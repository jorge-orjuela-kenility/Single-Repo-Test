//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import Network
internal import Utilities

/// A network-aware synchronization engine that coordinates and executes operations based on network connectivity.
///
/// `RemoteSyncEngine` is a concrete implementation of `SyncEngine` that manages the execution of
/// asynchronous operations with automatic handling of network interruptions. It monitors network
/// connectivity and automatically suspends operations when the network becomes unavailable, resuming
/// them when connectivity is restored.
///
/// ## Network-Aware Execution
///
/// The engine uses a `NetworkPathMonitor` to observe network connectivity changes. When the network
/// becomes unavailable (`.requiresConnection` or `.unsatisfied`), all active operations are interrupted
/// and the operation queue is suspended. When connectivity is restored (`.satisfied`), operations are
/// automatically resumed and execution continues.
///
/// ## Operation Management
///
/// - **Concurrent Execution**: Supports up to 20 concurrent operations for efficient parallel processing
/// - **Operation Queue**: Uses an `OperationQueue` to manage operation execution and lifecycle
/// - **Operation Tracking**: Maintains a list of active operations for interruption handling
/// - **Automatic Cleanup**: Removes finished operations from the tracking list to prevent memory leaks
///
/// ## State Management
///
/// The engine operates in three states:
/// - **`.ready`**: Initial state before `start()` is called; operations are queued but not executed
/// - **`.running`**: Active state where operations are being executed; network is available
/// - **`.interrupted`**: Network is unavailable; operations are suspended until connectivity is restored
///
/// ## Thread Safety
///
/// The engine uses `NSLock` to synchronize access to its internal state, ensuring thread-safe
/// state transitions and operation management. All operations are executed on a dedicated dispatch queue.
///
/// ## Usage Example
///
/// ```swift
/// let syncEngine = RemoteSyncEngine()
///
/// // Add a producer that yields operations
/// syncEngine.add(operationProducer)
///
/// // Start the engine to begin executing operations
/// syncEngine.start()
///
/// // The engine will automatically handle network interruptions
/// // and resume operations when connectivity is restored
/// ```
final class RemoteSyncEngine: SyncEngine, @unchecked Sendable {
    // MARK: - Private Properties

    private var _operations: [AsyncOperation] = []
    private var _state = State.ready
    private let lock = NSLock()
    private let networkPathMonitor: any NetworkPathMonitor
    private let operationQueue: OperationQueue
    private let queue = DispatchQueue(label: "com.truvideo.remoteSyncEngine.queue")

    // MARK: - Properties

    private(set) var state: State {
        get { lock.withLock { _state } }
        set { lock.withLock { _state = newValue } }
    }

    private(set) var operations: [AsyncOperation] {
        get { lock.withLock { _operations } }
        set { lock.withLock { _operations = newValue } }
    }

    // MARK: - Types

    /// Represents the possible states of the sync engine.
    ///
    /// The engine transitions between these states based on network connectivity and
    /// explicit start/stop calls.
    enum State {
        /// The engine is interrupted due to network unavailability.
        ///
        /// In this state, all operations are suspended and the operation queue is paused.
        /// The engine will automatically transition to `.running` when network connectivity
        /// is restored.
        case interrupted

        /// The engine is ready but not yet started.
        ///
        /// This is the initial state after initialization. Operations may be queued but
        /// will not execute until `start()` is called. The operation queue is suspended
        /// in this state.
        case ready

        /// The engine is actively running and executing operations.
        ///
        /// In this state, the operation queue is active and operations are being executed
        /// concurrently. The engine will transition to `.interrupted` if network connectivity
        /// is lost.
        case running
    }

    // MARK: - Initializer

    /// Creates a new remote sync engine instance.
    ///
    /// The engine is initialized in the `.ready` state with the operation queue suspended.
    /// It will begin monitoring network connectivity and automatically manage operation
    /// execution based on network availability once `start()` is called.
    ///
    /// - Parameters:
    ///   - networkPathMonitor: A network path monitor used to observe connectivity changes.
    ///                         Defaults to `NWPathMonitor()` if not provided.
    ///   - operationQueue: An operation queue used to execute operations. Defaults to a new
    ///                    `OperationQueue()` if not provided. The queue is configured to support
    ///                    up to 20 concurrent operations.
    init(
        networkPathMonitor: some NetworkPathMonitor = NWPathMonitor(),
        operationQueue: OperationQueue = OperationQueue()
    ) {
        self.networkPathMonitor = networkPathMonitor
        self.operationQueue = operationQueue

        self.operationQueue.isSuspended = true
        self.operationQueue.maxConcurrentOperationCount = 20

        networkPathMonitor.pathUpdateHandler = { [weak self] newPath in
            if let self {
                switch newPath.status {
                case .requiresConnection where state == .running,
                     .unsatisfied where state == .running:
                    receivedInterruption()

                case .satisfied where state == .interrupted:
                    interruptionEnded()

                default:
                    break
                }
            }
        }
    }

    // MARK: - SyncEngine

    /// Adds an operation producer to the sync engine.
    ///
    /// The engine will begin consuming operation batches from the producer's stream and
    /// execute them once `start()` is called. Multiple producers can be added to coordinate
    /// different sources of synchronization work.
    ///
    /// - Parameter producer: The operation producer to add. The engine will consume operations
    ///                      from this producer's stream until it completes or finishes.
    func add(_ producer: OperationProducer) {
        Task {
            for try await operations in producer.operations() {
                self.operations.removeAll(where: \.isFinished)

                for operation in operations {
                    operationQueue.addOperation(operation)
                    self.operations.append(operation)
                }
            }
        }
    }

    /// Starts the sync engine and begins executing operations.
    ///
    /// This method activates the engine and allows it to begin executing operations that have
    /// been consumed from registered producers. Before calling this method, operations may be
    /// queued but not executed. The exact behavior depends on the implementation.
    ///
    /// This method should be idempotent—calling it multiple times should be safe, though
    /// implementations may choose to ignore subsequent calls if already started.
    func start() {
        operationQueue.isSuspended = false
        networkPathMonitor.start(queue: .main)
        state = .running
    }

    // MARK: - Private methods

    private func interruptionEnded() {
        operationQueue.isSuspended = false
        state = .running
    }

    private func receivedInterruption() {
        operationQueue.isSuspended = true
        state = .interrupted
    }
}
