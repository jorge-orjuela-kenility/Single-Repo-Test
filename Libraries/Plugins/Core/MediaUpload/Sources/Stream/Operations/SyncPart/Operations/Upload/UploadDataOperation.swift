//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
internal import InternalUtilities
internal import Networking
import TruVideoFoundation

/// An asynchronous operation that uploads part data to cloud storage and retrieves an ETag.
///
/// `UploadDataOperation` handles the two-step process of uploading stream part data:
/// 1. Retrieves a presigned URL from the server for the upload session
/// 2. Uploads the data directly to cloud storage using the presigned URL
/// 3. Extracts the ETag from the storage response
///
/// ## Operation Flow
///
/// 1. Requests a presigned URL from `/upload/{sessionId}/parts` with count=1
/// 2. Uploads the data to the presigned URL using HTTP PUT
/// 3. Extracts the ETag header from the storage response
/// 4. Completes with success (containing the ETag) or failure result
///
/// ## ETag Extraction
///
/// The operation extracts the ETag from the HTTP response headers after a successful upload.
/// The ETag is required for registering the uploaded part with the server via `RegisterPartOperation`.
///
/// ## Lifecycle Management
///
/// The operation supports cancellation, suspension, and resumption. Cancelling cancels any
/// active network requests. Suspending pauses the upload request, and resuming continues
/// from where it was paused. If resumed before the upload request is created, the operation
/// will start from the beginning.
final class UploadDataOperation: AsyncOperation, @unchecked Sendable {
    // MARK: - Private Properties

    private let data: Data
    private let fileType: FileType
    private var requests: [any Request] = []
    private let sessionId: String

    // MARK: - Dependencies

    @Dependency(\.environment)
    private var environment: Environment

    @Dependency(\.session)
    private var session: Session

    // MARK: - Properties

    /// The result of the operation execution.
    ///
    /// `nil` until the operation completes. Contains either `.success(String)` with the ETag
    /// if the upload was successful, or `.failure(UtilityError)` if an error occurred.
    private(set) var result: Result<String, UtilityError>?

    // MARK: - Types

    /// Errors specific to the upload data process.
    enum UploadDataError: Error {
        /// Indicates that the ETag header was missing from the storage response.
        case missingETagHeader

        /// Indicates that no presigned URL was returned from the server.
        case missingPresignedURL
    }

    // MARK: - Initializer

    /// Creates a new operation to upload part data.
    ///
    /// - Parameters:
    ///   - data: The part data to upload to cloud storage.
    ///   - fileType: The file extension of the data to be uploaded.
    ///   - sessionId: The multipart upload session ID this part belongs to.
    init(data: Data, fileType: FileType, sessionId: String) {
        self.data = data
        self.fileType = fileType
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
            requests.forEach { $0.cancel() }
            super.cancel()
        }
    }

    /// The main method for performing the operation’s work.
    ///
    /// If the operation is cancelled, it explicitly finishes with a cancellation error.
    /// Otherwise, it initiates the asynchronous upload process.
    override func main() {
        Task {
            do {
                let request = session.request(
                    environment.baseURL.appending("/upload/\(sessionId)/parts"),
                    method: .get,
                    parameters: [
                        "count": 1
                    ],
                    encoder: .url,
                    middleware: Middleware(interceptors: [AuthTokenInterceptor()], retriers: [])
                )

                requests.append(request)

                let part = try await request
                    .validate(RequestValidator.validate)
                    .serializing(UploadPartResponse.self)
                    .result
                    .get()
                    .parts
                    .first
                    .unwrap(or: UploadDataError.missingPresignedURL)

                guard !isCancelled else {
                    explicitlyCancelled()
                    return
                }

                await uploadData(to: part.presignedUrl)
            } catch {
                let error = UtilityError(
                    kind: .UploadDataOperationErrorReason.failedToUploadData,
                    underlyingError: error
                )

                finish(with: .failure(error))
                return
            }
        }
    }

    /// Resumes the operation if it was previously suspended.
    ///
    /// If the operation is suspended and not cancelled, this method resumes the active network
    /// request if one exists. If no request exists yet, it starts the operation from the beginning.
    override func resume() {
        if state == .suspended, !isCancelled {
            requests.forEach { $0.resume() }
            super.resume()
        }
    }

    /// Suspends the operation if it is currently executing.
    ///
    /// If the operation is actively executing, this method suspends the underlying network
    /// request and transitions the operation state to suspended.
    override func suspend() {
        for request in requests {
            request.suspend()
        }

        super.suspend()
    }

    // MARK: - Private methods

    private func explicitlyCancelled() {
        let error = UtilityError(
            kind: .UploadDataOperationErrorReason.failedToUploadData,
            underlyingError: CancellationError()
        )

        finish(with: .failure(error))
    }

    private func finish(with result: Result<String, UtilityError>) {
        requests.forEach { $0.cancel() }
        requests.removeAll()

        self.result = result
        self.finish()
    }

    private func uploadData(to url: URL) async {
        let request = session.upload(data, to: url, method: .put, headers: [fileType.contentType])

        requests.append(request)

        Task.delayed(milliseconds: 500) {
            if state == .suspended {
                request.suspend()
            }
        }

        let response = await request
            .validate()
            .serializing(Empty.self, emptyResponseCodes: [200, 204, 205])

        guard !isCancelled else {
            explicitlyCancelled()
            return
        }

        guard var eTag = response.response?.value(forHTTPHeaderField: "ETag") else {
            let error = UtilityError(
                kind: .UploadDataOperationErrorReason.failedToUploadData,
                underlyingError: response.error ?? UploadDataError.missingETagHeader
            )

            finish(with: .failure(error))
            return
        }

        eTag = eTag.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        finish(with: .success(eTag))
    }
}

extension FileType {
    /// A convenience header representing the appropriate `Content-Type`
    /// for the current media file type.
    ///
    /// This value must match the MIME type used when generating any
    /// presigned upload URLs (e.g. for S3), otherwise signature validation
    /// will fail.
    fileprivate var contentType: HTTPHeader {
        switch self {
        case .aac:
            HTTPHeader(name: "Content-Type", value: "audio/aac")

        case .avi:
            HTTPHeader(name: "Content-Type", value: "video/x-msvideo")

        case .flac:
            HTTPHeader(name: "Content-Type", value: "audio/flac")

        case .flv:
            HTTPHeader(name: "Content-Type", value: "video/x-flv")

        case .g3pp:
            HTTPHeader(name: "Content-Type", value: "video/3gpp")

        case .jpeg:
            HTTPHeader(name: "Content-Type", value: "image/jpeg")

        case .jpg:
            HTTPHeader(name: "Content-Type", value: "image/jpeg")

        case .mkv:
            HTTPHeader(name: "Content-Type", value: "video/x-matroska")

        case .mov:
            HTTPHeader(name: "Content-Type", value: "video/quicktime")

        case .mp3:
            HTTPHeader(name: "Content-Type", value: "audio/mpeg")

        case .mp4:
            HTTPHeader(name: "Content-Type", value: "video/mp4")

        case .pdf:
            HTTPHeader(name: "Content-Type", value: "application/pdf")

        case .png:
            HTTPHeader(name: "Content-Type", value: "image/png")

        case .svg:
            HTTPHeader(name: "Content-Type", value: "image/svg+xml")

        case .unknown:
            HTTPHeader(name: "Content-Type", value: "application/octet-stream")

        case .wav:
            HTTPHeader(name: "Content-Type", value: "audio/wav")

        case .webm:
            HTTPHeader(name: "Content-Type", value: "video/webm")

        case .wmv:
            HTTPHeader(name: "Content-Type", value: "video/x-ms-wmv")
        }
    }
}
