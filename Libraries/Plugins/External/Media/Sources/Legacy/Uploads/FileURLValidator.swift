//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// Abstraction used to validate the file url
protocol FileURLValidator {
    /// Method used to validate the file URL
    /// - Parameter url: the file url
    /// - Returns: A boolean indicating if the provided url contains a valid file
    @discardableResult
    func isValid(url: URL) throws -> Bool
}
