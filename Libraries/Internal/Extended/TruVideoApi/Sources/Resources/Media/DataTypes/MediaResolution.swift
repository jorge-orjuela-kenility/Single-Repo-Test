//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// Represents the quality or size of the media resolution.
/// Use this to standardize how you handle different resolutions across
/// uploads, processing pipelines, and playback configurations.
public enum MediaResolution: String, Codable, Sendable {
    /// Low resolution.
    ///
    /// ## Typical Use Cases
    /// - Fast previews
    /// - Thumbnails
    /// - Low-bandwidth connections
    /// - Background loading where quality is not critical
    case low = "LOW"

    /// Medium resolution.
    ///
    /// ## Typical Use Cases
    /// - Standard playback on mobile devices
    /// - Default quality when bandwidth is moderate
    /// - Balance between quality and file size
    case medium = "MEDIUM"

    /// High resolution.
    ///
    /// ## Typical Use Cases
    /// - High-quality playback on larger screens
    /// - When bandwidth and storage are less constrained
    /// - Marketing, demo, or client-facing content
    case high = "HIGH"

    /// Unknown or unrecognized resolution.
    ///
    /// This is a fallback when the backend sends a value that does not
    /// match any known resolution or when the field is missing.
    ///
    /// ## Common Scenarios
    /// - New resolution levels introduced on the backend not yet supported
    /// - Malformed or unexpected payloads
    /// - Default value for defensive decoding
    case unknown = "UNKNOWN"
}
