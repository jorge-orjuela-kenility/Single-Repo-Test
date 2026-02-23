//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
internal import InternalUtilities
internal import Networking
import TruVideoFoundation

/// An asynchronous operation that finalizes a multipart upload stream.
///
/// `CompleteStreamOperation` sends a completion request to the server to finalize a multipart
/// upload stream. This operation is called after all stream parts have been successfully uploaded
/// and registered, signaling to the server that the upload is complete and the final media file
/// should be assembled.
///
/// ## Operation Flow
///
/// 1. Validates that the stream has a valid `sessionId`
/// 2. Sends a POST request to `/upload/{sessionId}/complete/stream`
/// 3. Accepts an empty response with status code 202 (Accepted)
/// 4. Completes with success or failure result
///
/// ## Prerequisites
///
/// The stream must have a `sessionId` before this operation can succeed. The `sessionId` is
/// typically obtained from `StartSessionOperation` and must be present after all parts have
/// been uploaded and registered.
///
/// ## Lifecycle Management
///
/// The operation supports cancellation, suspension, and resumption. Cancelling the operation
/// also cancels the underlying network request and sets the result to failure with a cancellation
/// error. Suspending pauses the request execution, and resuming continues from where it was paused.
final class CompleteStreamOperation: AsyncOperation, @unchecked Sendable {
    // MARK: - Private Properties

    private var request: (any DataRequest)?
    private let sessionId: String
    private let stream: StreamModel

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
    /// `nil` until the operation completes. Contains either `.success(())` if the stream was
    /// successfully completed, or `.failure(UtilityError)` if an error occurred.
    private(set) var result: Result<Void, UtilityError>?

    // MARK: - Types

    /// Errors specific to the complete stream process.
    enum CompleteStreamError: Error {
        /// Indicates that an expected `sessionId` was missing from the stream.
        case missingSessionId
    }

    // MARK: - Initializer

    /// Creates a new operation to complete a stream.
    ///
    /// - Parameters:
    ///    - stream: The model that needs a session initialized.
    ///    - sessionId: The id of the session to complete.
    init(stream: StreamModel, sessionId: String) {
        self.sessionId = sessionId
        self.stream = stream
    }

    // MARK: - Overridden methods

    /// Cancels the operation and its underlying network request.
    ///
    /// If the operation is not already cancelled, this method cancels the active network
    /// request (if any), sets the result to failure with a cancellation error, finishes
    /// the operation, and then calls the superclass implementation to mark the operation
    /// as cancelled.
    override func cancel() {
        if !isCancelled {
            let error = UtilityError(
                kind: .CompleteStreamOperationErrorReason.failedToCompleteStream,
                underlyingError: CancellationError()
            )

            request?.cancel()
            result = .failure(error)
            eventEmitter.emit(StreamOperationEvent.cancelled(streamId: stream.id))

            super.cancel()
        }
    }

    /// The main method for performing the operation's work.
    ///
    /// This method initiates the stream completion process. It validates that the stream has
    /// a `sessionId`, creates a POST request to complete the stream, and handles the response.
    /// The server may return an empty response with status code 202 (Accepted) to indicate
    /// successful completion.
    ///
    /// The operation completes asynchronously, setting the `result` property and calling
    /// `finish()` when done.
    override func main() {
        Task {
            do {
                guard !sessionId.isEmpty else {
                    throw CompleteStreamError.missingSessionId
                }

                let parameters: Parameters = [
                    "includeInReport": stream.isIncludedInReport,
                    "isLibrary": stream.isLibrary,
                    "metadata": stream.metadata,
                    "title": stream.title,
                    "tags": stream.tags
                ]

                let request = session.request(
                    environment.baseURL.appending("/upload/\(sessionId)/complete/stream"),
                    method: .post,
                    parameters: parameters,
                    encoder: .json,
                    middleware: Middleware(interceptors: [AuthTokenInterceptor()], retriers: [])
                )

                self.request = request

                _ = try await request
                    .validate()
                    .serializing(Empty.self, emptyResponseCodes: [202])
                    .result
                    .get()

                finish(with: nil)
            } catch {
                finish(with: error)
            }
        }
    }

    /// Resumes the operation if it was previously suspended.
    ///
    /// If the operation is in a suspended state, this method resumes the underlying network
    /// request and transitions the operation state back to running.
    override func resume() {
        if state == .suspended {
            request?.resume()
            state = .running
        }
    }

    /// Suspends the operation if it is currently executing.
    ///
    /// If the operation is actively executing, this method suspends the underlying network
    /// request and transitions the operation state to suspended.
    override func suspend() {
        if isExecuting {
            request?.suspend()
            eventEmitter.emit(StreamOperationEvent.suspended(streamId: stream.id))

            super.suspend()
        }
    }

    // MARK: - Private methods

    private func finish(with error: Error?) {
        defer { finish() }

        guard let error else {
            result = .success(())
            eventEmitter.emit(StreamOperationEvent.completed(streamId: stream.id))

            return
        }

        let wrappedError = UtilityError(
            kind: .CompleteStreamOperationErrorReason.failedToCompleteStream,
            underlyingError: error
        )

        result = .failure(wrappedError)
        eventEmitter.emit(StreamOperationEvent.failed(streamId: stream.id, error: wrappedError))
    }
}
