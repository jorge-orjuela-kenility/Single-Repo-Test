//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
internal import InternalUtilities
internal import Networking
import TruVideoFoundation

/// An asynchronous operation that registers an uploaded stream part with the server.
///
/// `RegisterPartOperation` sends a registration request to the server to associate a previously
/// uploaded part with the multipart upload session. This operation is called after a part has
/// been successfully uploaded to cloud storage and an `eTag` has been received.
///
/// ## Operation Flow
///
/// 1. Creates a POST request to `/upload/{sessionId}/part` with the part's number and `eTag`
/// 2. Sends the request to register the part with the server
/// 3. Receives an `UploadPartStatus` response confirming the registration
/// 4. Completes with success or failure result
///
/// ## Prerequisites
///
/// The part must have an `eTag` before this operation can succeed. The `eTag` is typically
/// obtained from the storage service after uploading the part data via `UploadDataOperation`.
///
/// ## Lifecycle Management
///
/// The operation supports cancellation, suspension, and resumption. Cancelling the operation
/// also cancels the underlying network request. Suspending pauses the request execution,
/// and resuming continues from where it was paused.
final class RegisterPartOperation: AsyncOperation, @unchecked Sendable {
    // MARK: - Private Properties

    private let eTag: String
    private let number: Int
    private var request: (any DataRequest)?
    private let sessionId: String

    // MARK: - Dependencies

    @Dependency(\.eventEmitter)
    private var eventEmitter: EventEmitter

    @Dependency(\.environment)
    private var environment: Environment

    @Dependency(\.session)
    private var session: Session

    // MARK: - Properties

    /// The result of the operation execution.
    ///
    /// `nil` until the operation completes. Contains either `.success(())` if the part was
    /// successfully registered, or `.failure(UtilityError)` if an error occurred.
    private(set) var result: Result<Void, UtilityError>?

    // MARK: - Types

    /// Errors specific to the part registration process.
    enum RegisterPartError: Error {
        /// Indicates that an expected `eTag` header was missing from the upload response.
        case missingETagHeader
    }

    // MARK: - Initializer

    /// Creates a new instance of a stream part with the given upload metadata.
    ///
    /// - Parameters:
    ///   - eTag: The entity tag (ETag) returned by the storage service after
    ///           successfully uploading this part. Used later to finalize the
    ///           multipart upload.
    ///   - number: The 1-based part number within the multipart upload sequence.
    ///             This must match the part number used when uploading to storage.
    ///   - sessionId: The identifier of the multipart upload session this part
    ///                belongs to. All parts of the same upload share the same
    ///                session ID.
    init(eTag: String, number: Int, sessionId: String) {
        self.eTag = eTag
        self.number = number
        self.sessionId = sessionId
    }

    // MARK: - Overridden methods

    /// Cancels the operation and its underlying network request.
    ///
    /// If the operation is not already cancelled, this method cancels the active network
    /// request (if any) and then calls the superclass implementation to mark the operation
    /// as cancelled.
    override func cancel() {
        if !isCancelled {
            request?.cancel()

            super.cancel()
        }
    }

    /// The main method for performing the operation’s work.
    ///
    /// This method initiates the part registration process by executing the pre-created
    /// network request. It validates the response, deserializes the `UploadPartStatus` response,
    /// and completes the operation with a success or failure result.
    ///
    /// The operation completes asynchronously, setting the `result` property and calling
    /// `finish()` when done.
    override func main() {
        Task {
            do {
                let request = session.request(
                    environment.baseURL.appending("/upload/\(sessionId)/part"),
                    method: .post,
                    parameters: [
                        "partNumber": number,
                        "eTag": eTag
                    ],
                    encoder: .json,
                    middleware: Middleware(interceptors: [AuthTokenInterceptor()], retriers: [])
                )

                self.request = request

                _ = try await request.validate()
                    .serializing(UploadPartStatus.self)
                    .result
                    .get()

                result = .success(())
                finish()
            } catch {
                let error = UtilityError(
                    kind: .RegisterPartOperationErrorReason.failedToRegisterPart,
                    underlyingError: error
                )

                result = .failure(error)
                finish()
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
            super.suspend()
        }
    }
}
