//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import Foundation

// swiftlint:disable identifier_name
/// Exposed constant used to access the `TruvideoSdkMedia` module utilities
public let TruvideoSdkMedia: TruvideoSdkMediaInterface = TruvideoSdkMediaInterfaceImp()

/// Interface that provides the utilities for external usage
public protocol TruvideoSdkMediaInterface {
    /// A Combine publisher that emits arrays of file upload requests.
    typealias TruvideoSdkMediaFileUploadStreams = AnyPublisher<[TruvideoSdkMediaUploadRequest], Never>

    /// A Combine publisher that emits individual file upload request updates.
    typealias TruvideoSdkMediaFileUploadStream = AnyPublisher<TruvideoSdkMediaUploadRequest, Never>

    /// Creates a new stream-based upload request for the provided file.
    ///
    /// This method persists a new stream record locally and returns a request object that
    /// can be used to control the upload lifecycle (start, pause, resume, cancel) and
    /// observe completion events. The request is backed by the SDK's stream upload pipeline.
    ///
    /// - Parameter fileURL: The local URL of the media file to upload.
    /// - Returns: A `TruvideoSdkMediaStreamRequest` ready to be configured and started.
    /// - Throws: An error if the stream request cannot be created or persisted.
    func createUploadRequest(from fileURL: URL) async throws -> TruvideoSdkMediaStreamRequest

    /// Creates and returns a `FileUploadRequestBuilder` configured for uploading a file.
    ///
    /// This builder encapsulates the information required to construct a file upload request,
    /// including the local file location, metadata, and tags. Optional flags can be provided
    /// to control report inclusion and library classification.
    ///
    /// - Parameters:
    ///   - fileURL: The local URL of the file to upload.
    ///   - metadata: Structured metadata to associate with the uploaded file.
    ///   - tags: Additional tag values (key–value pairs) to attach to the uploaded file.
    ///   - includeInReport: Whether this upload should be included in generated reports. If `nil`,
    ///     the SDK will use its default behavior.
    ///   - isLibrary: Whether this upload belongs to the library. If `nil`, the SDK will use its
    ///     default behavior.
    /// - Returns: A `FileUploadRequestBuilder` instance configured with the provided values.
    func FileUploadRequestBuilder(
        fileURL: URL,
        metadata: TruvideoSdkMediaMetadata,
        tags: TruvideoSdkMediaTags,
        includeInReport: Bool?,
        isLibrary: Bool?
    ) -> FileUploadRequestBuilder

    /// Retrieves stream upload requests stored locally.
    ///
    /// Use this API to query the SDK's stream upload queue. Results reflect the last-known
    /// state persisted on device and do not trigger any network request.
    ///
    /// - Returns: An array of stream upload requests.
    /// - Throws: An error if the underlying store cannot be accessed or the requests cannot be reconstructed.
    func getAllUploadRequests() async throws -> [TruvideoSdkMediaStreamRequest]

    /// Retrieves a media item from the server by its identifier.
    ///
    /// This asynchronous operation requests the media resource associated with the provided `id`.
    /// If the request succeeds but the resource does not exist (or is not accessible), the method
    /// may return `nil`.
    ///
    /// - Parameter id: The unique identifier of the media item to retrieve.
    /// - Returns: The `TruvideoSDKMedia` associated with `id`, or `nil` if no matching media is found.
    /// - Throws: An error if the request fails due to networking, server, decoding, or authorization issues.
    func getById(_ id: String) async throws -> TruvideoSDKMedia?

    /// Retrieves the request for the specified id
    ///
    /// - Parameter id: Request id
    /// - Returns: The matched request
    func getFileUploadRequest(withId id: String) throws -> TruvideoSdkMediaUploadRequest

    /// Retrieves file upload requests, optionally filtered by status.
    ///
    /// Use `status` to return only requests in a specific state. Pass `nil` to retrieve
    /// all stored requests regardless of status.
    ///
    /// - Parameter status: The status used to filter requests, or `nil` to fetch all requests.
    /// - Returns: An array of `TruvideoSdkMediaUploadRequest` matching the provided status filter.
    /// - Throws: An error if the requests cannot be retrieved (for example, due to persistence or decoding failures).
    func getFileUploadRequests(
        byStatus status: TruvideoSdkMediaUploadRequest.Status?
    ) throws -> [TruvideoSdkMediaUploadRequest]

    /// Retrieves a single stream upload request by identifier.
    ///
    /// The returned request provides control over the stream lifecycle (pause, resume, cancel)
    /// and access to metadata, tags, and the local `fileUrl`.
    ///
    /// - Parameter id: The request identifier.
    /// - Returns: The matching stream upload request.
    /// - Throws: An error if the request cannot be found or loaded from the local store.
    func getUploadRequestById(_ id: String) async throws -> TruvideoSdkMediaStreamRequest

    /// Searches for media upload requests based on the specified type and tags.
    ///
    /// This function performs an asynchronous search for media upload requests that match the provided type and tags.
    /// The search results are returned as an array of `TruvideoSdkMediaUploadRequest` objects.
    ///
    /// - Parameters:
    ///   - type: A `MediaType` representing the type of media to search for.
    ///   - tags: A dictionary of tags to filter the search results. The keys and values in the dictionary are `String`.
    ///   - isLibrary: A boolean indicating whether the search will filter by library.
    ///   - pageNumber: An integer representing the page number of the search results. Used for pagination.
    ///   - size: An integer specifying the number of items to return per page. Used for pagination.
    /// - Returns: An array of `TruvideoSdkMediaUploadRequest` objects that match the search criteria.
    /// - Throws: An error if the search fails.
    func search(
        type: TruvideoSdkMediaType?,
        tags: TruvideoSdkMediaTags?,
        isLibrary: Bool,
        pageNumber: Int,
        size: Int
    ) async throws -> TruvideoSdkMediaPaginatedResponse<TruvideoSDKMedia>

    /// Streams updates for all stream upload requests.
    ///
    /// The returned `AsyncStream` emits whenever the SDK observes changes in matching requests
    /// (creation, status updates, completion, or deletion). Iterate it inside a `Task` and cancel
    /// the task to stop receiving updates.
    ///
    /// - Returns: An async stream that emits the current list of matching requests over time.
    /// - Throws: An error if the stream cannot be established (for example, due to store access).
    func streamAllUploadRequests() -> AsyncStream<[TruvideoSdkMediaStreamRequest]>

    /// Streams the list of request with the provided status
    ///
    /// - Parameter status: Request status
    /// - Returns: A publisher with the list of requests
    func streamFileUploadRequests(
        byStatus status: TruvideoSdkMediaUploadRequest.Status?
    ) -> TruvideoSdkMediaFileUploadStreams

    /// Streams the request with the provided id
    ///
    /// - Parameter id: Request id
    /// - Returns: A publisher with the request
    func streamFileUploadRequest(withId id: String) throws -> TruvideoSdkMediaFileUploadStream

    /// Streams updates for a single stream upload request.
    ///
    /// This is useful for UI that needs to track one upload's lifecycle. The stream emits as the
    /// request transitions between statuses or updates its persisted data.
    ///
    /// - Parameter id: The request identifier.
    /// - Returns: An async stream that emits the request as it changes over time.
    /// - Throws: An error if the request does not exist or updates cannot be observed.
    func streamUploadRequestById(_ id: String) -> AsyncStream<TruvideoSdkMediaStreamRequest>
}

extension TruvideoSdkMediaInterface {
    /// Creates and returns a `FileUploadRequestBuilder` configured for uploading a file.
    ///
    /// This builder encapsulates the information required to construct a file upload request,
    /// including the local file location, metadata, and tags. Optional flags can be provided
    /// to control report inclusion and library classification.
    ///
    /// - Parameters:
    ///   - fileURL: The local URL of the file to upload.
    ///   - metadata: Structured metadata to associate with the uploaded file.
    ///   - tags: Additional tag values (key–value pairs) to attach to the uploaded file.
    ///   - includeInReport: Whether this upload should be included in generated reports. If `nil`,
    ///     the SDK will use its default behavior.
    ///   - isLibrary: Whether this upload belongs to the library. If `nil`, the SDK will use its
    ///     default behavior.
    /// - Returns: A `FileUploadRequestBuilder` instance configured with the provided values.
    public func FileUploadRequestBuilder(
        fileURL: URL,
        metadata: TruvideoSdkMediaMetadata = TruvideoSdkMediaMetadata.builder().build(),
        tags: TruvideoSdkMediaTags = TruvideoSdkMediaTags.builder().build(),
        includeInReport: Bool? = nil,
        isLibrary: Bool? = nil
    ) -> FileUploadRequestBuilder {
        FileUploadRequestBuilder(
            fileURL: fileURL,
            metadata: metadata,
            tags: tags,
            includeInReport: includeInReport,
            isLibrary: isLibrary
        )
    }

    /// Retrieves stream upload requests stored locally.
    ///
    /// - Returns: An array of stream upload requests.
    /// - Throws: An error if the underlying store cannot be accessed or the requests cannot be reconstructed.
    public func getAllUploadRequests() async throws -> [TruvideoSdkMediaStreamRequest] {
        try await getAllUploadRequests()
    }

    /// Retrieves file upload requests, optionally filtered by status.
    ///
    /// Use `status` to return only requests in a specific state. Pass `nil` to retrieve
    /// all stored requests regardless of status.
    ///
    /// - Parameter status: The status used to filter requests, or `nil` to fetch all requests.
    /// - Returns: An array of `TruvideoSdkMediaUploadRequest` matching the provided status filter.
    /// - Throws: An error if the requests cannot be retrieved (for example, due to persistence or decoding failures).
    public func getFileUploadRequests(
        byStatus status: TruvideoSdkMediaUploadRequest.Status? = nil
    ) throws -> [TruvideoSdkMediaUploadRequest] {
        try getFileUploadRequests(byStatus: status)
    }

    /// Searches for media upload requests based on type and tags, with pagination support.
    ///
    /// - Parameters:
    ///   - type: (Optional) The type of media to search for (e.g., video, image). Defaults to `nil`.
    ///   - tags: (Optional) Tags to filter search results. Defaults to `nil`.
    ///   - pageNumber: The page number for pagination (defaults to 0).
    ///   - size: The number of results per page (defaults to 20).
    /// - Returns: A paginated response containing the search results.
    /// - Throws: An error if the search operation fails.
    public func search(
        type: TruvideoSdkMediaType? = nil,
        tags: TruvideoSdkMediaTags? = nil,
        isLibrary: Bool = false,
        pageNumber: Int = 0,
        size: Int = 20
    ) async throws -> TruvideoSdkMediaPaginatedResponse<TruvideoSDKMedia> {
        try await search(type: type, tags: tags, isLibrary: isLibrary, pageNumber: pageNumber, size: size)
    }

    /// Streams updates for all stream upload requests.
    ///
    /// - Returns: An async stream that emits the current list of matching requests over time.
    /// - Throws: An error if the stream cannot be established (for example, due to store access).
    public func streamAllUploadRequests() throws -> AsyncStream<[TruvideoSdkMediaStreamRequest]> {
        streamAllUploadRequests()
    }

    /// Streams updates for all stream upload requests.
    ///
    /// The returned `AsyncStream` emits whenever the SDK observes changes in matching requests
    /// (creation, status updates, completion, or deletion). Iterate it inside a `Task` and cancel
    /// the task to stop receiving updates.
    ///
    /// - Returns: An async stream that emits the current list of matching requests over time.
    /// - Throws: An error if the stream cannot be established (for example, due to store access).
    public func streamFileUploadRequests(
        byStatus status: TruvideoSdkMediaUploadRequest.Status? = nil
    ) -> TruvideoSdkMediaFileUploadStreams {
        streamFileUploadRequests(byStatus: status)
    }
}
