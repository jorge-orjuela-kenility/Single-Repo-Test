//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
internal import InternalUtilities
internal import Networking
import TruVideoFoundation

/// An asynchronous operation that initializes a multipart upload session for a stream.
///
/// `StartSessionOperation` creates a new multipart upload session on the server by sending a request
/// to initialize the upload. This operation must complete successfully before any stream parts can be
/// uploaded, as it provides the `sessionId` that is required for coordinating multipart uploads.
///
/// ## Operation Flow
///
/// 1. Checks if the stream already has a `sessionId`; if so, the operation completes immediately
/// 2. If no session exists, sends a POST request to `/upload/start/stream` with the stream's file type
/// 3. Receives an `UploadSession` response containing the `uploadId`
/// 4. Updates the stream's `sessionId` with the received upload ID
/// 5. Completes with success or failure result
///
/// ## Dependencies
///
/// Other operations (such as `SyncPartOperation`) depend on this operation to ensure the session
/// is initialized before attempting to upload parts. This dependency is typically managed by
/// operation producers that add this operation as a dependency.
///
/// ## Lifecycle Management
///
/// The operation supports cancellation, suspension, and resumption. Cancelling the operation
/// also cancels the underlying network request. Suspending pauses the request execution,
/// and resuming continues from where it was paused.
final class StartSessionOperation: AsyncOperation, @unchecked Sendable {
    // MARK: - Private Properties

    private var request: (any DataRequest)?
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
    /// `nil` until the operation completes. Contains either `.success(())` if the session
    /// was initialized successfully, or `.failure(Error)` if an error occurred.
    private(set) var result: Result<Void, Error>?

    /// Creates a new operation to initialize a multipart upload session.
    ///
    /// - Parameter stream: The model that needs a session initialized.
    init(stream: StreamModel) {
        self.stream = stream
    }

    // MARK: - Overridden methods

    /// Cancels the operation and its underlying network request.
    ///
    /// If the operation is not already cancelled, this method cancels the active network
    /// request (if any) and then calls the superclass implementation to mark the operation
    /// as cancelled.
    override func cancel() {
        if !isCancelled {
            let error = UtilityError(
                kind: .StartSessionOperationErrorReason.failedToStartNewStreamSession,
                underlyingError: CancellationError()
            )

            request?.cancel()
            result = .failure(error)
            eventEmitter.emit(StreamOperationEvent.cancelled(streamId: stream.id))

            super.cancel()
        }
    }

    /// The main method for performing the operation’s work.
    ///
    /// This method initiates the session initialization process. If the stream already has
    /// a `sessionId`, the operation completes immediately. Otherwise, it creates a network
    /// request to initialize a new multipart upload session and updates the stream with
    /// the received session ID.
    ///
    /// The operation completes asynchronously, setting the `result` property and calling
    /// `finish()` when done.
    override func main() {
        guard stream.sessionId == nil else {
            result = .success(())
            finish()

            return
        }

        eventEmitter.emit(StreamOperationEvent.creatingSession(for: stream.id))

        let request = session.request(of: stream.fileType, url: environment.baseURL.appending("/upload/start/stream"))

        self.request = request

        Task {
            do {
                let session = try await request
                    .serializing(UploadSession.self)
                    .result
                    .get()

                eventEmitter.emit(
                    StreamOperationEvent.sessionCreated(
                        for: stream.id,
                        sessionId: session.uploadId,
                        mediaId: session.mediaId
                    )
                )

                result = .success(())
                finish()
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
            eventEmitter.emit(StreamOperationEvent.resumed(streamId: stream.id))
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

    private func finish(with error: Error) {
        let error = UtilityError(
            kind: .StartSessionOperationErrorReason.failedToStartNewStreamSession,
            underlyingError: error
        )

        result = .failure(error)
        eventEmitter.emit(StreamOperationEvent.failed(streamId: stream.id, error: error))
        finish()
    }
}

extension Session {
    /// Creates a POST request to initialize a multipart upload session for the specified file type.
    ///
    /// This method constructs an authenticated HTTP POST request to start a new multipart upload
    /// session on the server. The request includes the file type information in the request body
    /// and applies authentication middleware to ensure the request is properly authorized. The
    /// resulting request is validated using the standard request validator before being returned.
    ///
    /// - Parameters:
    ///   - fileType: The type of media file (e.g., `.mp4`, `.mov`, `.jpg`) that will be uploaded
    ///               in this multipart session.
    ///   - url: The endpoint URL where the session initialization request should be sent.
    ///
    /// - Returns: A configured `DataRequest` instance that can be executed to initialize the
    ///            multipart upload session. The request is authenticated and validated.
    fileprivate func request(of fileType: FileType, url: String) -> any DataRequest {
        let middleware = Middleware(interceptors: [AuthTokenInterceptor()], retriers: [])
        let parameters = [
            "media": [
                "fileType": fileType.rawValue
            ]
        ]

        return request(url, method: .post, parameters: parameters, encoder: .json, middleware: middleware)
            .validate(RequestValidator.validate)
    }
}
