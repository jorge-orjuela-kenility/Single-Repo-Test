//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

extension Date {
    /// Converts the date to a string representation using the specified format and time zone.
    ///
    /// This method formats the date according to the provided format string and optionally
    /// converts it to a specific time zone. The format string uses Unicode Technical Standard
    /// #35 date format patterns (e.g., "dd MMMM yyyy" for "01 January 2024").
    ///
    /// ## Format String Examples
    ///
    /// - `"dd MMMM yyyy"` → "01 January 2024"
    /// - `"yyyy-MM-dd"` → "2024-01-01"
    /// - `"MMM dd, yyyy HH:mm"` → "Jan 01, 2024 14:30"
    /// - `"EEEE, MMMM dd, yyyy"` → "Monday, January 01, 2024"
    ///
    /// ## Time Zone Handling
    ///
    /// If a time zone is provided, the date is converted to that time zone before formatting.
    /// If `nil` is provided, the formatter uses its default time zone (UTC by default).
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// let date = Date()
    ///
    /// // Default format (dd MMMM yyyy)
    /// let defaultFormat = date.toString()
    /// // "01 January 2024"
    ///
    /// // Custom format
    /// let customFormat = date.toString("yyyy-MM-dd")
    /// // "2024-01-01"
    ///
    /// // With time zone
    /// let timeZone = TimeZone(identifier: "America/New_York")
    /// let withTimeZone = date.toString("yyyy-MM-dd HH:mm", timeZone: timeZone)
    /// // "2024-01-01 09:30" (converted to Eastern Time)
    /// ```
    ///
    /// - Parameters:
    ///   - format: The date format string to use. Defaults to `"dd MMMM yyyy"` if not specified.
    ///     Uses Unicode Technical Standard #35 date format patterns.
    ///   - timeZone: An optional time zone to convert the date to before formatting. If `nil`,
    ///     the formatter's default time zone (UTC) is used.
    /// - Returns: A string representation of the date formatted according to the specified
    ///   format and time zone.
    public func toString(_ format: String = "dd MMMM yyyy", timeZone: TimeZone? = nil) -> String {
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = timeZone

        return dateFormatter.string(from: self)
    }
}

private var dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    return dateFormatter
}()
