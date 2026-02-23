//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Testing
import UIKit

@testable import Utilities

struct OptionalUnwrapTests {
    // MARK: - Tests

    @Test
    func testThatUnwrapShouldReturnWrappedValueWhenValueIsNotNil() throws {
        // Given
        let value: Int? = 42

        // When
        let result = try value.unwrap(or: NSError(domain: "test", code: 0))

        // Then
        #expect(result == 42)
    }

    @Test
    func testThatUnwrapShouldThrowErrorWhenValueIsNil() {
        // Given
        let value: Int? = nil
        let expectedError = NSError(domain: "unwrap", code: 123)

        // When / Then
        #expect(throws: expectedError) {
            _ = try value.unwrap(or: expectedError)
        }
    }
}
