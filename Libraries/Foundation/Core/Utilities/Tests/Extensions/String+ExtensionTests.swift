//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable import Utilities

struct StringTests {
    // MARK: - Tests

    @Test
    func testThatStringToDateShouldReturnDateWhenUsingDefaultFormat() {
        // Given
        let dateString = "2025-01-20T15:30:00+0000"

        // When
        let date = dateString.toDate()

        // Then
        #expect(date != nil)
    }

    @Test
    func testThatStringToDateShouldReturnDateWhenUsingCustomFormat() {
        // Given
        let dateString = "20-01-2025"
        let format = "dd-MM-yyyy"

        // When
        let date = dateString.toDate(format)

        // Then
        #expect(date != nil)
    }

    @Test
    func testThatStringToDateShouldReturnNilWhenStringIsInvalid() {
        // Given
        let invalidDateString = "date-invalid"

        // When
        let date = invalidDateString.toDate()

        // Then
        #expect(date == nil)
    }

    @Test
    func testThatStringToDateShouldUseUTCTimeZoneWhenParsingDate() {
        // Given
        let dateString = "2025-01-20T00:00:00+0000"

        // When
        let date = dateString.toDate()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date!)

        // Then
        #expect(components.year == 2025)
        #expect(components.month == 1)
        #expect(components.day == 20)
        #expect(components.hour == 0)
    }
}
