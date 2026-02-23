//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// The title metadata value for TruVideo media files.
///
/// This constant defines the title that will be embedded in media file metadata
/// to identify the content as originating from the TruVideo platform.
/// It is used when creating media files to ensure proper attribution
/// and identification in media players and file systems.
let truVideoMetadataTitle = "TruVideo"

/// The artist metadata value for TruVideo media files.
///
/// This constant defines the artist/creator metadata that points to the
/// TruVideo platform URL. It serves as a reference to the source
/// platform and provides users with a way to identify the origin
/// of the media content.
let truVideoMetadataArtist = "https://truvideo.com/"

/// A global actor that serializes access to capture-device operations.
///
/// Use this actor to ensure all capture session and device mutations occur on a single,
/// well-defined executor, preventing data races and reducing configuration hazards.
/// Conforming device types may isolate their APIs to `DeviceActor` to guarantee consistency.
@globalActor
actor DeviceActor {
    /// The shared global actor instance used to isolate device operations.
    static let shared = DeviceActor()
}
