//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// An enumeration that defines the high-level categories of supported media.
///
/// `MediaType` represents the semantic classification of a media resource
/// (e.g., video, image, audio, or document). Unlike `FileType`, which specifies
/// the exact file extension (e.g., `.mp4`, `.jpg`, `.pdf`), `MediaType` groups
/// those extensions into broader categories that are meaningful to the TruVideo
/// API and client applications.
///
/// This value is used in the `metadata.type` field when initializing or
/// finalizing uploads, allowing the backend to apply media-specific processing
/// such as thumbnail generation, preview GIF creation, or audio transcription.
public enum MediaType: String, Codable, Sendable {
    /// Video media category.
    ///
    /// Includes formats such as:
    /// - `.mp4`
    /// - `.mov`
    /// - `.avi`
    /// - `.mkv`
    /// - `.flv`
    /// - `.wmv`
    /// - `.3gpp`
    /// - `.webm`
    ///
    /// ## Example Use Cases
    /// - Uploading recorded video clips
    /// - Marketing or training videos
    /// - Video tutorials and product demos
    case video = "VIDEO"

    /// Image media category.
    ///
    /// Includes formats such as:
    /// - `.jpg`
    /// - `.jpeg`
    /// - `.png`
    /// - `.svg`
    ///
    /// ## Example Use Cases
    ///
    /// - Product photography
    /// - Screenshots
    /// - Logos and icons
    /// - Illustrations and diagrams
    case image = "IMAGE"

    /// Audio media category.
    ///
    /// Includes formats such as:
    /// - `.mp3`
    /// - `.wav`
    /// - `.aac`
    /// - `.flac`
    ///
    /// ## Example Use Cases
    ///
    /// - Voice recordings
    /// - Podcasts
    /// - Music tracks
    /// - Transcriptions and dictations
    case audio = "AUDIO"

    /// Document media category.
    ///
    /// Includes formats such as:
    /// - `.pdf`
    ///
    /// ## Example Use Cases
    ///
    /// - Reports
    /// - Manuals
    /// - Contracts
    /// - E-books and reference materials
    case document = "DOCUMENT"

    /// Unknown or unrecognized media category.
    ///
    /// This case represents media that does not fit into any of the defined
    /// categories or files whose type cannot be determined. This serves as a
    /// fallback for handling unsupported or unrecognized file formats.
    ///
    /// ## Common Scenarios
    /// - Unsupported file extensions not covered by existing media types
    /// - Files without a clear category classification
    /// - Fallback when type detection fails
    /// - Future file format support not yet implemented
    ///
    /// ## Usage Examples
    /// ```swift
    /// // When file type cannot be determined
    /// let mediaType: MediaType = .unknown
    ///
    /// // When handling unrecognized uploads
    /// if mediaType == .unknown {
    ///     log.warning("Unrecognized media type, using generic upload handler")
    /// }
    /// ```
    ///
    /// ## Backend Handling
    /// The backend may apply generic processing for unknown media types
    /// or reject the upload depending on security policies.
    ///
    /// ## Compatibility
    /// - Used as a default value in type detection
    /// - Allows graceful degradation for unsupported formats
    /// - Consider logging when unknown types are encountered
    ///
    /// - Note: Should be used sparingly. Prefer specific categories when possible.
    case unknown = "UNKNOWN"
}
