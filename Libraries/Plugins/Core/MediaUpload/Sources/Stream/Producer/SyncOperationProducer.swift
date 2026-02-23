//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import CoreDataUtilities
import Foundation
import TruVideoFoundation

/// A producer that generates synchronization operations for stream parts based on database changes.
///
/// `SyncOperationProducer` observes changes to stream parts in the database and produces
/// `SyncPartOperation` instances for parts that match specific criteria. It monitors parts with
/// a status matching the stream's current status and fewer than 5 synchronization attempts.
///
/// ## Operation Flow
///
/// The producer creates an async stream that:
/// 1. Observes database changes for `StreamPartModel` entities matching the filter criteria
/// 2. Creates `SyncPartOperation` instances for each matching part
/// 3. Ensures all sync operations depend on the `StartSessionOperation` completing first
/// 4. Yields batches of operations as they become available
final class SyncOperationProducer: OperationProducer, @unchecked Sendable {
    // MARK: - Private Properties

    private var _continuations: [UUID: AsyncStream<[AsyncOperation]>.Continuation] = [:]
    private var _isFinished = false
    private let database: Database
    private let lock = NSLock()
    private let partRegistry: PartRegistry
    private let startSessionOperation: StartSessionOperation
    private let streamId: UUID

    // MARK: - Lazy Properties

    private lazy var streamTask = Task {
        let predicate: NSPredicate = \StreamModel.id == streamId && \StreamModel.sessionId != nil
        let asyncStream = await database.observeChanges(of: StreamModel.self, where: predicate)

        for await streams in asyncStream where !Task.isCancelled {
            await didReceive(streams)
        }
    }

    private lazy var task = Task {
        let acceptableStatuses = [StreamPartStatus.failed, .pending, .retrying, .uploading].map(\.rawValue)
        let statusPredicate: NSPredicate = StreamPartModel.statusAttribute << acceptableStatuses
        let predicate = \StreamPartModel.streamId == streamId && \StreamPartModel.attempts < 5 && statusPredicate
        let parts = await database.observeChanges(of: StreamPartModel.self, where: predicate)

        for await parts in parts where !Task.isCancelled {
            let operations = await makeOperations(for: parts)

            if !operations.isEmpty {
                yield(operations)
            }
        }
    }

    // MARK: - Computed Properties

    private var continuations: [UUID: AsyncStream<[AsyncOperation]>.Continuation] {
        get { lock.withLock { _continuations } }
        set { lock.withLock { _continuations = newValue } }
    }

    private var isFinished: Bool {
        get { lock.withLock { _isFinished } }
        set { lock.withLock { _isFinished = newValue } }
    }

    // MARK: - Initializer

    /// Creates a new operation producer for synchronizing stream parts.
    ///
    /// The producer uses the provided model store to initialize a `StartSessionOperation` that
    /// will be used as a dependency for all sync operations. The producer then observes database
    /// changes to stream parts and generates sync operations as needed.
    ///
    /// - Parameters:
    ///   - stream: The stream that defines which parts should be synchronized.
    ///   - database: The database instance used to observe changes to stream parts and manage
    ///               part models.
    ///   - partRegistry: A registry that maintains a collection of stream parts for quick lookup.
    init(stream: StreamModel, database: Database, partRegistry: PartRegistry) {
        self.database = database
        self.partRegistry = partRegistry
        self.streamId = stream.id
        self.startSessionOperation = StartSessionOperation(stream: stream)

        Task {
            await streamTask.value
        }
    }

    // MARK: - Instance methods

    /// Finishes the operation stream, signaling that no more operations will be produced.
    ///
    /// This method should be called when synchronization is complete or needs to be cancelled.
    /// After calling this method, the continuation will be finished and no further operations
    /// will be yielded.
    func finish() async throws {
        if !isFinished {
            do {
                let stream = try await database.find(StreamModel.self, with: streamId)

                task.cancel()
                isFinished = true

                if let sessionId = stream.sessionId, !sessionId.isEmpty, stream.status != .cancelled {
                    let operation = CompleteStreamOperation(stream: stream, sessionId: sessionId)

                    yield([operation])
                }

                continuations.values.forEach { $0.finish() }
            } catch let error where error.kind == .DatabaseError.findFailed {
                // NOTE: We assume a find failure as an intentional deletion
                // so we stop the producer
                task.cancel()
                continuations.values.forEach { $0.finish() }
            } catch {
                throw UtilityError(kind: .OperationProducerErrorReason.failedToFinish, underlyingError: error)
            }
        }
    }

    /// Returns the async stream of synchronization operations.
    ///
    /// - Returns: An `AsyncStream` that yields batches of `AsyncOperation` instances as
    ///   matching stream parts are detected in the database.
    func operations() -> AsyncStream<[AsyncOperation]> {
        AsyncStream<[AsyncOperation]> { continuation in
            guard !isFinished else {
                continuation.finish()
                return
            }

            let handle = UUID()

            continuation.onTermination = { [weak self] _ in
                self?.continuations.removeValue(forKey: handle)
            }

            continuation.yield([startSessionOperation])
            continuations[handle] = continuation
        }
    }

    // MARK: - Private methods

    private func didReceive(_ streams: [StreamModel]) async {
        if let sessionId = streams.last?.sessionId, !sessionId.isEmpty {
            streamTask.cancel()
            await task.value
        }
    }

    private func makeOperations(for parts: [StreamPartModel]) async -> [AsyncOperation] {
        var operations: [AsyncOperation] = []

        do {
            let now = Date()
            let stream = try await database.find(StreamModel.self, with: streamId)
            let isValidStream = ![.cancelled, .completed, .failed, .suspended].contains(stream.status)

            guard let sessionId = stream.sessionId, !sessionId.isEmpty, isValidStream else {
                return operations
            }

            for part in parts {
                if let nextAttemptDate = part.nextAttemptDate, nextAttemptDate >= now, part.status != .retrying {
                    continue
                }

                let operation = SyncPartOperation(part: part, fileType: stream.fileType, sessionId: sessionId)

                if let partHandle = partRegistry.value(forKey: part.id), await partHandle.register(operation) {
                    operation.addDependency(startSessionOperation)
                    operations.append(operation)
                }
            }
        } catch {
            print(error)
        }

        return operations
    }

    private func yield(_ operations: [AsyncOperation]) {
        let continuations = continuations.values

        for continuation in continuations {
            continuation.yield(operations)
        }
    }
}
