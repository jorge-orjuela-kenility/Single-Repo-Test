//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
internal import InternalUtilities
internal import Networking
import TruVideoFoundation

/// An asynchronous operation that synchronizes a single stream part with the server.
///
/// `SyncPartOperation` handles the complete upload and registration process for a single part
/// of a multipart stream upload. It coordinates two sub-operations: uploading the part data to
/// cloud storage and registering the uploaded part with the server.
///
/// ## Operation Flow
///
/// 1. Checks if the part already has an `eTag` (indicating it was previously uploaded)
/// 2. If no `eTag` exists, uploads the part data and retrieves the `eTag` from storage
/// 3. Registers the part with the server using the `eTag` and part number
/// 4. Updates the part's status to "COMPLETED" on success, or "FAILED"/"CANCELLED" on error
///
/// ## Sub-Operations
///
/// The operation uses an internal `OperationQueue` with serial execution (`maxConcurrentOperationCount = 1`)
/// to coordinate two sub-operations:
/// - `UploadDataOperation`: Uploads the part data to cloud storage and returns an `eTag`
/// - `RegisterPartOperation`: Registers the uploaded part with the server using the `eTag` and part number
///
/// ## Dependencies
///
/// This operation typically depends on `StartSessionOperation` to ensure the multipart upload
/// session is initialized before attempting to upload parts. This dependency is managed by
/// operation producers.
///
/// ## Lifecycle Management
///
/// The operation supports cancellation, suspension, and resumption. Cancelling propagates to
/// all sub-operations. Suspending pauses the queue and all active sub-operations, while resuming
/// reactivates them.
final class SyncPartOperation: AsyncOperation, @unchecked Sendable {
    // MARK: - Private Properties

    private var _operations = Set<AsyncOperation>()
    private var fileType: FileType
    private let lock = NSLock()
    private let operationQueue = OperationQueue()
    private let part: StreamPartModel
    private let sessionId: String

    // MARK: - Dependencies

    @Dependency(\.environment)
    private var environment: Environment

    @Dependency(\.eventEmitter)
    private var eventEmitter: EventEmitter

    @Dependency(\.session)
    private var session: Session

    // MARK: - Properties

    /// The result of the operation execution.
    ///
    /// `nil` until the operation completes. Contains either `.success(())` if the part was
    /// successfully synchronized, or `.failure(UtilityError)` if an error occurred.
    private(set) var result: Result<Void, UtilityError>?

    // MARK: - Computed Properties

    private var operations: Set<AsyncOperation> {
        get { lock.withLock { _operations } }
        set { lock.withLock { _operations = newValue } }
    }

    // MARK: - Types

    /// Errors specific to the part synchronization process.
    enum SyncPartError: Error {
        /// Indicates that an expected `eTag` header was missing from the upload response.
        case missingETagHeader

        /// Indicates that the part registration operation did not produce a result.
        case missingPartRegistrationResult
    }

    // MARK: - Initializer

    /// Creates a new operation to synchronize a stream part.
    ///
    /// The operation is configured with a serial operation queue (`maxConcurrentOperationCount = 1`)
    /// to ensure sub-operations (upload and registration) execute sequentially in the correct order.
    ///
    /// - Parameters:
    ///   - part: The stream part to synchronize.
    ///   - fileType: The file extension of the data to be uploaded.
    init(part: StreamPartModel, fileType: FileType, sessionId: String) {
        self.fileType = fileType
        self.part = part
        self.sessionId = sessionId
        self.operationQueue.maxConcurrentOperationCount = 1
    }

    // MARK: - Overridden methods

    /// Cancels the operation and all its sub-operations.
    ///
    /// Cancels all operations in the internal queue and then calls the superclass implementation
    /// to mark this operation as cancelled.
    override func cancel() {
        if !isCancelled {
            operationQueue.cancelAllOperations()
            super.cancel()

            let error = UtilityError(
                kind: .SyncPartOperationErrorReason.failedToSyncPart,
                underlyingError: CancellationError()
            )

            result = .failure(error)
            eventEmitter.emit(StreamPartOperationEvent.cancelled(partId: part.id))
        }
    }

    /// The main method for performing the operation’s work.
    override func main() {
        Task {
            eventEmitter.emit(StreamPartOperationEvent.uploading(partId: part.id))

            var eTag = part.eTag

            if eTag == nil {
                do {
                    let data = try Data(contentsOf: part.localFileUrl)
                    let newETag = try await upload(data)

                    eTag = newETag

                    eventEmitter.emit(StreamPartOperationEvent.uploaded(partId: part.id, eTag: newETag))
                } catch {
                    finish(with: error)
                    return
                }
            }

            guard !isCancelled else {
                return
            }

            guard let eTag, !eTag.isEmpty else {
                finish(with: SyncPartError.missingETagHeader)
                return
            }

            let operation = RegisterPartOperation(eTag: eTag, number: part.number, sessionId: sessionId)

            operation.completionBlock = { [weak self, weak operation] in
                if let self, let operation {
                    operations.remove(operation)

                    guard let result = operation.result else {
                        finish(with: SyncPartError.missingPartRegistrationResult)
                        return
                    }

                    finish(with: result.failure)
                }
            }

            operations.insert(operation)
            operationQueue.addOperation(operation)
        }
    }

    /// Resumes the operation if it was previously suspended.
    ///
    /// If the operation is cancelled, it explicitly finishes with a cancellation error.
    /// Otherwise, if suspended, it resumes all active sub-operations and reactivates the
    /// operation queue.
    override func resume() {
        if isSuspended {
            for operation in operations where operation.isSuspended {
                operation.resume()
            }

            operationQueue.isSuspended = false

            guard operations.isEmpty else {
                eventEmitter.emit(StreamPartOperationEvent.uploading(partId: part.id))
                return
            }

            eventEmitter.emit(StreamPartOperationEvent.resumed(partId: part.id))
        }

        super.resume()
    }

    /// Suspends the operation if it is currently executing.
    ///
    /// Suspends the operation queue and all active sub-operations, then transitions this
    /// operation's state to suspended.
    override func suspend() {
        operationQueue.isSuspended = true

        for operation in operations {
            operation.suspend()
        }

        eventEmitter.emit(StreamPartOperationEvent.suspended(partId: part.id))
        super.suspend()
    }

    // MARK: - Private methods

    private func finish(with error: Error?) {
        guard let error else {
            result = .success(())
            finish()

            eventEmitter.emit(StreamPartOperationEvent.completed(partId: part.id))
            return
        }

        let wrappedError = UtilityError(
            kind: .SyncPartOperationErrorReason.failedToSyncPart,
            underlyingError: error
        )

        result = .failure(wrappedError)
        finish()
        eventEmitter.emit(StreamPartOperationEvent.failed(partId: part.id))
    }

    private func upload(_ data: Data) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let operation = UploadDataOperation(data: data, fileType: fileType, sessionId: sessionId)

            operation.completionBlock = { [weak self, weak operation] in
                if let self, let operation {
                    operations.remove(operation)

                    guard let result = operation.result else {
                        continuation.resume(throwing: SyncPartError.missingETagHeader)
                        return
                    }

                    switch result {
                    case let .failure(error):
                        continuation.resume(throwing: error)

                    case let .success(eTag):
                        continuation.resume(returning: eTag)
                    }
                }
            }

            operations.insert(operation)
            operationQueue.addOperation(operation)
        }
    }
}
