//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// Gateway used to send requests to the media endpoint
protocol MediaGateway {
    /// Creates a new media entry on the server.
    ///
    /// This function takes a `MediaData` object and sends it to the server to create a new media entry.
    /// It returns a `MediaDTO` object representing the created media.
    ///
    /// - Parameter media: The `MediaData` object containing the information about the media to be created.
    /// - Returns: A `MediaDTO` object representing the created media.
    /// - Throws: An error if the media creation fails.
    func create(media: MediaData) async throws -> MediaDTO

    /// Retrieves a `MediaDTO` by its identifier.
    ///
    /// The `getById` function asynchronously fetches a `MediaDTO` object based on the provided identifier.
    /// If the media item is found, it returns the `MediaDTO` object; otherwise, it returns `nil`.
    ///
    /// - Parameter id: The identifier of the media item to retrieve.
    /// - Returns: A `MediaDTO` object if the media item is found, otherwise `nil`.
    /// - Throws: An error if something goes wrong during the fetch operation.
    func getById(_ id: String) async throws -> MediaDTO?

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
    ) async throws -> PaginatedResponseDTO<MediaDTO>
}

extension MediaGateway {
    /// Searches for media items based on the specified type and tags.
    ///
    /// This function constructs a search request using the provided media type and tags,
    /// then sends the request using the authenticated `HTTPClient`.
    ///
    /// - Parameters:
    ///   - pageNumber: An integer representing the page number of the search results. Used for pagination.
    ///   - size: An integer specifying the number of items to return per page. Used for pagination.
    ///   - type: The type of media to search for (optional).
    ///   - tags: A dictionary of tags to filter the search results (optional).
    /// - Returns: An array of `SearchMediaResponseDTO` objects matching the search criteria.
    /// - Throws: An error if the search request fails.
    func search(
        pageNumber: Int,
        size: Int,
        type: TruvideoSdkMediaType? = nil,
        tags: [String: String]? = nil
    ) async throws -> PaginatedResponseDTO<MediaDTO> {
        try await search(pageNumber: pageNumber, size: size, isLibrary: false, type: type, tags: tags)
    }
}
