//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

extension MetadataValue {
    /// Returns the raw value represented by the `MetadataValue`,
    /// recursively unwrapping arrays and dictionaries.
    var rawValue: Any? {
        switch self {
        case let .array(array):
            array.map(\.rawValue)

        case let .bool(bool):
            bool

        case let .dictionary(dictionary):
            dictionary.reduce(into: [String: Any]()) { result, entry in
                result[entry.key] = entry.value.rawValue
            }

        case let .double(double):
            double

        case let .int(int):
            int

        case let .string(string):
            string
        }
    }
}
