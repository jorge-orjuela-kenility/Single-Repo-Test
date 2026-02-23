//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import InternalUtilities
internal import TruVideoApi
internal import Utilities

/// Media gateway implementation to decouple request from the `shared` module
final class MediaGatewayImplementation: MediaGateway {
    // MARK: Private Properties

    private let mediaResource: MediaResource

    // MARK: Initializer

    /// Creates a new instance of the `MediaGatewayImplementation`.
    ///
    /// - Parameter mediaResource: The `MediaResource` used for making network requests.
    init(mediaResource: MediaResource) {
        self.mediaResource = mediaResource
    }

    // MARK: MediaGateway

    /// Creates a new media entry on the server.
    ///
    /// This function takes a `MediaData` object and sends it to the server to create a new media entry.
    /// It returns a `MediaDTO` object representing the created media.
    ///
    /// - Parameter media: The `MediaData` object containing the information about the media to be created.
    /// - Returns: A `MediaDTO` object representing the created media.
    /// - Throws: An error if the media creation fails.
    func create(media: MediaData) async throws -> MediaDTO {
        let parameters = SaveMediaParameters(
            size: media.size,
            title: media.title,
            type: media.type.apiMediaType,
            url: media.url.absoluteString,
            duration: media.duration,
            includeInReport: media.includeInReport,
            isLibrary: media.isLibrary,
            metadata: media.metadata,
            resolution: MediaResolution(rawValue: media.resolution) ?? .unknown,
            tags: media.tags
        )

        let result = try await mediaResource.create(parameters)

        return makeMediaDTO(from: result)
    }

    /// Retrieves a `MediaDTO` by its identifier.
    ///
    /// The `getById` function asynchronously fetches a `MediaDTO` object based on the provided identifier.
    /// If the media item is found, it returns the `MediaDTO` object; otherwise, it returns `nil`.
    ///
    /// - Parameter id: The identifier of the media item to retrieve.
    /// - Returns: A `MediaDTO` object if the media item is found, otherwise `nil`.
    /// - Throws: An error if something goes wrong during the fetch operation.
    func getById(_ id: String) async throws -> MediaDTO? {
        let parameters = TruVideoApi.SearchMediaParameters().ids([id])

        guard let media = try await mediaResource.search(with: parameters).content.first else {
            return nil
        }

        return makeMediaDTO(from: media)
    }

    /// Searches for media items based on the specified type and tags.
    ///
    /// This function constructs a search request using the provided media type and tags,
    /// then sends the request using the authenticated `HTTPClient`.
    ///
    /// - Parameters:
    ///   - pageNumber: An integer representing the page number of the search results. Used for pagination.
    ///   - size: An integer specifying the number of items to return per page. Used for pagination.
    ///   - isLibrary: A boolean indicating whether the search will filter by library.
    ///   - type: The type of media to search for (optional).
    ///   - tags: A dictionary of tags to filter the search results (optional).
    /// - Returns: An array of `SearchMediaResponseDTO` objects matching the search criteria.
    /// - Throws: An error if the search request fails.
    func search(
        pageNumber: Int,
        size: Int,
        isLibrary: Bool,
        type: TruvideoSdkMediaType?,
        tags: [String: String]?
    ) async throws -> PaginatedResponseDTO<MediaDTO> {
        let parameters = TruVideoApi.SearchMediaParameters()
            .isLibrary(isLibrary)
            .page(pageNumber)
            .pageSize(size)

        if let tags {
            parameters.tags(tags)
        }

        if let type {
            parameters.type(type.apiMediaType)
        }

        let result = try await mediaResource.search(with: parameters)
        let contents = result.content.map { makeMediaDTO(from: $0) }

        return PaginatedResponseDTO<MediaDTO>(
            content: contents,
            empty: result.empty,
            first: result.first,
            last: result.last,
            number: result.number,
            numberOfElements: result.numberOfElements,
            size: result.size,
            totalElements: result.totalElements,
            totalPages: result.totalPages
        )
    }
}

private extension MediaGatewayImplementation {
    func makeMediaDTO(from media: Media) -> MediaDTO {
        MediaDTO(
            id: media.id.uuidString,
            createdDate: media.createdDate.toString("yyyy-MM-dd'T'HH:mm:ssZ"),
            metadata: media.metadata,
            includeInReport: media.includeInReport,
            isLibrary: media.isLibrary,
            previewUrl: media.previewUrl,
            tags: media.tags,
            thumbnailUrl: media.thumbnailUrl,
            transcriptionLength: Float(media.transcriptionLength),
            transcriptionUrl: media.transcriptionUrl,
            type: media.type.sdkMediaType,
            url: media.url
        )
    }
}

private extension MediaType {
    var sdkMediaType: TruvideoSdkMediaType {
        TruvideoSdkMediaType(rawValue: rawValue) ?? .video
    }
}

private extension TruvideoSdkMediaType {
    var apiMediaType: MediaType {
        MediaType(rawValue: rawValue) ?? .unknown
    }
}
