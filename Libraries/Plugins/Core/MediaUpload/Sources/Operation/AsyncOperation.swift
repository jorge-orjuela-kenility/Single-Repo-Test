//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// A base class for asynchronous operations that can be suspended, resumed, and cancelled.
///
/// `AsyncOperation` extends `Operation` to provide enhanced state management for asynchronous
/// work. It adds support for suspension and resumption, which are not natively supported by
/// the standard `Operation` class. The operation maintains its own state machine that tracks
/// whether it's ready, running, suspended, or finished.
///
/// ## State Management
///
/// Operations progress through states: `.ready` → `.running` → `.finished`. Operations can
/// be suspended (`.suspended`) while running and later resumed. The state is thread-safe
/// and uses KVO to notify observers of changes to `isExecuting`, `isFinished`, and `isReady`.
///
/// ## Subclassing
///
/// Subclasses should override `start()` to implement their asynchronous work. The base
/// `start()` implementation handles cancellation checks and state transitions, but subclasses
/// must provide their own execution logic. The `main()` method is provided for compatibility
/// but is not used by default.
///
/// ## Concurrency
///
/// This class is marked `@unchecked Sendable` because it manages mutable state (`_state`) that
/// is accessed across concurrency boundaries. Thread safety is ensured through the use of
/// `NSLock` for state access.
class AsyncOperation: Operation, Identifiable, @unchecked Sendable {
    // MARK: - Private Properties

    private var _state = State.ready
    private let lock = NSLock()

    // MARK: - Properties

    /// A unique identifier for this operation.
    let id: UUID

    /// A Boolean value indicating whether the operation is currently interrupted.
    ///
    /// An operation is marked as interrupted when a system interruption occurs (such as app
    /// backgrounding or network connectivity loss). The interrupted state is separate from
    /// the suspended state, though interruptions typically cause operations to suspend.
    ///
    /// This property is set to `true` by `interruptionStarted()` and cleared by `interruptionEnded()`.
    private(set) var isInterrupted = false

    // MARK: - Computed Properties

    /// Indicates whether the operation is in a runnable state.
    var isActive: Bool {
        isReady || isExecuting
    }

    /// A Boolean value indicating whether the operation is currently suspended.
    var isSuspended: Bool {
        state == .suspended
    }

    /// The current state of the operation.
    ///
    /// Thread-safe access to the operation's state. Changes to this property trigger KVO
    /// notifications for dependent properties (`isExecuting`, `isFinished`, `isReady`).
    @objc dynamic var state: State {
        get { lock.withLock { _state } }
        set { lock.withLock { _state = newValue } }
    }

    // MARK: - Overridden Properties

    /// A Boolean value indicating whether the operation is currently executing.
    ///
    /// Returns `true` when the operation's state is `.running`.
    override var isExecuting: Bool {
        state == .running
    }

    /// A Boolean value indicating whether the operation has finished executing.
    ///
    /// Returns `true` when the operation's state is `.finished`.
    override var isFinished: Bool {
        state == .finished
    }

    /// A Boolean value indicating whether the operation is ready to execute.
    ///
    /// Returns `true` when the operation's state is `.ready` and the superclass also
    /// indicates readiness (e.g., dependencies are satisfied).
    override var isReady: Bool {
        state == .ready
    }

    // MARK: - Types

    /// Represents the possible states of an asynchronous operation.
    @objc
    enum State: Int {
        /// The operation has completed execution.
        case finished

        /// The operation is ready to begin execution.
        case ready

        /// The operation is temporarily paused.
        case suspended

        /// The operation is currently executing.
        case running
    }

    // MARK: - Overridden Class methods

    /// Returns the key paths that affect the value of the specified key.
    ///
    /// Configures KVO to notify observers when the `state` property changes, which affects
    /// pa the computed properties `isExecuting`, `isFinished`, and `isReady`.
    ///
    /// - Parameter key: The key whose dependent key paths are being requested.
    /// - Returns: A set of key paths that affect the value of the specified key.
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isExecuting", "isFinished", "isReady"].contains(key) {
            return [#keyPath(state)]
        }

        return super.keyPathsForValuesAffectingValue(forKey: key)
    }

    // MARK: - Initializer

    /// Creates a new asynchronous operation.
    ///
    /// - Parameter id: A unique identifier for the operation. Defaults to a new UUID if not provided.
    init(id: UUID = UUID()) {
        self.id = id
    }

    // MARK: - Instance methods

    /// Marks the operation as finished.
    ///
    /// If the operation is not already finished, this method transitions its state to `.finished`,
    /// which causes `isFinished` to return `true` and allows the operation queue to remove it.
    func finish() {
        if !isFinished {
            state = .finished
        }
    }

    /// Resumes the operation if it is ready.
    ///
    /// If the operation is in the `.ready` state, this method transitions it to `.running`,
    /// allowing it to begin or continue execution.
    func resume() {
        if isSuspended {
            state = .running
        }
    }

    /// Suspends the operation if it is currently executing.
    ///
    /// If the operation is in the `.running` state, this method transitions it to `.suspended`,
    /// pausing its execution. The operation can be resumed later using `resume()`.
    func suspend() {
        if isExecuting {
            state = .suspended
        }
    }

    // MARK: - Overridden methods

    /// The main method for performing the operation's work.
    ///
    /// This method is provided for compatibility with the standard `Operation` interface but
    /// is not used by default. Subclasses should override `start()` instead to implement
    /// their asynchronous work.
    override func main() {}

    /// Begins execution of the operation.
    ///
    /// This method checks if the operation has been cancelled, and if so, immediately
    /// finishes it. Otherwise, it transitions the state to `.running`. Subclasses should
    /// override this method to implement their specific asynchronous work.
    ///
    /// - Note: Subclasses must call `super.start()` or implement their own state management
    ///         to ensure proper state transitions and cancellation handling.
    override func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .running
        main()
    }
}
