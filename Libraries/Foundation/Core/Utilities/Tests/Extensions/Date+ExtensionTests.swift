//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable import Utilities

struct DateTests {
    // MARK: - Tests

    @Test
    func testThatDateToStringShouldReturnDefaultFormattedStringWhenNoFormatIsProvided() {
        // Given
        let date = makeDate(year: 2026, month: 01, day: 21)

        // When
        let result = date.toString()

        // Then
        #expect(result == "21 January 2026")
    }

    @Test
    func testThatDateToStringShouldReturnCustomFormattedStringWhenFormatIsProvided() {
        // Given
        let date = makeDate(year: 2026, month: 01, day: 21)

        // When
        let result = date.toString("yyyy-MM-dd")

        // Then
        #expect(result == "2026-01-21")
    }

    @Test
    func testThatDateToStringShouldRespectProvidedTimeZoneWhenFormatting() {
        // Given
        let date = makeDate(
            year: 2026,
            month: 1,
            day: 21,
            hour: 11
        )
        let newYork = TimeZone(identifier: "America/New_York")!

        // When
        let result = date.toString("yyyy-MM-dd HH:mm", timeZone: newYork)

        // Then
        #expect(result == "2026-01-21 11:00")
    }

    @Test
    func testThatDateToStringShouldUseUTCWhenTimeZoneIsNil() {
        // Given
        let date = makeDate(year: 2026, month: 01, day: 21, hour: 11)

        // When
        let result = date.toString("HH:mm", timeZone: nil)

        // Then
        #expect(result == "11:00")
    }

    // MARK: - Private method

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        timeZone: TimeZone? = nil
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        return components.day == nil ? Date() : Calendar.current.date(from: components)!
    }
}
