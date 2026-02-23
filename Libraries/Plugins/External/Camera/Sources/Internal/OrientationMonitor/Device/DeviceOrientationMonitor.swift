//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Combine
import CoreMotion
import Foundation
import UIKit

/// A concrete implementation of `OrientationMonitor` that uses `CMMotionManager` for
/// physical device orientation detection.
///
/// This class provides real-time orientation monitoring by combining device motion data
/// with system orientation notifications. It offers more accurate and responsive
/// orientation detection compared to relying solely on system notifications, especially
/// for edge cases like face-down orientations.
final class DeviceOrientationMonitor: OrientationMonitor, @unchecked Sendable {
    // MARK: - Private Properties

    private var _observers = Set<ObservationToken>()
    private var cancellables = Set<AnyCancellable>()
    private let deviceOrientation = CurrentValueSubject<DeviceOrientation, Never>(.unknown)
    fileprivate var lastOrientation = UIDeviceOrientation.unknown
    private let lock = NSLock()
    private var isRunning = false
    private let motionManager = CMMotionManager()
    private let notificationDelay: UInt64 = 700_000_000
    private let operationQueue = OperationQueue()

    // MARK: - Properties

    /// Represents the most recent known device orientation for a subscriber.
    ///
    /// This property reflects the current orientation state as detected or provided by
    /// the `OrientationMonitor`. It serves as the reference orientation used to
    /// calculate transitions, rotation angles, and visual adjustments when new
    /// orientation updates are received.
    ///
    /// Implementations of this property should ensure it always reflects the
    /// **last applied orientation**, whether derived from sensors, the system, or
    /// manually set values. When a new `DeviceOrientationInfo` arrives, this value
    /// should be updated before handling the rotation logic in `didReceive(_:)`.
    var currentOrientation: DeviceOrientation {
        deviceOrientation.value
    }

    // MARK: - Computed Properties

    private var observers: Set<ObservationToken> {
        get { lock.withLock { _observers } }
        set { lock.withLock { _observers = newValue } }
    }

    // MARK: - Types

    /// A token that represents a registered event observer.
    ///
    /// `ObservationToken` encapsulates an observer's callback block and provides a mechanism
    /// for removing the observer from the emitter. The token uses a unique identifier for
    /// equality and hashing, allowing it to be stored in sets and compared efficiently.
    ///
    /// The token holds a weak reference to the emitter to prevent retain cycles, and provides
    /// a `remove()` method for explicit observer removal.
    struct ObservationToken: Hashable {
        weak var orientationMonitor: DeviceOrientationMonitor?

        /// The async closure that will be invoked when events are emitted.
        ///
        /// This closure receives the emitted event and processes it asynchronously. The closure
        /// is marked as `@Sendable` to ensure it can be safely passed across concurrency domains.
        let block: @Sendable (DeviceOrientation) async -> Void

        /// A unique identifier for this observation token.
        ///
        /// This UUID is used for equality comparison and hashing, ensuring that each token
        /// is uniquely identifiable within the observers collection.
        let token = UUID()

        // MARK: - Hashable

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        static func == (lhs: ObservationToken, rhs: ObservationToken) -> Bool {
            lhs.token == rhs.token
        }

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        func hash(into hasher: inout Hasher) {
            token.hash(into: &hasher)
        }

        // MARK: - Instance methods

        /// Removes this observer from the emitter.
        ///
        /// This method unregisters the observer from the emitter, preventing it from receiving
        /// future events. After removal, the observer will no longer be notified of emitted events.
        ///
        /// If the emitter has already been deallocated, this method does nothing.
        func remove() {
            orientationMonitor?.removeObserver(self)
        }
    }

    // MARK: - Initializer

    init() {
        motionManager.deviceMotionUpdateInterval = 1 / 30

        Task(priority: .userInitiated) { @MainActor in
            if UIDevice.current.orientation.isSupported {
                let orientation = DeviceOrientation(orientation: UIDevice.current.orientation, source: .system)
                deviceOrientation.value = orientation
            }
        }

        startObserving()
    }

    // MARK: - Deinitializer

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Instance methods

    func yield(_ deviceOrientation: DeviceOrientation) {
        let observers = observers

        for observer in observers {
            Task {
                await observer.block(deviceOrientation)
            }
        }
    }

    // MARK: - Notification methods

    @MainActor
    @objc
    func didReceiveOrientationDidChangeNotification(_ notification: Notification) {
        if UIDevice.current.orientation.isSupported {
            let deviceOrientation = DeviceOrientation(orientation: UIDevice.current.orientation, source: .system)

            self.deviceOrientation.send(deviceOrientation)

            if isRunning {
                yield(deviceOrientation)
            }
        }
    }

    // MARK: - OrientationMonitor

    /// Returns an asynchronous sequence that produces `DeviceOrientation` events
    /// originating from the specified source.
    ///
    /// This method provides a unified, consumer-friendly interface for observing
    /// orientation changes without exposing the underlying emitter or its internal
    /// sequence type. The returned value conforms to `AsyncSequence`, allowing the
    /// caller to iterate orientation updates using `for await` syntax.
    func orientationUpdates(from type: MonitoringType) -> AsyncStream<DeviceOrientation> {
        AsyncStream { continuation in
            let task = Task {
                let asyncSequence = DeviceOrientationAsyncSequence(orientationMonitor: self, type: type)

                for try await deviceOrientation in asyncSequence {
                    continuation.yield(deviceOrientation)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Begins monitoring device orientation changes.
    ///
    /// This method starts the orientation detection process and begins calling the
    /// `updateHandler` closure whenever the device orientation changes.
    func startMonitoring() {
        if !isRunning {
            isRunning = true

            if deviceOrientation.value.orientation != lastOrientation {
                yield(deviceOrientation.value)
            }

            motionManager.startDeviceMotionUpdates(
                using: .xArbitraryZVertical,
                to: operationQueue
            ) { [weak self] deviceMotion, error in
                if let self, isRunning {
                    guard let error else {
                        Task { @MainActor in
                            let currentOrientation = self.deviceOrientation.value.orientation
                            let orientation = deviceMotion?.gravity.orientation

                            if let orientation, orientation != currentOrientation, orientation.isSupported {
                                let deviceOrientation = DeviceOrientation(orientation: orientation, source: .sensors)

                                try await Task.sleep(nanoseconds: self.notificationDelay)

                                self.yield(deviceOrientation)
                                self.deviceOrientation.send(deviceOrientation)
                            }
                        }

                        return
                    }

                    print(error)
                    // Log Error
                }
            }
        }
    }

    /// Stops monitoring device orientation changes.
    ///
    /// This method stops the orientation detection process and ceases calling the
    /// `updateHandler` closure.
    func stopMonitoring() {
        if isRunning {
            motionManager.stopDeviceMotionUpdates()
            isRunning = false
        }
    }

    // MARK: - Private methods

    fileprivate func addObserver(
        using block: @escaping @Sendable (DeviceOrientation) async -> Void
    ) -> ObservationToken {
        let observationToken = ObservationToken(orientationMonitor: self, block: block)

        observers.insert(observationToken)

        return observationToken
    }

    private func removeObserver(_ token: ObservationToken) {
        observers.remove(token)
    }

    private func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveOrientationDidChangeNotification(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
}

extension DeviceOrientationMonitor {
    // MARK: - Types

    struct DeviceOrientationAsyncSequence: AsyncSequence, Sendable {
        typealias AsyncIterator = DeviceOrientationSequenceIterator
        typealias Element = DeviceOrientation

        // MARK: - Private Properties

        private let orientationMonitor: DeviceOrientationMonitor
        private let type: MonitoringType

        // MARK: - Initializer

        init(orientationMonitor: DeviceOrientationMonitor, type: MonitoringType) {
            self.orientationMonitor = orientationMonitor
            self.type = type
        }

        // MARK: - AsyncSequence

        /// Creates the asynchronous iterator that produces elements of this
        /// asynchronous sequence.
        ///
        /// - Returns: An instance of the `AsyncIterator` type used to produce
        /// elements of the asynchronous sequence.
        func makeAsyncIterator() -> DeviceOrientationSequenceIterator {
            DeviceOrientationSequenceIterator(orientationMonitor: orientationMonitor, type: type)
        }
    }
}

extension DeviceOrientationMonitor {
    // MARK: - Types

    final class DeviceOrientationSequenceIterator: @unchecked Sendable, AsyncIteratorProtocol {
        typealias Element = DeviceOrientation
        typealias Failure = Never

        // MARK: - Private Properties

        private var cancellables = Set<AnyCancellable>()
        private let intervalMilliseconds: UInt64 = 1_000
        private let state = State()

        // MARK: - Types

        fileprivate final class State: @unchecked Sendable {
            // MARK: - Private Properties

            private var continuations: [CheckedContinuation<DeviceOrientation?, Error>] = []
            fileprivate let deviceOrientation = PassthroughSubject<DeviceOrientation, Never>()
            fileprivate var lastOrientation = UIDeviceOrientation.unknown
            private let lock = NSLock()
            private var orientations: [DeviceOrientation] = []

            // MARK: - Properties

            var observer: ObservationToken?

            // MARK: - Instance methods

            /// Appends a continuation to the waiting queue and attempts to immediately resume it
            /// if a matching orientation is available.
            ///
            /// This method adds a new continuation to the internal queue of waiting continuations.
            /// After appending, it checks if there are any pending orientations that can be
            /// immediately delivered. If both an orientation and a continuation are available,
            /// a `Resumption` is returned that can be used to resume the continuation with the
            /// orientation value.
            ///
            /// - Parameter continuation: The continuation to add to the waiting queue.
            /// - Returns: A `Resumption` object if an orientation is immediately available to
            ///   resume the continuation, or `nil` if the continuation must wait for a future
            ///   orientation update.
            func append(_ continuation: CheckedContinuation<DeviceOrientation?, Error>) -> Resumption? {
                lock.withLock {
                    continuations.append(continuation)
                    return next()
                }
            }

            /// Cancels all pending continuations and removes the orientation observer.
            ///
            /// This method performs a complete cleanup of the state:
            /// - Removes the observer from the orientation monitor
            /// - Resumes all waiting continuations with `nil` to signal cancellation
            /// - Clears the internal continuation queue
            ///
            /// All continuations are resumed with `nil`, which signals to consumers that the
            /// sequence has been terminated and no further orientation updates will be delivered.
            func cancel() {
                let continuations = lock.withLock {
                    defer {
                        self.continuations.removeAll()
                    }

                    observer?.remove()
                    return self.continuations
                }

                for continuation in continuations {
                    continuation.resume(returning: nil)
                }
            }

            /// Enqueues a device orientation and immediately resumes a waiting continuation if available.
            ///
            /// When a new device orientation is received, this method attempts to deliver it
            /// immediately to a waiting continuation. If no continuations are waiting, the
            /// orientation is not stored and `nil` is returned, indicating that the orientation
            /// was dropped because there were no active consumers.
            ///
            /// - Parameter deviceOrientation: The device orientation to deliver to a waiting continuation.
            /// - Returns: A `Resumption` object if a continuation was available and can be resumed
            ///   with the orientation, or `nil` if no continuations were waiting.
            func enqueue(_ deviceOrientation: DeviceOrientation) -> Resumption? {
                lock.withLock {
                    guard !continuations.isEmpty else {
                        return nil
                    }

                    return Resumption(deviceOrientation: deviceOrientation, continuation: continuations.removeFirst())
                }
            }

            /// Pairs an available orientation with a waiting continuation, if both are present.
            ///
            /// This method checks if there are both pending orientations and waiting continuations
            /// in their respective queues. If both are available, it removes the first item from
            /// each queue and creates a `Resumption` that pairs them together for delivery.
            ///
            /// - Returns: A `Resumption` object pairing an orientation with a continuation if both
            ///   are available, or `nil` if either queue is empty.
            func next() -> Resumption? {
                guard !orientations.isEmpty, !continuations.isEmpty else {
                    return nil
                }

                return Resumption(
                    deviceOrientation: orientations.removeFirst(),
                    continuation: continuations.removeFirst()
                )
            }
        }

        /// A coordination object that pairs a sample buffer with waiting continuations.
        ///
        /// The `Resumption` struct encapsulates the delivery of a sample buffer to
        /// one or more waiting async continuations. It provides a clean abstraction
        /// for resuming consumers with the appropriate sample data.
        struct Resumption: Sendable {
            // MARK: - Private Properties

            private let continuations: [CheckedContinuation<DeviceOrientation?, Error>]
            private let deviceOrientation: DeviceOrientation?

            // MARK: - Initializer

            /// Creates a resumption that pairs a device orientation with a single continuation.
            ///
            /// This initializer is used when a device orientation is available and ready to be
            /// delivered to a waiting continuation. The continuation will be resumed with the
            /// provided orientation value when `resume()` is called.
            ///
            /// - Parameters:
            ///   - deviceOrientation: The device orientation to deliver to the continuation, or
            ///     `nil` to signal the end of the sequence.
            ///   - continuation: The continuation that will receive the device orientation.
            init(deviceOrientation: DeviceOrientation?, continuation: CheckedContinuation<DeviceOrientation?, Error>) {
                self.continuations = [continuation]
                self.deviceOrientation = deviceOrientation
            }

            /// Creates a resumption for cancelling multiple continuations.
            ///
            /// This initializer is used when the sequence is being cancelled and all waiting
            /// continuations need to be resumed with `nil` to signal termination. The device
            /// orientation is set to `nil` to indicate that no orientation data will be delivered.
            ///
            /// - Parameter continuations: An array of continuations that should be cancelled
            ///   and resumed with `nil`.
            init(cancelling continuations: [CheckedContinuation<DeviceOrientation?, Error>]) {
                self.continuations = continuations
                self.deviceOrientation = nil
            }

            // MARK: - Instance methods

            /// Resumes all waiting continuations with the sample buffer.
            ///
            /// This method delivers the sample buffer to all waiting continuations,
            /// effectively resuming the consumers that were awaiting the next sample.
            /// If the buffer is `nil`, it signals the end of the sequence to consumers.
            func resume() {
                for continuation in continuations {
                    continuation.resume(returning: deviceOrientation)
                }
            }
        }

        // MARK: - Initializer

        fileprivate init(orientationMonitor: DeviceOrientationMonitor, type: MonitoringType) {
            state.lastOrientation = orientationMonitor.lastOrientation

            if type == .all {
                subscribeToOrientationUpdates()
            }

            state.observer = orientationMonitor.addObserver { [weak self] deviceOrientation in
                if let self {
                    switch type {
                    case .sensors where deviceOrientation.source == .sensors:
                        state.enqueue(deviceOrientation)?.resume()

                    case .system where deviceOrientation.source == .system:
                        state.enqueue(deviceOrientation)?.resume()

                    default:
                        state.deviceOrientation.send(deviceOrientation)
                    }
                }
            }
        }

        // MARK: - Deinitializer

        deinit {
            state.cancel()
        }

        // MARK: - AsyncIteratorProtocol

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        func next() async throws -> DeviceOrientation? {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    state.append(continuation)?.resume()
                }
            } onCancel: {
                state.cancel()
            }
        }

        // MARK: - Private methods

        private func subscribeToOrientationUpdates() {
            state.deviceOrientation
                .removeDuplicates()
                .collect(.byTime(RunLoop.main, .milliseconds(1_000)))
                .receive(on: RunLoop.main)
                .filter { _ in UIApplication.shared.applicationState == .active }
                .compactMap { $0.last { $0.source == .system } ?? $0.last }
                .sink { [weak self] orientation in
                    if let self, state.lastOrientation != orientation.orientation {
                        if state.lastOrientation != orientation.orientation || orientation.source == .system {
                            state.enqueue(orientation)?.resume()
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }
}

extension CMAcceleration {
    /// Calculates the device orientation based on acceleration data.
    ///
    /// This computed property determines the current device orientation by analyzing
    /// the acceleration values from the device's accelerometer. It compares the
    /// magnitude of acceleration along each axis (X, Y, Z) to determine which
    /// orientation the device is currently in.
    ///
    /// - Returns: The calculated `UIDeviceOrientation` based on accelerometer data analysis.
    fileprivate var orientation: UIDeviceOrientation {
        let faceUpZThreshold = -0.7
        let faceUpPortraitThreshold = 0.6
        let landscapeThreshold = 0.9
        let threshold = 0.82

        if z < faceUpZThreshold {
            if abs(x) > abs(y), abs(x) > abs(z), abs(x) > threshold {
                return x > 0 ? .landscapeRight : .landscapeLeft
            }

            if abs(y) > faceUpPortraitThreshold {
                return y > 0 ? .portraitUpsideDown : .portrait
            }

            return .unknown
        }

        if abs(x) > abs(y), abs(x) > abs(z), abs(x) > threshold {
            if abs(x) > landscapeThreshold {
                return x > 0 ? .landscapeRight : .landscapeLeft
            }

            return .unknown
        }

        if abs(y) > abs(x), abs(y) > abs(z), abs(y) > threshold {
            return y > 0 ? .portraitUpsideDown : .portrait
        }

        return .unknown
    }
}
