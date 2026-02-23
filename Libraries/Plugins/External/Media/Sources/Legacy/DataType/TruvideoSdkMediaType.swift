//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// An enumeration representing different types of media.
public enum TruvideoSdkMediaType: String, Codable {
    /// Represents an image media type.
    case image = "IMAGE"

    /// Represents a video media type.
    case video = "VIDEO"

    /// Represents an audio media type.
    case audio = "AUDIO"

    /// Represents a pdf media type.
    case document = "DOCUMENT"
}
