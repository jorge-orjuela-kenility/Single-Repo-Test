//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// A structure representing a response for a media search.
public struct PaginatedResponse<Content: Decodable>: Decodable {
    /// An array of Content Type representing the items in the response.
    public let content: [Content]

    /// A boolean indicating whether the response is empty.
    public let empty: Bool

    /// A boolean indicating whether the current page is the first page.
    public let first: Bool

    /// A boolean indicating whether the current page is the last page.
    public let last: Bool

    /// The current page number in the response.
    public let number: Int

    /// The number of elements in the current page of the response.
    public let numberOfElements: Int

    /// The size of the current page in the response.
    public let size: Int

    /// The total number of elements in the response.
    public let totalElements: Int

    /// The total number of pages in the response.
    public let totalPages: Int
}
