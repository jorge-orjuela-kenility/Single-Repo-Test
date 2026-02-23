//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import Foundation
internal import TruVideoFoundation
internal import TruVideoMediaUpload

extension ErrorReason {
    /// Error reasons for stream request operations.
    ///
    /// These reasons are used to wrap stream request failures in ``UtilityError``
    /// with a stable error code for logging and diagnostics.
    enum TruvideoSdkStreamRequestErrorReason {
        /// Error indicating the stream upload failed to start or complete.
        static let uploadFailed = ErrorReason(rawValue: "STREAM_REQUEST_UPLOAD_FAILED")
    }
}

/// Represents a single stream-based upload request.
///
/// This class wraps a ``MUStream`` instance and exposes a public API to drive
/// the lifecycle of a streaming upload (start, pause, resume, cancel) while
/// providing metadata, tags, and reporting flags used when completing the upload.
///
/// The request also publishes progress and completion events via Combine so
/// clients can observe status changes without polling.
open class TruvideoSdkMediaStreamRequest {
    // MARK: - Private Properties

    private let stream: MUStream

    // MARK: - Properties

    /// Internal subject that emits the final upload result or an error.
    ///
    /// This subject is bridged to the public ``completionHandler`` publisher.
    var completionPublisher = PassthroughSubject<String, Error>()

    // MARK: - Public Properties

    /// Unique identifier for the upload request.
    public let id: UUID

    /// Timestamp when the request was created, if available.
    ///
    /// This value is optional because requests may be reconstructed from storage
    /// or created in-memory before a timestamp is assigned.
    public let createdAt: Date

    /// Local file URL backing this stream request.
    ///
    /// This URL points to the file currently being streamed (typically a video or
    /// media file on disk). It may reference a temporary location, so consumers
    /// should not assume long-term persistence beyond the upload lifecycle.
    ///
    /// Use this value to correlate a stream request with the original media file
    /// (for example, when listing active streams or showing upload UI).
    public let fileUrl: URL

    /// Indicates whether the uploaded media should be included in reports.
    ///
    /// This flag is sent when finishing the stream. It can be updated before
    /// calling ``upload(with:)``.
    public private(set) var isIncludedInReport: Bool

    /// Indicates whether the uploaded media belongs to a shared/library collection.
    ///
    /// This flag is sent when finishing the stream. It can be updated before
    /// calling ``upload(with:)``.
    public private(set) var isLibrary: Bool

    /// Metadata attached to the uploaded media.
    ///
    /// The metadata is serialized and sent during stream completion. Update it
    /// prior to calling ``upload(with:)``.
    public private(set) var metadata: TruvideoSdkMediaMetadata

    /// Remote identifier assigned by the backend for the upload, if available.
    public let remoteId: String?

    /// Current status of the upload request.
    public let status: Status

    /// Tags attached to the uploaded media.
    ///
    /// Tags are sent during stream completion for categorization and filtering.
    public private(set) var tags: TruvideoSdkMediaTags

    // MARK: - Computed Properties

    /// A publisher that emits the remote media identifier upon completion.
    ///
    /// The publisher completes with either the media identifier (`String`) or an `Error`
    /// when the upload finishes or fails.
    public var completionHandler: AnyPublisher<String, Error> {
        completionPublisher.eraseToAnyPublisher()
    }

    /// Duration in milli seconds.
    public var durationMilliseconds: Int? {
        guard let duration = fileUrl.getDuration() else {
            return nil
        }

        return duration * 1_000
    }

    /// File type
    public var fileType: TruvideoSdkMediaType {
        fileUrl.getFileType()
    }

    // MARK: - Types

    /// Options applied when finishing a stream and completing the upload on the server.
    ///
    /// Use this type to pass title, tags, metadata, and reporting flags into
    /// ``upload(with:)``. The values are sent with the completion request so
    /// the backend can classify the media, include it in reports, or mark it as
    /// library content.
    public struct Options {
        /// Whether the completed media should be included in reporting or analytics.
        public let isIncludedInReport: Bool

        /// Whether the media belongs to a shared or library collection.
        public let isLibrary: Bool

        /// Metadata associated with the media.
        public let metadata: TruvideoSdkMediaMetadata

        /// Key–value tags attached to the media for categorization or filtering.
        public let tags: [String: String]

        /// Human-readable title or name of the media.
        public let title: String

        // MARK: - Initializer

        /// Creates options for stream completion.
        ///
        /// - Parameters:
        ///   - isIncludedInReport: Whether the media should be included in reporting. Defaults to `true`.
        ///   - isLibrary: Whether the media belongs to a library collection. Defaults to `false`.
        ///   - metadata: Metadata to attach to the media.
        ///   - tags: Tags dictionary. Defaults to an empty dictionary.
        ///   - title: Human-readable title or name of the media. Defaults to an empty string.
        public init(
            isIncludedInReport: Bool = true,
            isLibrary: Bool = false,
            metadata: TruvideoSdkMediaMetadata = TruvideoSdkMediaMetadata.builder().build(),
            tags: [String: String] = [:],
            title: String = ""
        ) {
            self.isIncludedInReport = isIncludedInReport
            self.isLibrary = isLibrary
            self.metadata = metadata
            self.tags = tags
            self.title = title
        }
    }

    /// Represents the lifecycle state of a stream request.
    public enum Status: String {
        /// The stream upload was explicitly cancelled and cannot proceed further.
        case cancelled

        /// The request failed due to an error.
        case error

        /// The request is paused and can be resumed.
        case paused

        /// The request is ready to start and has not begun uploading.
        case pending

        /// The request is currently uploading.
        case processing

        /// The request finished uploading and was successfully completed.
        case uploaded
    }

    // MARK: - Initializer

    /// Creates a new instance of `TruvideoSdkStreamRequest`.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the upload request.
    ///   - createdAt: Optional creation date for the request.
    ///   - fileURL: The URL of the file to be uploaded.
    ///   - stream: Stream object that manages multipart upload operations.
    ///   - includeInReport: Whether the upload should be included in reports.
    ///   - isLibrary: Whether the upload belongs to a library collection.
    ///   - metadata: Metadata attached to the uploaded file.
    ///   - remoteId: Optional remote identifier assigned by the backend.
    ///   - status: Initial status of the request. Defaults to `.pending`.
    ///   - tags: Tags associated with the uploaded file.
    init(stream: MUStream) {
        self.id = stream.id
        self.createdAt = stream.createdAt
        self.fileUrl = stream.fileURL
        self.stream = stream
        self.isIncludedInReport = stream.isIncludedInReport
        self.isLibrary = stream.isLibrary
        self.metadata = TruvideoSdkMediaMetadata(metadata: stream.metadata)
        self.remoteId = stream.mediaId?.uuidString
        self.tags = TruvideoSdkMediaTags(dictionary: stream.tags)

        if [
            .failed,
            .running,
            .suspended
        ].contains(stream.status), !UserDefaults.standard.bool(forKey: stream.id.uuidString) {
            self.status = .pending
        } else {
            self.status = Status.from(stream.status)
        }

        stream.onCompletion { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(mediaId):
                self.completionPublisher.send(mediaId.uuidString)
                self.completionPublisher.send(completion: .finished)

            case let .failure(error):
                self.completionPublisher.send(completion: .failure(error))
                reset()
            }
        }
    }

    // MARK: - Open methods

    /// Cancels the upload request.
    ///
    /// - Throws: An error if the cancellation fails.
    open func cancel() async throws {
        try await stream.cancel()
    }

    /// Deletes the upload request.
    ///
    /// - Throws: An error if the deletion fails.
    open func delete() async throws {
        try await stream.delete()
    }

    /// Pauses the upload request.
    ///
    /// - Throws: An error if the pause operation fails.
    open func pause() async throws {
        try await stream.suspend()
    }

    /// Resumes the upload request.
    ///
    /// - Throws: An error if the resume operation fails.
    open func resume() async throws {
        try await stream.resume()
    }

    /// Retries the upload if it previously failed.
    ///
    /// - Throws: An error if the retry fails.
    open func retry() async throws {
        try await stream.retry()
    }

    /// Initiates the upload process for the request.
    ///
    /// This method finalizes the stream with the provided options and triggers
    /// the backend completion step.
    ///
    /// - Parameter options: Values used to complete the upload (title, tags, metadata, flags).
    /// - Throws: ``UtilityError`` with kind ``ErrorReason.TruvideoSdkStreamRequestErrorReason.uploadFailed``
    ///   when the stream fails to start or complete.
    open func upload(with options: Options) throws {
        defer { UserDefaults.standard.set(true, forKey: stream.id.uuidString) }

        guard stream.status != .failed else {
            let error = TruvideoSdkMediaError.streamRequestFailed
            completionPublisher.send(completion: .failure(error))

            return
        }

        do {
            guard status == .pending else {
                throw TruvideoSdkMediaError.unableToResumeUpload(message: "Task already processing")
            }

            isIncludedInReport = options.isIncludedInReport
            isLibrary = options.isLibrary
            metadata = options.metadata
            tags = TruvideoSdkMediaTags(dictionary: options.tags)

            let options = MUStream.Options(
                isIncludedInReport: isIncludedInReport,
                isLibrary: isLibrary,
                metadata: metadata.metadata,
                tags: tags.dictionary,
                title: options.title
            )

            Task {
                do {
                    try await stream.finish(with: options)
                } catch {
                    self.completionPublisher.send(completion: .failure(error))
                }
            }
        } catch {
            throw UtilityError(kind: .TruvideoSdkStreamRequestErrorReason.uploadFailed, underlyingError: error)
        }
    }

    // MARK: - Private methods

    /// Restores the completion publishers for the upload request.
    private func reset() {
        completionPublisher = PassthroughSubject<String, Error>()
    }
}

extension TruvideoSdkMediaStreamRequest: Equatable {
    // MARK: - Equatable

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: TruvideoSdkMediaStreamRequest, rhs: TruvideoSdkMediaStreamRequest) -> Bool {
        lhs.id == rhs.id
    }
}

private extension TruvideoSdkMediaStreamRequest.Status {
    /// Maps internal `MUStreamStatus` values to the public stream request status.
    static func from(_ status: MUStreamStatus) -> TruvideoSdkMediaStreamRequest.Status {
        switch status {
        case .cancelled:
            .cancelled

        case .completed:
            .uploaded

        case .failed:
            .error

        case .ready:
            .pending

        case .running:
            .processing

        case .suspended:
            .paused
        }
    }
}
