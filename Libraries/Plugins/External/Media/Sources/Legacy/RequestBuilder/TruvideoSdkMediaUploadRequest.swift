//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import Foundation

/// File upload request progress
public struct TruvideoSdkMediaFileUploadProgress {
    /// Uploaded percetange
    public let percentage: Double
}

/// Struct representing the progress of a file upload request.
public final class TruvideoSdkMediaUploadRequest {
    // MARK: - Private Properties

    private let engine: TruvideoSdkMediaUploadEngine

    // MARK: - Properties

    /// A subject that emits the result of the upload request upon completion.
    var completionPublisher = PassthroughSubject<TruvideoSdkMediaFileUploadResult, Error>()

    /// A subject that emits progress updates for the upload request.
    let progressPublisher = PassthroughSubject<TruvideoSdkMediaFileUploadProgress, Never>()

    /// The URL of the file to be uploaded.
    let fileURL: URL

    // MARK: - Public Properties

    /// A publisher that emits progress updates for the upload request.
    public var progressHandler: AnyPublisher<TruvideoSdkMediaFileUploadProgress, Never> {
        progressPublisher.eraseToAnyPublisher()
    }

    /// A publisher that emits the result of the upload request upon completion.
    public var completionHandler: AnyPublisher<TruvideoSdkMediaFileUploadResult, Error> {
        completionPublisher.eraseToAnyPublisher()
    }

    /// Upload id
    public let id: UUID

    /// Creation date milliseconds
    public let createdAt: Date?

    /// Error message
    public let errorMessage: String?

    /// Remote URL
    public let remoteId: String?

    /// Remote URL
    public let remoteURL: URL?

    /// Additional metadata attached to the uploaded file.
    public let metadata: TruvideoSdkMediaMetadata

    /// Send to OEM
    public var includeInReport: Bool?

    /// Is Library
    public var isLibrary: Bool?

    /// Creation date milliseconds
    public let status: Status

    /// Additional tags attached to the uploaded file.
    public let tags: TruvideoSdkMediaTags

    /// Transcription length
    public var transcriptionLength: Float?

    /// Transcription url
    public let transcriptionURL: String?

    /// Update date milliseconds
    public let updatedAt: Date?

    /// Progress
    public let uploadProgress: Double

    // MARK: - Computed Properties

    /// Duration in milli seconds
    public var durationMilliseconds: Int? {
        guard let duration = fileURL.getDuration() else {
            return nil
        }

        return duration * 1_000
    }

    /// File path
    public var filePath: String {
        fileURL.path
    }

    /// File type
    public var fileType: TruvideoSdkMediaType {
        fileURL.getFileType()
    }

    // MARK: - Types

    /// Represents the current lifecycle state of an upload request.
    ///
    /// Use this value to drive UI and business logic based on the upload progress.
    public enum Status: Int {
        /// The request was created but has not started yet.
        case idle

        /// The upload is actively sending data to the server.
        case processing

        /// The upload finished transferring and is syncing server-side metadata.
        case synchronizing

        /// The upload finished successfully.
        case completed

        /// The upload failed.
        case error

        /// The upload was cancelled by the user or system.
        case cancelled

        /// The upload was paused and can be resumed.
        case paused
    }

    // MARK: - Initializer

    /// Creates a new instance of `TruvideoSdkMediaUploadRequest`
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the upload request.
    ///   - fileURL: The URL of the file to be uploaded.
    ///   - metadata: Metadata attached to the uploaded file.
    ///   - tags: Tags associated with the uploaded file.
    ///   - engine: The upload engine handling the upload process.
    ///   - uploadProgress: The initial upload progress (default is 0).
    ///   - errorMessage: An optional error message.
    ///   - remoteId: An optional remote identifier.
    ///   - remoteURL: An optional remote URL.
    ///   - transcriptionURL: An optional transcription URL.
    ///   - transcriptionLength: An optional transcription length.
    ///   - status: The initial status of the upload request (default is .idle).
    ///   - createdAt: An optional creation date.
    ///   - updatedAt: An optional update date.
    ///   - includeInReport: An optional flag indicating if it should be included in the report.
    init(
        id: UUID,
        fileURL: URL,
        metadata: TruvideoSdkMediaMetadata = .init(metadata: [:]),
        tags: TruvideoSdkMediaTags = .init(dictionary: [:]),
        engine: TruvideoSdkMediaUploadEngine,
        uploadProgress: Double = 0,
        errorMessage: String? = nil,
        remoteId: String? = nil,
        remoteURL: URL? = nil,
        transcriptionURL: String? = nil,
        transcriptionLength: Float? = nil,
        status: Status = .idle,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        includeInReport: Bool? = nil,
        isLibrary: Bool? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.engine = engine
        self.metadata = metadata
        self.tags = tags
        self.uploadProgress = uploadProgress
        self.errorMessage = errorMessage
        self.remoteId = remoteId
        self.remoteURL = remoteURL
        self.transcriptionURL = transcriptionURL
        self.transcriptionLength = transcriptionLength
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.includeInReport = includeInReport
        self.isLibrary = isLibrary
    }

    // MARK: - Instance methods

    /// Restores the completion publishers for the upload request.
    func restorePublishers() {
        completionPublisher = PassthroughSubject<TruvideoSdkMediaFileUploadResult, Error>()
    }

    // MARK: - Public methods

    /// Cancels the upload request.
    ///
    /// - Throws: An error if the cancellation fails.
    public func cancel() throws {
        try engine.cancel(id: id.uuidString)
    }

    /// Deletes the upload request.
    ///
    /// - Throws: An error if the deletion fails.
    public func delete() throws {
        try engine.delete(id: id.uuidString)
    }

    /// Pauses the upload request.
    ///
    /// - Throws: An error if the pause operation fails.
    public func pause() throws {
        try engine.pause(id: id.uuidString)
    }

    /// Resumes the upload request.
    ///
    /// - Throws: An error if the resume operation fails.
    public func resume() throws {
        try engine.resume(id: id.uuidString)
    }

    /// Retries the upload if it previously failed.
    ///
    /// - Throws: An error if the retry fails.
    public func retry() throws {
        try engine.retry(request: self)
    }

    /// Updates the flag indicating if the upload should be included in the report.
    ///
    /// - Parameter includeInReport: A boolean indicating the new state.
    public func updateIncludeInReport(_ includeInReport: Bool) {
        self.includeInReport = includeInReport
        engine.updateRequest(request: self)
    }

    /// Updates the flag indicating if the upload is a library file.
    ///
    /// - Parameter isLibrary: A boolean indicating the new state.
    public func updateIsLibrary(_ isLibrary: Bool) {
        self.isLibrary = isLibrary
        engine.updateRequest(request: self)
    }

    /// Initiates the upload process for the request.
    ///
    /// - Throws: An error if the upload fails.
    public func upload() throws {
        try engine.upload(request: self)
    }
}

extension TruvideoSdkMediaUploadRequest: Equatable {
    // MARK: - Equatable

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: TruvideoSdkMediaUploadRequest, rhs: TruvideoSdkMediaUploadRequest) -> Bool {
        lhs.id == rhs.id
    }
}
