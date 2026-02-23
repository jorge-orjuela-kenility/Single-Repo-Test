//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

protocol TruvideoSdkMediaUploadEngine {
    /// Cancels an ongoing upload request by its identifier.
    ///
    /// - Parameter id: The unique identifier of the upload request to be canceled.
    /// - Throws: An error if the cancellation fails.
    func cancel(id: String) throws

    /// Deletes a completed or failed upload request by its identifier.
    ///
    /// - Parameter id: The unique identifier of the upload request to be deleted.
    /// - Throws: An error if the deletion fails.
    func delete(id: String) throws

    /// Generates an upload request for a file located at the specified URL with associated metadata and tags.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to upload.
    ///   - metadata: Metadata associated with the media being uploaded.
    ///   - tags: Tags to categorize the media.
    ///   - id: A unique identifier for the upload request.
    ///   - includeInReport: A flag indicating whether to include this upload in a report.
    /// - Returns: A `TruvideoSdkMediaUploadRequest` object configured for the upload.
    func generateUploadRequest(
        forFileAt url: URL,
        metadata: TruvideoSdkMediaMetadata,
        tags: TruvideoSdkMediaTags,
        withId id: UUID,
        includeInReport: Bool?,
        isLibrary: Bool?
    ) -> TruvideoSdkMediaUploadRequest

    /// Retrieves a specific upload request by its identifier.
    ///
    /// - Parameter id: The unique identifier of the upload request.
    /// - Returns: The `TruvideoSdkMediaUploadRequest` object associated with the specified ID.
    /// - Throws: An error if the request cannot be found.
    func getUpload(withId id: String) throws -> TruvideoSdkMediaUploadRequest

    /// Retrieves a list of upload requests filtered by their status.
    ///
    /// - Parameter status: The status of the upload requests to retrieve. If `nil`, all statuses are included.
    /// - Returns: An array of `TruvideoSdkMediaUploadRequest` objects that match the specified status.
    /// - Throws: An error if the retrieval fails.
    func getUploads(byStatus status: TruvideoSdkMediaUploadRequest.Status?) throws -> [TruvideoSdkMediaUploadRequest]

    /// Pauses an ongoing upload request by its identifier.
    ///
    /// - Parameter id: The unique identifier of the upload request to be paused.
    /// - Throws: An error if the pause operation fails.
    func pause(id: String) throws

    /// Resumes a paused upload request by its identifier.
    ///
    /// - Parameter id: The unique identifier of the upload request to be resumed.
    /// - Throws: An error if the resume operation fails.
    func resume(id: String) throws

    /// Retries a failed upload request by its identifier.
    ///
    /// - Parameter request: The `TruvideoSdkMediaUploadRequest` object to be retried.
    /// - Throws: An error if the retry operation fails.
    func retry(request: TruvideoSdkMediaUploadRequest) throws

    /// Updates an existing upload request with new information.
    ///
    /// - Parameter request: The updated `TruvideoSdkMediaUploadRequest` object.
    func updateRequest(request: TruvideoSdkMediaUploadRequest)

    /// Streams a specific upload request by its identifier.
    ///
    /// - Parameter id: The unique identifier of the upload request to stream.
    /// - Returns: A `TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStream` object representing the upload stream.
    /// - Throws: An error if the stream cannot be found.
    func streamUpload(withId id: String) throws -> TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStream

    /// Streams upload requests filtered by their status.
    ///
    /// - Parameter status: The status of the upload requests to stream. If `nil`, all statuses are included.
    /// - Returns: A `TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStreams` object containing the streams of the
    /// upload requests.
    func streamUploads(byStatus status: TruvideoSdkMediaUploadRequest.Status?) -> TruvideoSdkMediaInterface
        .TruvideoSdkMediaFileUploadStreams

    /// Initiates the upload process for the given upload request.
    ///
    /// - Parameter request: The upload request containing necessary details for the upload.
    /// - Throws: Errors related to upload initiation such as authentication failures, invalid states, etc.
    func upload(request: TruvideoSdkMediaUploadRequest) throws
}
