//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing
import TruVideoFoundation

@testable import Utilities

struct MetadataTests {
    // MARK: - Tests

    @Test
    func testThatMetadataPrettifyShouldReturnNilWhenMetadataIsEmpty() {
        // Given
        let metadata: Metadata = [:]

        // When
        let result = metadata.prettify()

        // Then
        #expect(result == nil)
    }

    @Test
    func testThatMetadataPrettifyShouldReturnJSONWhenMetadataIsNotEmpty() throws {
        // Given
        let metadata: Metadata = [
            "string": "value",
            "int": 1,
            "bool": true
        ]

        // When
        let json = metadata.prettify()

        // Then
        #expect(json != nil)

        let decoded = try JSONSerialization.jsonObject(with: json!.data(using: .utf8)!, options: []) as? [String: Any]
        #expect(decoded?["string"] as? String == "value")
        #expect(decoded?["int"] as? Int == 1)
        #expect(decoded?["bool"] as? Bool == true)
    }

    @Test
    func testThatMetadataValueShouldPreserveValueWhenEncodedAndDecoded() throws {
        // Given
        let original: MetadataValue = [
            "string": "value",
            "int": 1,
            "double": 1.5,
            "bool": true,
            "array": [1, "two", false],
            "dict": [
                "nested": "yes"
            ]
        ]

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataValue.self, from: data)

        // Then
        #expect(decoded == original)
    }

    @Test
    func testThatMetadataValueShouldNotBeEqualWhenUnderlyingTypesDiffer() {
        // Given, When
        let intValue: MetadataValue = 1
        let doubleValue: MetadataValue = 1.0

        // Then
        #expect(intValue != doubleValue)
    }

    @Test
    func testThatMetadataValueShouldSupportDictionaryLiteralInitialization() {
        // Given, When
        let value: MetadataValue = [
            "key": "value",
            "flag": true
        ]

        // Then
        #expect(
            value == .dictionary([
                "key": .string("value"),
                "flag": .bool(true)
            ])
        )
    }

    @Test
    func testThatMetadataValueDescriptionShouldContainUnderlyingValuesForDictionary() {
        // Given
        let value: MetadataValue = [
            "key": "value",
            "count": 2
        ]

        // When
        let description = value.description

        // Then
        #expect(description.contains("value"))
        #expect(description.contains("2"))
    }

    @Test
    func testThatMetadataValueDescriptionShouldReturnBoolStringWhenValueIsBool() {
        // Given
        let value: MetadataValue = true

        // When
        let description = value.description

        // Then
        #expect(description == "true")
    }

    @Test
    func testThatMetadataValueDescriptionShouldReturnDoubleStringWhenValueIsDouble() {
        // Given
        let value: MetadataValue = 3.14

        // When
        let description = value.description

        // Then
        #expect(description == "3.14")
    }

    @Test
    func testThatMetadataValueDescriptionShouldReturnFormattedArrayWhenValueIsArray() {
        // Given
        let value: MetadataValue = [
            MetadataValue.int(1),
            MetadataValue.string("abc"),
            MetadataValue.bool(false)
        ]

        // When
        let description = value.description

        // Then
        #expect(description == "[\"1\", \"abc\", \"false\"]")
    }
}
