//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

extension URL {
    /// The directory URL for storing stream-related files.
    ///
    /// This computed property provides a consistent location for storing stream data
    /// across different iOS versions. It automatically adapts to the available APIs
    /// while maintaining backward compatibility.
    ///
    /// ## Directory Location
    /// - **iOS 16.0+**: Uses `URL.documentsDirectory` for better security and organization
    /// - **iOS < 16.0**: Falls back to the Documents directory or temporary directory
    ///
    /// ## Path Structure
    /// The returned URL points to a "streams" subdirectory within the appropriate
    /// base directory, ensuring organized file storage.
    ///
    /// ## Usage Examples
    /// ```swift
    /// let streamsDir = URL.streamsDirectory
    ///
    /// // Create a file in the streams directory
    /// let fileURL = streamsDir.appendingPathComponent("upload_123.data")
    ///
    /// // Ensure directory exists
    /// try FileManager.default.createDirectory(at: streamsDir, withIntermediateDirectories: true)
    /// ```
    ///
    /// ## Thread Safety
    /// This property is thread-safe and can be accessed from any thread.
    ///
    /// ## Availability
    /// - **iOS**: 13.0+
    /// - **macOS**: 10.15+
    ///
    /// ## Notes
    /// - The directory may not exist initially and should be created if needed
    /// - Files in this directory are subject to the same backup and sync policies as the parent directory
    /// - Consider using this directory for temporary stream data that can be recreated
    ///
    /// - Returns: A URL pointing to the streams directory
    static var streamsDirectory: URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory
                .appendingPathComponent("streams", isDirectory: true)
        } else {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first
            let url = documentsDirectory ?? FileManager.default.temporaryDirectory

            return url.appendingPathComponent("streams", isDirectory: true)
        }
    }
}
