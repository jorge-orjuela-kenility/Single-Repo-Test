//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import InternalUtilities
import TruVideoFoundation

/// Represents the payload used to create or update a media resource.
///
/// This type groups all the attributes that can be sent to the backend
/// when saving media (both on **create** and **update** operations).
/// It is typically serialized into the JSON body of the `/api/media`
/// endpoints.
public struct SaveMediaParameters {
    /// Duration of the media in seconds, when applicable.
    public let duration: Int?

    /// Indicates whether this media should be included in reporting or analytics views.
    public let includeInReport: Bool?

    /// Indicates whether the media belongs to a shared/library collection.
    public let isLibrary: Bool?

    /// Arbitrary metadata associated with the media.
    public let metadata: Metadata?

    /// Logical resolution descriptor for the media.
    public let resolution: MediaResolution?

    /// Size of the media file in bytes.
    public let size: Int

    /// Tags associated with the media, represented as key–value pairs.
    public let tags: [String: String]?

    /// Human-readable title or name of the media.
    public let title: String

    /// Logical media type, such as `.video`, `.image`, `.audio`, or `.document`.
    public let type: MediaType

    /// The absolute URL where the media content is stored.
    public let url: String

    // MARK: - Initializer

    /// Creates a new instance of `SaveMediaParameters`.
    ///
    /// - Parameters:
    ///   - size: The size of the media file in bytes.
    ///   - title: Human-readable title or name of the media.
    ///   - type: The logical media type (e.g. `.video`, `.image`).
    ///   - url: The absolute URL where the media is stored.
    ///   - duration: Optional duration in seconds for time-based media.
    ///   - includeInReport: Optional flag indicating if the media should be
    ///     considered in reporting or analytics.
    ///   - isLibrary: Optional flag indicating if the media belongs to a
    ///     shared library of reusable assets.
    ///   - metadata: Optional metadata payload, often JSON-encoded.
    ///   - resolution: Optional logical resolution descriptor for the media.
    ///   - tags: Optional key–value tags attached to the media.
    public init(
        size: Int,
        title: String,
        type: MediaType,
        url: String,
        duration: Int? = nil,
        includeInReport: Bool?,
        isLibrary: Bool? = nil,
        metadata: Metadata? = nil,
        resolution: MediaResolution? = nil,
        tags: [String: String]? = nil
    ) {
        self.url = url
        self.duration = duration
        self.includeInReport = includeInReport
        self.isLibrary = isLibrary
        self.metadata = metadata
        self.resolution = resolution
        self.size = size
        self.tags = tags
        self.type = type
        self.title = title
    }
}
