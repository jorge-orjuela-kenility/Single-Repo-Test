//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

@testable import TruVideoApi

public extension PaginatedResponse where Content: Decodable {
    /// Creates a mock `PaginatedResponse` instance for testing purposes.
    ///
    /// This helper method simplifies the creation of paginated API responses in unit tests
    /// by allowing callers to define the response content and optionally override pagination
    /// metadata such as page number, page size, total elements, and total pages.
    ///
    /// Any pagination parameters not explicitly provided are automatically inferred from
    /// the `content` array to produce a consistent and valid mock response.
    ///
    /// - Parameters:
    ///   - content: The array of decoded elements representing the current page's content.
    ///   - number: The current page index (zero-based). Defaults to `0`.
    ///   - numberOfElements: The number of elements in the current page. Defaults to `content.count`.
    ///   - size: The size of the page. Defaults to `20`.
    ///   - totalElements: The total number of elements across all pages. Defaults to `content.count`.
    ///   - totalPages: The total number of available pages. Defaults to `1`.
    ///
    /// - Returns: A fully constructed `PaginatedResponse<Content>` instance suitable for testing.
    static func mock(
        content: [Content],
        number: Int = 0,
        numberOfElements: Int? = nil,
        size: Int = 20,
        totalElements: Int? = nil,
        totalPages: Int? = nil
    ) -> PaginatedResponse<Content> {
        let resolvedNumberOfElements = numberOfElements ?? content.count
        let resolvedTotalElements = totalElements ?? content.count
        let resolvedTotalPages = totalPages ?? 1

        return PaginatedResponse(
            content: content,
            empty: content.isEmpty,
            first: number == 0,
            last: resolvedTotalPages <= 1 || number >= (resolvedTotalPages - 1),
            number: number,
            numberOfElements: resolvedNumberOfElements,
            size: size,
            totalElements: resolvedTotalElements,
            totalPages: resolvedTotalPages
        )
    }
}
