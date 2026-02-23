//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// A protocol that defines the contract for producing asynchronous operations in batches.
///
/// Types conforming to `OperationProducer` provide a stream of operation batches that can be
/// consumed by a sync engine or similar execution coordinator. Producers observe changes (such
/// as database updates, network events, or state changes) and yield batches of operations that
/// should be executed to synchronize or process those changes.
///
/// ## Lifecycle
///
/// 1. The producer is created and configured with the necessary dependencies
/// 2. The sync engine calls `operations()` to obtain the async stream
/// 3. The engine iterates over the stream, receiving batches of operations as they become available
/// 4. When synchronization is complete or needs to stop, `finish()` is called to signal completion
///
/// ## Operation Batching
///
/// Operations are yielded in batches rather than individually. This allows producers to:
/// - Group related operations together
/// - Reduce overhead from frequent stream emissions
/// - Coordinate dependencies between operations within a batch
protocol OperationProducer {
    /// Signals that the producer should stop producing operations and finish its stream.
    ///
    /// This method should be called when synchronization is complete or needs to be cancelled.
    /// After calling this method, the producer should finish its async stream, causing any
    /// consumers iterating over `operations()` to complete their iteration.
    ///
    /// Multiple calls to `finish()` should be safe and idempotent.
    func finish() async throws

    /// Returns an async stream that yields batches of operations as they become available.
    ///
    /// The stream produces arrays of `AsyncOperation` instances whenever the producer detects
    /// work that needs to be performed. The stream continues until `finish()` is called or
    /// the producer naturally completes.
    ///
    /// - Returns: An `AsyncStream` that yields batches of `AsyncOperation` instances.
    ///            The stream completes when `finish()` is called or the producer terminates.
    func operations() -> AsyncStream<[AsyncOperation]>
}

/// A protocol that defines the contract for coordinating and executing synchronization operations.
///
/// Types conforming to `SyncEngine` manage the lifecycle of operation producers and coordinate
/// the execution of their operations. The engine acts as a central coordinator that consumes
/// operation batches from multiple producers and executes them according to its implementation
/// strategy (e.g., concurrent execution, dependency management, resource constraints).
///
/// ## Producer Management
///
/// Producers are registered with the engine using `add(_:)`. The engine consumes operation
/// batches from each producer's stream and executes them. Multiple producers can be added
/// to a single engine, allowing different sources of work to be coordinated together.
///
/// ## Execution Lifecycle
///
/// 1. Producers are added to the engine using `add(_:)`
/// 2. The engine begins consuming operations from producer streams asynchronously
/// 3. `start()` is called to begin executing operations
/// 4. Operations are executed according to the engine's implementation (e.g., queued execution,
///    dependency resolution, concurrency limits)
protocol SyncEngine: Sendable {
    /// Adds an operation producer to the sync engine.
    ///
    /// The engine will begin consuming operation batches from the producer's stream and
    /// execute them once `start()` is called. Multiple producers can be added to coordinate
    /// different sources of synchronization work.
    ///
    /// - Parameter producer: The operation producer to add. The engine will consume operations
    ///                      from this producer's stream until it completes or finishes.
    func add(_ producer: OperationProducer)

    /// Starts the sync engine and begins executing operations.
    ///
    /// This method activates the engine and allows it to begin executing operations that have
    /// been consumed from registered producers. Before calling this method, operations may be
    /// queued but not executed. The exact behavior depends on the implementation.
    ///
    /// This method should be idempotent—calling it multiple times should be safe, though
    /// implementations may choose to ignore subsequent calls if already started.
    func start()
}
