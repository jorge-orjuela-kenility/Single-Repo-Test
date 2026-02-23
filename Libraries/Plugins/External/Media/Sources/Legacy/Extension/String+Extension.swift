//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    return dateFormatter
}()

extension String {
    /// Converts a string to a `Date` object based on the specified date format.
    ///
    /// - Parameter format: A `String` representing the desired date format. The default value is `"MM-dd-yy"`.
    /// - Returns: A `Date` object if the string can be successfully parsed with the given format; otherwise, `nil`.
    ///
    /// This function attempts to parse the string (represented by `self`) into a `Date` object using the provided date
    /// format.
    /// If the format is not specified, it defaults to `"MM-dd-yy"`. The function makes a copy of the date formatter to
    /// ensure
    /// thread safety and to prevent side effects on the original date formatter.
    func toDate(_ format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Date? {
        guard let dateFormatter = dateFormatter.copy() as? DateFormatter else { return nil }

        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
}
