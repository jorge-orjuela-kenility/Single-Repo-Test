//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import InternalUtilities
import Testing
import TruVideoFoundation

@testable import TruVideoApi

struct SearchMediaParametersTests {
    // MARK: - Tests

    @Test
    func testThatSearchMediaParametersBuildShouldReturnExpectedQueryAndBodyParametersWhenAllParametersAreProvided() {
        // Given
        let parameters = SearchMediaParameters()
            .ids(["media-id-1", "media-id-2"])
            .searchTerm("brakes")
            .type(.image)
            .isActive(true)
            .isLibrary(true)
            .sortedBy(.createdDate)
            .tags(["foo": "bar"])
            .direction(.ascending)
            .page(2)
            .pageSize(50)

        // When
        let result = parameters.build()

        // Then
        #expect(result.queryParameters == "sortBy=createdDate&direction=asc&page=2&size=50")
        #expect(result.bodyParameters["ids"] as? [String] == ["media-id-1", "media-id-2"])
        #expect(result.bodyParameters["searchTerm"] as? String == "brakes")
        #expect(result.bodyParameters["active"] as? Bool == true)
        #expect(result.bodyParameters["isLibrary"] as? Bool == true)
        #expect(result.bodyParameters["tags"] as? [String: String] == ["foo": "bar"])
        #expect(result.bodyParameters["type"] as? String == MediaType.image.rawValue)
    }
}
