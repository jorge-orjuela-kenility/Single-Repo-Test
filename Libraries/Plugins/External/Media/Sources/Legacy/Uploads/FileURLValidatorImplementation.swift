//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

final class FileURLValidatorImplementation: FileURLValidator {
    // MARK: Instance Methods

    /// Method used to validate if the file URL either exists or is not a directory
    /// - Parameter url: the file url
    /// - Returns: A boolean that says if the provided url is valid or not
    @discardableResult
    func isValid(url: URL) throws -> Bool {
        guard !url.hasDirectoryPath else {
            throw TruvideoSdkMediaError.invalidFile(url: url)
        }

        guard FileManager.default.fileExists(atPath: url.relativePath) else {
            throw TruvideoSdkMediaError.fileNotFound(url: url)
        }

        return true
    }
}
