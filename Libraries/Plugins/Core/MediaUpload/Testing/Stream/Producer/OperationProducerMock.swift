//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

@testable import MediaUpload

/// A mock implementation of the `OperationProducer` protocol for unit testing.
///
/// `OperationProducerMock` allows tests to simulate the production of asynchronous
/// operation batches without executing real background or network work.
/// It provides deterministic control over:
/// - When operation batches are emitted
/// - How many times the producer is queried
/// - Whether the producer is explicitly finished
///
/// This mock is especially useful for validating orchestration logic,
/// lifecycle handling, and backpressure behavior in consumers of
/// `OperationProducer`.
public final class OperationProducerMock: OperationProducer {
    // MARK: - Call Tracking

    /// Number of times `finish()` has been invoked.
    ///
    /// Useful for asserting that the producer lifecycle
    /// is correctly terminated.
    public private(set) var finishCallCount = 0

    /// Number of times `operations()` has been invoked.
    ///
    /// Useful for verifying that consumers subscribe
    /// to the operations stream the expected number of times.
    public private(set) var operationsCallCount = 0

    // MARK: - Private Properties

    /// Continuation used to emit batches of operations to subscribers.
    ///
    /// This is captured when `operations()` is called and is used
    /// to yield predefined batches and signal stream completion.
    private var continuations: [AsyncStream<[AsyncOperation]>.Continuation] = []

    // MARK: - Public Properties

    /// Predefined batches of operations to be emitted by the mock.
    ///
    /// Tests can populate this array to fully control the sequence
    /// and grouping of operations produced by the stream.
    ///
    /// Each inner array represents a single batch yielded
    /// through the `AsyncStream`.
    public var predefinedBatches: [[AsyncOperation]] = []

    // MARK: - Initializer

    /// Creates an instance of the `OperationProducer`.
    public init() {}

    // MARK: - OperationProducer

    /// Finishes the operation producer.
    ///
    /// This method increments the `finishCallCount` and signals
    /// completion on the underlying `AsyncStream`, if active.
    ///
    /// Consumers observing the operations stream will receive
    /// a termination event.
    public func finish() async throws {
        finishCallCount += 1

        for continuation in continuations {
            continuation.finish()
        }
        continuations.removeAll()
    }

    /// Returns an asynchronous stream of operation batches.
    ///
    /// Each call increments `operationsCallCount` and creates
    /// a new `AsyncStream`.
    ///
    /// The stream immediately emits all batches defined in
    /// `predefinedBatches`, in order, and remains open until
    /// `finish()` is called.
    ///
    /// - Returns: An `AsyncStream` emitting arrays of `AsyncOperation`.
    public func operations() -> AsyncStream<[AsyncOperation]> {
        operationsCallCount += 1

        return AsyncStream { [weak self] continuation in
            Task { [weak self] in
                guard let self else { return }
                self.continuations.append(continuation)
                for batch in self.predefinedBatches {
                    continuation.yield(batch)
                }
            }
        }
    }
}
