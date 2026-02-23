//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Testing

@testable import Utilities

struct SequenceTests {
    // MARK: - Tests

    @Test
    func testThatRemoveDuplicatesShouldPreserveOriginalOrderWhenDuplicatesExist() {
        // Given
        let input = ["portrait", "landscapeRight", "portrait", "portraitUpsideDown"]

        // When
        let result = input.removeDuplicates()

        // Then
        #expect(result == ["portrait", "landscapeRight", "portraitUpsideDown"])
    }

    @Test
    func testThatRemoveDuplicatesShouldReturnSameSequenceWhenAllElementsAreUnique() {
        // Given
        let input = [1, 2, 3, 4]

        // When
        let result = input.removeDuplicates()

        // Then
        #expect(result == input)
    }

    @Test
    func testThatRemoveDuplicatesShouldReturnEmptySequenceWhenInputIsEmpty() {
        // Given
        let input: [Int] = []

        // When
        let result = input.removeDuplicates()

        // Then
        #expect(result.isEmpty)
    }

    @Test
    func testThatRemoveDuplicatesShouldWorkWithCustomHashableTypeWhenDuplicatesExist() {
        // Given
        let input = [
            ItemMock(id: 1),
            ItemMock(id: 2),
            ItemMock(id: 1)
        ]

        // When
        let result = input.removeDuplicates()

        // Then
        #expect(result.map(\.id) == [1, 2])
    }
}

struct ItemMock: Hashable {
    let id: Int
}
