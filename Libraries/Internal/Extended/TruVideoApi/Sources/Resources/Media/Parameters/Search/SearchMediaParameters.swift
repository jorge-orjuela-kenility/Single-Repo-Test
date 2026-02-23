//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import InternalUtilities
internal import Networking

/// Builder-style helper for constructing request parameters for the
/// media search endpoint.
///
/// Usage example:
/// ```swift
/// let parameters = SearchMediaParameters()
///     .searchTerm("brakes")
///     .type(.image)
///     .isActive(true)
///     .isLibrary(true)
///     .sortedBy(.createdDate)
///     .direction(.descending)
///     .page(1)
///     .pageSize(50)
///     .build()
/// ```
public final class SearchMediaParameters {
    // MARK: - Private methods

    private var ids: [String]?
    private var direction = SortDirection.descending
    private var isActive: Bool?
    private var isLibrary: Bool?
    private var page = 1
    private var searchTerm: String?
    private var size = 20
    private var sortBy = SortBy.createdDate
    private var tags: [String: String]?
    private var type: MediaType?

    // MARK: - Private Static Properties

    private static let maxNumberOfItemsPerPage = 100

    // MARK: - Data Types

    /// Represents the field used to sort media search results.
    ///
    /// The selected value is serialized into the `sortBy` query parameter of the
    /// media search endpoint and combined with `SortDirection` to determine the
    /// final ordering of the result set.
    public enum SortBy: String, Codable, Sendable {
        /// Sort results by creation date.
        case createdDate
    }

    /// Container for the final, transport-ready request parameters.
    ///
    /// - `bodyParameters` are encoded in the HTTP body (JSON).
    /// - `queryParameters` are encoded as URL query items.
    public struct RequestParameters {
        /// Parameters that will be sent in the HTTP body (filters).
        public let bodyParameters: [String: any Any & Sendable]

        /// Parameters that will be sent as URL query items
        /// (sorting and pagination).
        public let queryParameters: String
    }

    /// Represents the direction used when sorting search results.
    ///
    /// This value is serialized into the `direction` query parameter and works
    /// together with `SortBy` to determine the final ordering of the media list.
    public enum SortDirection: String, Codable, Sendable {
        /// Ascending sort direction.
        ///
        /// Common scenarios:
        /// - From A to Z when sorting by a textual field.
        /// - From oldest to newest when sorting by dates.
        /// - From the smallest to the largest when sorting by numeric values.
        case ascending = "asc"

        /// Descending sort direction.
        ///
        /// Common scenarios:
        /// - From Z to A when sorting by a textual field.
        /// - From newest to oldest when sorting by dates.
        /// - From the largest to the smallest when sorting by numeric values.
        case descending = "desc"
    }

    // MARK: - Initializer

    /// Creates a new instance with no parameters set.
    public init() {}

    // MARK: - Public methods

    /// Builds the final request parameters, separating body and query values.
    ///
    /// - Returns: A `RequestParameters` value containing:
    ///   - `bodyParameters`: filters encoded for the request body.
    ///   - `queryParameters`: sorting and pagination encoded as query items.
    public func build() -> RequestParameters {
        let size = min(size, Self.maxNumberOfItemsPerPage)
        let parameters: Parameters = [
            "ids": ids?.map { $0.lowercased() } as Any?,
            "active": isActive as Any?,
            "isLibrary": isLibrary as Any?,
            "searchTerm": searchTerm as Any?,
            "tags": tags as Any?,
            "type": type?.rawValue as Any?
        ]
            .compactMapValues(\.self)

        let queryParameters = [
            "sortBy=\(sortBy.rawValue)",
            "direction=\(direction.rawValue)",
            "page=\(page)",
            "size=\(size)"
        ]
            .joined(separator: "&")

        return RequestParameters(bodyParameters: parameters, queryParameters: queryParameters)
    }

    /// Sets the sort direction for the search results.
    ///
    /// - Parameter value: The direction to apply when ordering results.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func direction(_ direction: SortDirection) -> SearchMediaParameters {
        self.direction = direction
        return self
    }

    /// Sets the list of media identifiers to filter the search results.
    ///
    /// When provided, the search will be constrained to the given set of IDs,
    /// typically matching media records by their unique identifiers.
    ///
    /// - Parameter value: An array of media IDs to include in the search.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func ids(_ ids: [String]) -> SearchMediaParameters {
        self.ids = ids
        return self
    }

    /// Sets whether to filter results by active state.
    ///
    /// - Parameter value: `true` to filter active media, `false` for inactive.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func isActive(_ value: Bool) -> SearchMediaParameters {
        isActive = value
        return self
    }

    /// Sets whether to filter results to only include library media.
    ///
    /// - Parameter value: `true` to include only library media.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func isLibrary(_ value: Bool) -> SearchMediaParameters {
        isLibrary = value
        return self
    }

    /// Sets the page number for paginated search results.
    ///
    /// - Parameter value: The 1-based page index.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func page(_ value: Int) -> SearchMediaParameters {
        page = value
        return self
    }

    /// Sets the maximum number of items to return per page.
    ///
    /// Values greater than the internal maximum (`maxNumberOfItemsPerPage`)
    /// will be clamped.
    ///
    /// - Parameter value: Desired page size.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func pageSize(_ value: Int) -> SearchMediaParameters {
        size = value
        return self
    }

    /// Sets the free-text search term used to filter media.
    ///
    /// - Parameter value: The text to search for (e.g. title, description).
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func searchTerm(_ value: String) -> SearchMediaParameters {
        searchTerm = value
        return self
    }

    /// Sets the field used to sort the search results.
    ///
    /// - Parameter value: The field to sort by.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func sortedBy(_ value: SortBy) -> SearchMediaParameters {
        sortBy = value
        return self
    }

    /// Sets the tag filters to apply to the search.
    ///
    /// Tags are represented as key–value pairs, where keys and values
    /// match the backend tagging model.
    ///
    /// - Parameter value: A dictionary of tags to filter by.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func tags(_ value: [String: String]) -> SearchMediaParameters {
        tags = value
        return self
    }

    /// Sets the media type filter to apply to the search.
    ///
    /// - Parameter value: The media type to filter by.
    /// - Returns: The same `SearchMediaParameters` instance to allow chaining.
    @discardableResult
    public func type(_ value: MediaType) -> SearchMediaParameters {
        type = value
        return self
    }
}
