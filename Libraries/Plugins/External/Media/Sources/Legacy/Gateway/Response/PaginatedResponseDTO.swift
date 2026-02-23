//
// Created by TruVideo on 18/06/24.
// Copyright © 2024 Truvideo. All rights reserved.
//

import Foundation

/// A structure representing a response for a media search.
struct PaginatedResponseDTO<Content: Decodable>: Decodable {
    // MARK: Properties

    /// An array of Content Type representing the items in the response.
    let content: [Content]

    /// A boolean indicating whether the response is empty.
    let empty: Bool

    /// A boolean indicating whether the current page is the first page.
    let first: Bool

    /// A boolean indicating whether the current page is the last page.
    let last: Bool

    /// The current page number in the response.
    let number: Int

    /// The number of elements in the current page of the response.
    let numberOfElements: Int

    /// The size of the current page in the response.
    let size: Int

    /// The total number of elements in the response.
    let totalElements: Int

    /// The total number of pages in the response.
    let totalPages: Int

    // MARK: Initializer

    /// Creates a new instance of the `SearchMediaResponseDTO`.
    ///
    /// - Parameters:
    ///   - content: An array of Content Type representing the items in the response.
    ///   - empty: A boolean indicating whether the response is empty.
    ///   - first: A boolean indicating whether the current page is the first page.
    ///   - last: A boolean indicating whether the current page is the last page.
    ///   - number: The current page number in the response.
    ///   - numberOfElements: The number of elements in the current page of the response.
    ///   - size: The size of the current page in the response.
    ///   - totalElements: The total number of elements in the response.
    ///   - totalPages: The total number of pages in the response.
    init(
        content: [Content],
        empty: Bool,
        first: Bool,
        last: Bool,
        number: Int,
        numberOfElements: Int,
        size: Int,
        totalElements: Int,
        totalPages: Int
    ) {
        self.content = content
        self.empty = empty
        self.first = first
        self.last = last
        self.number = number
        self.numberOfElements = numberOfElements
        self.size = size
        self.totalElements = totalElements
        self.totalPages = totalPages
    }
}
