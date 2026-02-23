//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreData
import Foundation
internal import TruVideoApi
internal import TruVideoMediaUpload

/// `TruvideoSdkMediaInterface` implementation to expose public utilities
final class TruvideoSdkMediaInterfaceImp: TruvideoSdkMediaInterface {
    // MARK: - Private Properties

    private let container: StreamContainer
    private var credentialProvider: AWSCredentialProvider
    private var mediaGateway: MediaGateway
    private let uploadEngine: TruvideoSdkMediaUploadEngine

    // MARK: - Initializer

    /// Initializes a new instance of `TruvideoSdkMediaInterfaceImp`.
    ///
    /// - Parameters:
    ///   - container: .
    ///   - credentialProvider: The provider for AWS credentials, used for authentication with AWS services.
    ///   - gateway: An optional `MediaGateway` for handling media operations.
    ///   - store: An optional `UploadStore` that is used for managing the upload data.
    init(
        container: StreamContainer = StreamContainer.shared,
        credentialProvider: AWSCredentialProvider = AWSS3CredentialProvider(),
        store: UploadStore? = nil,
        gateway: MediaGateway? = nil
    ) {
        self.container = container
        self.credentialProvider = credentialProvider
        self.mediaGateway = gateway ?? MediaGatewayImplementation(mediaResource: MediaResourceImpl())

        let resolvedStore = store ?? CoreDataUploadStore()
        let requestMapper = RequestMapper(store: resolvedStore)
        let currentMediaGateway = self.mediaGateway

        resolvedStore.resetPendingUploadsStatus()

        self.uploadEngine = TruvideoSdkMediaUploadEngineImp<AWSS3FileUploaderTask>(
            fileURLValidator: FileURLValidatorImplementation(),
            credentialProvider: credentialProvider,
            store: resolvedStore,
            requestMapper: requestMapper
        ) { url, id, metadata, tags, includeInReport, isLibrary in
            .init(
                id: id,
                fileURL: url,
                metadata: metadata,
                tags: tags,
                includeInReport: includeInReport,
                duration: url.getDuration(),
                isLibrary: isLibrary,
                credentialProvider: credentialProvider,
                mediaGateway: currentMediaGateway,
                s3ServicesProvider: AWSS3ServicesProviderImplementation(credentialProvider: credentialProvider),
                store: resolvedStore
            )
        }
    }

    // MARK: - Instance Methods

    /// Creates a new stream-based upload request for the provided file.
    ///
    /// This method creates and persists a new stream entry using the media upload container
    /// and returns a request wrapper that exposes lifecycle controls and completion events.
    ///
    /// - Parameter fileURL: The local URL of the media file to upload.
    /// - Returns: A `TruvideoSdkMediaStreamRequest` ready to be configured and started.
    /// - Throws: An error if the request cannot be created or persisted.
    func createUploadRequest(from fileURL: URL) async throws -> TruvideoSdkMediaStreamRequest {
        do {
            let rawValue = fileURL.pathExtension.uppercased()
            let fileType = FileType(rawValue: rawValue) ?? .unknown
            let stream = try await container.newStream(from: fileURL, of: fileType)

            return TruvideoSdkMediaStreamRequest(stream: stream)
        } catch {
            throw TruvideoSdkMediaError.createStreamRequestFailed
        }
    }

    // swiftlint:disable identifier_name

    /// Builds a file upload request with the given parameters.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to be uploaded.
    ///   - metadata: The metadata associated with the file.
    ///   - tags: The tags related to the file.
    ///   - includeInReport: Whether to include this file in a report.
    /// - Returns: A `FileUploadRequestBuilder` instance used to construct the upload request.
    func FileUploadRequestBuilder(
        fileURL: URL,
        metadata: TruvideoSdkMediaMetadata,
        tags: TruvideoSdkMediaTags,
        includeInReport: Bool?,
        isLibrary: Bool?
    ) -> FileUploadRequestBuilder {
        .init(
            engine: uploadEngine,
            fileURL: fileURL,
            includeInReport: includeInReport,
            isLibrary: isLibrary,
            metadata: metadata,
            tags: tags
        )
    }

    /// Retrieves stream upload requests stored locally.
    ///
    /// Use this API to query the SDK's stream upload queue. Results reflect the last-known
    /// state persisted on device and do not trigger any network request.
    ///
    /// - Returns: An array of stream upload requests.
    /// - Throws: An error if the underlying store cannot be accessed or the requests cannot be reconstructed.
    func getAllUploadRequests() async throws -> [TruvideoSdkMediaStreamRequest] {
        do {
            let streams = try await container.retrieveStreams()

            return streams.map { TruvideoSdkMediaStreamRequest(stream: $0) }
        } catch {
            throw TruvideoSdkMediaError.retrieveStreamRequestsFailed
        }
    }

    /// Fetches a media item by its ID.
    ///
    /// - Parameter id: The ID of the media item.
    /// - Returns: A `TruvideoSDKMedia` instance if found, or `nil` if not.
    /// - Throws: An error if the media item cannot be fetched.
    func getById(_ id: String) async throws -> TruvideoSDKMedia? {
        try await self.mediaGateway.getById(id).map(TruvideoSDKMedia.from)
    }

    /// Retrieves a specific file upload request by its ID.
    ///
    /// - Parameter id: The ID of the file upload request.
    /// - Returns: A `TruvideoSdkMediaUploadRequest` instance.
    /// - Throws: An error if the file upload request cannot be fetched.
    func getFileUploadRequest(withId id: String) throws -> TruvideoSdkMediaUploadRequest {
        try uploadEngine.getUpload(withId: id)
    }

    /// Retrieves all file upload requests filtered by their status.
    ///
    /// - Parameter status: The status to filter uploads by. If `nil`, all uploads are returned.
    /// - Returns: An array of `TruvideoSdkMediaUploadRequest` instances.
    /// - Throws: An error if the upload requests cannot be fetched.
    func getFileUploadRequests(
        byStatus status: TruvideoSdkMediaUploadRequest.Status? = nil
    ) throws -> [TruvideoSdkMediaUploadRequest] {
        try uploadEngine.getUploads(byStatus: status)
    }

    /// Retrieves a single stream upload request by identifier.
    ///
    /// The returned request provides control over the stream lifecycle (pause, resume, cancel)
    /// and access to metadata, tags, and the local `fileUrl`.
    ///
    /// - Parameter id: The request identifier.
    /// - Returns: The matching stream upload request.
    /// - Throws: An error if the request cannot be found or loaded from the local store.
    func getUploadRequestById(_ id: String) async throws -> TruvideoSdkMediaStreamRequest {
        do {
            let streams = try await container.retrieveStreams { $0.id.uuidString == id }

            guard let stream = streams.first else {
                throw TruvideoSdkMediaError.retrieveStreamRequestFailed
            }

            return TruvideoSdkMediaStreamRequest(stream: stream)
        } catch {
            throw TruvideoSdkMediaError.retrieveStreamRequestFailed
        }
    }

    /// Searches for media items based on type, tags, and pagination parameters.
    ///
    /// - Parameters:
    ///   - type: The type of media to search for (e.g., video, image).
    ///   - tags: The tags to filter media by.
    ///   - isLibrary: A boolean indicating whether the search will filter by library.
    ///   - pageNumber: The page number for pagination.
    ///   - size: The number of items per page.
    /// - Returns: A paginated response containing the search results.
    /// - Throws: An error if the search operation fails.
    func search(
        type: TruvideoSdkMediaType?,
        tags: TruvideoSdkMediaTags?,
        isLibrary: Bool,
        pageNumber: Int,
        size: Int
    ) async throws -> TruvideoSdkMediaPaginatedResponse<TruvideoSDKMedia> {
        let response = try await self.mediaGateway.search(
            pageNumber: pageNumber,
            size: size,
            isLibrary: isLibrary,
            type: type,
            tags: tags?.dictionary
        )

        return try .init(
            content: response.content.map(TruvideoSDKMedia.from),
            empty: response.empty,
            first: response.first,
            last: response.last,
            number: response.number,
            numberOfElements: response.numberOfElements,
            size: response.size,
            totalElements: response.totalElements,
            totalPages: response.totalPages
        )
    }

    /// Streams updates for all stream upload requests.
    ///
    /// The returned `AsyncStream` emits whenever the SDK observes changes in matching requests
    /// (creation, status updates, completion, or deletion). Iterate it inside a `Task` and cancel
    /// the task to stop receiving updates.
    ///
    /// - Returns: An async stream that emits the current list of matching requests over time.
    /// - Throws: An error if the stream cannot be established (for example, due to store access).
    func streamAllUploadRequests() -> AsyncStream<[TruvideoSdkMediaStreamRequest]> {
        AsyncStream { continuation in
            let task = Task {
                for await streams in container.streams() {
                    let requests = streams.map { TruvideoSdkMediaStreamRequest(stream: $0) }
                    continuation.yield(requests)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Streams a specific file upload request by its ID.
    ///
    /// - Parameter id: The ID of the file upload request to stream.
    /// - Returns: A stream of the file upload request.
    /// - Throws: An error if the upload request cannot be streamed.
    func streamFileUploadRequest(
        withId id: String
    ) throws -> TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStream {
        try uploadEngine.streamUpload(withId: id)
    }

    /// Streams file upload requests, optionally filtered by status.
    ///
    /// - Parameter status: The status to filter uploads by. If `nil`, all uploads are streamed.
    /// - Returns: A stream of file upload requests.
    func streamFileUploadRequests(byStatus status: TruvideoSdkMediaUploadRequest
        .Status? = nil
    ) -> TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStreams {
        uploadEngine.streamUploads(byStatus: status)
    }

    /// Streams updates for a single stream upload request.
    ///
    /// This is useful for UI that needs to track one upload's lifecycle. The stream emits as the
    /// request transitions between statuses or updates its persisted data.
    ///
    /// - Parameter id: The request identifier.
    /// - Returns: An async stream that emits the request as it changes over time.
    /// - Throws: An error if the request does not exist or updates cannot be observed.
    func streamUploadRequestById(_ id: String) -> AsyncStream<TruvideoSdkMediaStreamRequest> {
        AsyncStream { continuation in
            let task = Task {
                let asyncSequence = container.streams(where: { $0.id.uuidString == id })

                for await streams in asyncSequence {
                    if let stream = streams.first {
                        continuation.yield(TruvideoSdkMediaStreamRequest(stream: stream))
                    }
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
