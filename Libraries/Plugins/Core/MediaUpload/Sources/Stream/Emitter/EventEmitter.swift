//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import TruVideoFoundation

/// A protocol that defines the contract for events that can be emitted and observed.
///
/// Types conforming to `Event` represent discrete occurrences or state changes that can be
/// broadcast through an `EventEmitter` and observed by multiple subscribers. Events must
/// be `Sendable` to ensure thread-safe distribution across concurrent contexts.
///
/// ## Usage
///
/// Define custom event types by conforming to this protocol:
///
/// ```swift
/// struct StreamCompletedEvent: Event {
///     let streamId: UUID
///     let completedAt: Date
/// }
/// ```
protocol Event: Sendable {}

/// A thread-safe event emitter that broadcasts events to registered observers.
///
/// `EventEmitter` provides a publish-subscribe pattern for distributing events to multiple
/// observers. It supports both direct observer registration and `AsyncSequence`-based event
/// streaming, making it suitable for both callback-based and async/await-based event handling.
///
/// ## Thread Safety
///
/// The emitter uses `NSLock` to ensure thread-safe access to its observer collection. All
/// operations (emitting events, adding/removing observers) are safe to call from any thread.
///
/// ## Event Distribution
///
/// When an event is emitted via `emit(_:)`, all registered observers are notified asynchronously
/// using `Task`. This ensures that event processing doesn't block the emitter and allows
/// observers to perform their work concurrently.
///
/// ## Async Sequence Support
///
/// The emitter provides `AsyncSequence` support through the `events(of:)` method, allowing
/// consumers to use async/await syntax to observe events of a specific type. The sequence
/// automatically filters events to only yield those matching the requested type.
///
/// ## Usage
///
/// ```swift
/// let emitter = EventEmitter()
///
/// // Emit an event
/// emitter.emit(StreamCompletedEvent(streamId: id, completedAt: Date()))
///
/// // Observe events using AsyncSequence
/// for try await event in emitter.events(of: StreamCompletedEvent.self) {
///     print("Stream completed: \(event.streamId)")
/// }
/// ```
final class EventEmitter: @unchecked Sendable {
    // MARK: - Private Properties

    private var _observers = Set<ObservationToken>()
    private let lock = NSLock()

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
        /// A weak reference to the emitter that created this token.
        ///
        /// This weak reference prevents retain cycles between the emitter and observers,
        /// allowing the emitter to be deallocated when no longer referenced.
        weak var emitter: EventEmitter?

        /// The async closure that will be invoked when events are emitted.
        ///
        /// This closure receives the emitted event and processes it asynchronously. The closure
        /// is marked as `@Sendable` to ensure it can be safely passed across concurrency domains.
        let block: @Sendable (Event) async -> Void

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
            emitter?.removeObserver(self)
        }
    }

    // MARK: Instance methods

    /// Emits an event to all registered observers.
    ///
    /// This method broadcasts the provided event to all currently registered observers.
    /// Each observer's callback is invoked asynchronously using `Task`, ensuring that
    /// event processing doesn't block the emitter and allowing observers to process events
    /// concurrently.
    ///
    /// Observers are notified in the order they were registered, though actual execution
    /// order may vary due to the asynchronous nature of the distribution.
    ///
    /// - Parameter event: The event to emit to all observers.
    func emit(_ event: Event) {
        let observers = observers

        for observer in observers {
            Task {
                await observer.block(event)
            }
        }
    }

    /// Creates an async sequence that yields events of the specified type.
    ///
    /// This method returns an `AsyncSequence` that filters and yields only events matching
    /// the specified type. The sequence automatically registers an observer with the emitter
    /// and unregisters it when the sequence is cancelled or deallocated.
    ///
    /// The sequence buffers at most one event, ensuring that consumers don't miss events
    /// that occur between iterations. If a consumer is not actively awaiting the next event,
    /// only the most recent event is retained.
    ///
    /// - Parameter type: The type of events to observe.
    /// - Returns: An `AsyncSequence` that yields events of the specified type.
    func events<E: Event>(of type: E.Type) -> EmitterAsyncSequence<E> {
        EmitterAsyncSequence(emitter: self)
    }

    // MARK: - Private methods

    private func addObserver(using block: @escaping @Sendable (Event) async -> Void) -> ObservationToken {
        let observationToken = ObservationToken(emitter: self, block: block)

        observers.insert(observationToken)

        return observationToken
    }

    private func removeObserver(_ token: ObservationToken) {
        observers.remove(token)
    }
}

extension EventEmitter {
    // MARK: - Types

    /// An async sequence that yields events of a specific type from an event emitter.
    ///
    /// `EmitterAsyncSequence` provides an `AsyncSequence` interface for observing events
    /// of a particular type. It automatically filters events to only yield those matching
    /// the specified generic type parameter, and handles observer registration and cleanup
    /// automatically.
    ///
    /// The sequence buffers at most one event to ensure consumers don't miss events that
    /// occur between iterations. When a consumer awaits the next event, it receives the
    /// most recent event if one is available, or waits for the next event to be emitted.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// for try await event in emitter.events(of: StreamCompletedEvent.self) {
    ///     print("Stream completed: \(event.streamId)")
    /// }
    /// ```
    struct EmitterAsyncSequence<E: Event>: AsyncSequence, Sendable {
        // MARK: - Private Properties

        /// The event emitter that provides the events for this sequence.
        private let emitter: EventEmitter

        // MARK: - Initializer

        /// Creates a new async sequence for the specified emitter.
        ///
        /// - Parameter emitter: The event emitter to observe for events.
        init(emitter: EventEmitter) {
            self.emitter = emitter
        }

        // MARK: - AsyncSequence

        /// Creates the asynchronous iterator that produces elements of this
        /// asynchronous sequence.
        func makeAsyncIterator() -> EventSequenceIterator<E> {
            EventSequenceIterator(emitter: emitter)
        }
    }
}

extension EventEmitter {
    // MARK: - Types

    /// An async iterator that produces events of a specific type from an event emitter.
    ///
    /// `EventSequenceIterator` implements the `AsyncIteratorProtocol` to provide iteration
    /// over events of a specific type. It maintains an internal state that buffers events and
    /// coordinates between event emission and consumer awaiting, ensuring that events are
    /// delivered reliably even when consumers are not actively awaiting.
    ///
    /// The iterator automatically registers an observer with the emitter upon initialization
    /// and unregisters it when deallocated or cancelled. It uses a ring buffer to store at
    /// most one event, ensuring that the most recent event is always available for consumers.
    ///
    /// ## Thread Safety
    ///
    /// The iterator uses `NSLock` internally to synchronize access to its state, making it
    /// safe to use from multiple concurrent contexts.
    final class EventSequenceIterator<E: Event>: AsyncIteratorProtocol, Sendable {
        typealias Failure = Never

        // MARK: - Private Properties

        private let state = State()

        // MARK: - Types

        /// An internal state coordinator that manages event buffering and continuation coordination.
        ///
        /// This class maintains a ring buffer for events, a collection of waiting continuations,
        /// and coordinates the delivery of events to consumers. It uses `NSLock` to ensure thread-safe
        /// access to its internal state.
        ///
        /// The state automatically pairs buffered events with waiting continuations, ensuring that
        /// consumers receive events promptly when available and wait appropriately when no events
        /// are buffered.
        fileprivate final class State: @unchecked Sendable {
            // MARK: - Private Properties

            private var continuations: [CheckedContinuation<E?, Error>] = []
            private let lock = NSLock()
            private var ringBuffer = RingBuffer<E>(bufferingPolicy: .bufferingOldest(1))

            // MARK: - Properties

            /// The observation token registered with the event emitter.
            ///
            /// This token is used to unregister the observer when the iterator is cancelled
            /// or deallocated, preventing memory leaks and unnecessary event processing.
            var observer: ObservationToken?

            // MARK: - Instance methods

            /// Appends a continuation to the waiting list and attempts to pair it with a buffered event.
            ///
            /// This method adds the continuation to the waiting list and immediately checks if
            /// there's a buffered event available. If so, it returns a `Resumption` that pairs
            /// the event with the continuation for immediate delivery.
            ///
            /// - Parameter continuation: The continuation waiting for the next event.
            /// - Returns: A `Resumption` if an event is immediately available, `nil` otherwise.
            func append(_ continuation: CheckedContinuation<E?, Error>) -> Resumption? {
                lock.withLock {
                    continuations.append(continuation)
                    return next()
                }
            }

            /// Cancels the iterator and cleans up all resources.
            ///
            /// This method unregisters the observer from the emitter, clears the event buffer,
            /// and resumes all waiting continuations with `nil` to signal the end of the sequence.
            /// This ensures that consumers are properly notified when iteration is cancelled.
            func cancel() {
                let continuations = continuations
                defer { self.continuations.removeAll() }

                observer?.remove()
                ringBuffer.removeAll()

                for continuation in continuations {
                    continuation.resume(returning: nil)
                }
            }

            /// Enqueues a new event and attempts to pair it with a waiting continuation.
            ///
            /// This method adds the event to the ring buffer and immediately checks if there's
            /// a waiting continuation. If so, it returns a `Resumption` that pairs the event
            /// with the continuation for immediate delivery.
            ///
            /// - Parameter event: The event to enqueue.
            /// - Returns: A `Resumption` if a continuation is immediately available, `nil` otherwise.
            func enqueue(event: E) -> Resumption? {
                lock.withLock {
                    ringBuffer.add(event)
                    return next()
                }
            }

            /// Attempts to pair a buffered event with a waiting continuation.
            ///
            /// This method checks if both a buffered event and a waiting continuation are available.
            /// If so, it creates a `Resumption` that pairs them for delivery. If either is missing,
            /// it returns `nil` to indicate that pairing is not possible at this time.
            ///
            /// - Returns: A `Resumption` pairing an event with a continuation if both are available,
            ///            `nil` otherwise.
            func next() -> Resumption? {
                guard !ringBuffer.isEmpty, !continuations.isEmpty else {
                    return nil
                }

                return Resumption(event: ringBuffer.removeFirst(), continuation: continuations.removeFirst())
            }
        }

        /// A coordination object that pairs an event with waiting continuations.
        ///
        /// The `Resumption` struct encapsulates the delivery of an event to one or more waiting
        /// async continuations. It provides a clean abstraction for resuming consumers with
        /// the appropriate event data, or signaling the end of the sequence with `nil`.
        struct Resumption: Sendable {
            // MARK: - Private Properties

            private let continuations: [CheckedContinuation<E?, Error>]
            private let event: E?

            // MARK: - Initializer

            /// Creates a resumption that pairs an event with a continuation.
            ///
            /// - Parameters:
            ///   - event: The event to deliver, or `nil` to signal the end of the sequence.
            ///   - continuation: The continuation waiting for the event.
            init(event: E?, continuation: CheckedContinuation<E?, Error>) {
                self.continuations = [continuation]
                self.event = event
            }

            /// Creates a resumption that cancels multiple continuations.
            ///
            /// This initializer is used when the iterator is cancelled and all waiting
            /// continuations need to be resumed with `nil` to signal the end of the sequence.
            ///
            /// - Parameter continuations: The continuations to cancel.
            init(cancelling continuations: [CheckedContinuation<E?, Error>]) {
                self.continuations = continuations
                self.event = nil
            }

            // MARK: - Instance methods

            /// Resumes all waiting continuations with the event.
            ///
            /// This method delivers the event to all waiting continuations, effectively
            /// resuming the consumers that were awaiting the next event. If the event is
            /// `nil`, it signals the end of the sequence to consumers.
            func resume() {
                for continuation in continuations {
                    continuation.resume(returning: event)
                }
            }
        }

        // MARK: - Initializer

        /// Creates a new iterator for the specified emitter.
        ///
        /// This initializer sets up the iterator by registering an observer with the emitter.
        /// The observer filters events to only those matching the generic type `E` and enqueues
        /// them for delivery to consumers.
        ///
        /// - Parameter emitter: The event emitter to observe for events.
        fileprivate init(emitter: EventEmitter) {
            state.observer = emitter.addObserver { [weak self] event in
                if let self, let event = event as? E {
                    state.enqueue(event: event)?.resume()
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
        func next() async throws -> E? {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    state.append(continuation)?.resume()
                }
            } onCancel: {
                state.cancel()
            }
        }
    }
}
