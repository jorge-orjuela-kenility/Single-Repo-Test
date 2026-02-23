//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import Foundation
internal import TruVideoFoundation

/// The store protocol to be implemented by any other storage mechanism
protocol UploadStore {
    typealias OperationResult = Result<Void, Error>
    typealias RetrieveUploadResult = Result<LocalUploadRequest?, Error>
    typealias RetrieveUploadsResult = Result<[LocalUploadRequest], Error>
    typealias StreamUploadsResult = AnyPublisher<[LocalUploadRequest], Never>
    typealias StreamUploadResult = AnyPublisher<LocalUploadRequest, Never>

    /// Persists an upload local record
    /// - Parameter input: The input containing the id and path of the file
    /// - Returns: A result that can be either success or fail
    @discardableResult
    func insertUpload(input: InsertUploadInput) -> OperationResult

    /// Deletes an upload local record
    /// - Parameter id: Upload id
    /// - Returns: A result that can be either success or fail
    @discardableResult
    func deleteUpload(withId id: String) -> OperationResult

    /// Updates an upload local record
    /// - Parameters:
    ///   - id: Upload id
    ///   - data: Data to be modified
    /// - Returns: A result that can be either success or fail
    @discardableResult
    func updateUpload(withId id: String, data: UpdateUploadData) -> OperationResult

    /// Retrieves the local record for an upload
    /// - Parameter id: The id of the upload to be retrieved
    /// - Returns: A result containing the upload or a failure
    @discardableResult
    func retrieveUpload(withId id: String) -> RetrieveUploadResult

    /// Retrieves the uploads matching an specific status
    /// - Parameter status: The status to be searched
    /// - Returns: A result containing the matched uploads or a failure
    @discardableResult
    func retrieveUploads(withStatus status: TruvideoSdkMediaUploadRequest.Status) -> RetrieveUploadsResult

    /// Retrieves all pending uploads
    /// - Returns: A result containing the pending uploads
    @discardableResult
    func retrieveUploads() -> RetrieveUploadsResult

    // Reactive methods

    /// Streams all the pending uploads following a reactive approach
    /// - Returns: The result containing the streamed local records
    @discardableResult
    func streamUploads() -> StreamUploadsResult

    /// Streams an specific upload following a reactive approach
    /// - Parameter id: The id of the upload to be streamed
    /// - Returns: The result of the streamed upload
    @discardableResult
    func streamUploads(byId id: String) throws -> StreamUploadResult

    /// Streams the uploads matching an specific status following a reactive approach
    /// - Parameter status: The status to be matched
    /// - Returns: A result containing the pending uploads
    @discardableResult
    func streamUploads(withStatus status: TruvideoSdkMediaUploadRequest.Status) -> StreamUploadsResult

    /// Method to update the statuses of all the requests to cancelled on the Module first launch
    /// That will help us to clean the status for the uploads that did not complete before the app
    /// termination
    func resetPendingUploadsStatus()
}

/// Store insertion input
struct InsertUploadInput {
    /// The upload id
    let id: String

    /// The file path
    let path: URL

    /// Additional metadata attached to the uploaded file.
    let metadata: Metadata

    /// Additional metadata attached to the uploaded file.
    let tags: [String: String]

    /// Send to OEM
    let includeInReport: Bool?

    /// Send to OEM
    let isLibrary: Bool?

    // MARK: Initializer

    /// Creates a new instance of `InsertUploadInput`
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the upload.
    ///   - path: The file path of the upload as a URL.
    ///   - metadata: Additional metadata associated with the uploaded file.
    ///   - tags: Tags associated with the uploaded file as key-value pairs.
    ///   - includeInReport: Optional flag indicating whether the upload should be included in the OEM report.
    init(
        id: String,
        path: URL,
        metadata: Metadata,
        tags: [String: String],
        includeInReport: Bool? = nil,
        isLibrary: Bool? = nil
    ) {
        self.id = id
        self.path = path
        self.metadata = metadata
        self.tags = tags
        self.includeInReport = includeInReport
        self.isLibrary = isLibrary
    }
}

/// Update data
struct UpdateUploadData {
    // MARK: Properties

    /// External id
    var cloudServiceId: String?

    /// Status
    var status: TruvideoSdkMediaUploadRequest.Status?

    /// Remote Id
    var remoteId: String?

    /// Remote URL
    var remoteURL: URL?

    /// Progress
    var progress: Double?

    /// Retry number
    var retryCount: Int?

    /// Error message
    var errorMessage: String?

    /// The date when this media was created.
    var createdDate: String?

    /// Additional metadata attached to the uploaded file.
    var metadata: Metadata = [:]

    /// Additional tags attached to the uploaded file.
    var tags: [String: String] = [:]

    /// Transcription url
    var transcriptionURL: String?

    /// Transcription length
    var transcriptionLength: Float?

    /// Send to OEM
    var includeInReport: Bool?

    /// Is Library
    var isLibrary: Bool?
}

/// Local uploads DTO
struct LocalUploadRequest: Hashable {
    // MARK: Properties

    /// Upload id
    let id: String

    /// External id
    let cloudServiceId: String?

    /// Creation date milliseconds
    let createdAt: TimeInterval

    /// Error message
    let errorMessage: String?

    /// File path
    let filePath: String

    /// Send to OEM
    let includeInReport: Bool?

    /// Is Library
    let isLibrary: Bool?

    /// Additional metadata attached to the uploaded file.
    let metadata: Metadata?

    /// Progress
    let progress: Double

    /// The date when the media was created on the server.
    let remoteCreationDate: String?

    /// Remote Id
    let remoteId: String?

    /// Remote URL
    let remoteURL: URL?

    /// Retry number
    let retryCount: Int

    /// Status
    let status: TruvideoSdkMediaUploadRequest.Status

    /// Additional tags attached to the uploaded file.
    let tags: [String: String]?

    /// TranscriptionLeng
    let transcriptLength: Float

    /// Transcription url
    let transcriptURL: String?

    /// Update date milliseconds
    let updatedAt: TimeInterval

    var isRunning: Bool {
        status == .processing || status == .paused
    }
}
