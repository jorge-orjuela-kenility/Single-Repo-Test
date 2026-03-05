//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import InternalUtilities
import TruVideoFoundation

/// Represents a media resource returned by the backend.
///
/// This model encapsulates all server-side information about a media item,
/// including identity, lifecycle flags, metadata, and various helper URLs.
/// It is typically obtained via the Media API (e.g. `/api/media`, `/api/media/search`).
public struct Media: Codable, Identifiable, Sendable {
    /// Unique identifier of the media resource.
    public let id: UUID

    /// Indicates whether the media is currently active.
    public let active: Bool

    /// The date and time when the media was created, as provided by the backend.
    public let createdDate: Date

    /// Duration of the media in seconds, when applicable.
    public let duration: Int?

    /// Indicates whether this media should be included in reporting or analytics.
    public let includeInReport: Bool

    /// Indicates whether the media belongs to a shared/library collection.
    public let isLibrary: Bool

    /// Structured metadata associated with the media.
    public let metadata: Metadata

    /// Optional URL to a preview version of the media.
    public let previewUrl: URL?

    /// A sanitized version of the media title.
    public let sanitizedTitle: String

    /// Tags associated with the media, represented as key–value pairs.
    public let tags: [String: String]

    /// Optional URL to a thumbnail image representing the media.
    public let thumbnailUrl: URL?

    /// Human-readable title of the media.
    public let title: String?

    /// Optional length or summary information about the transcription.
    public let transcriptionLength: Double

    /// Optional URL pointing to a transcription resource for the media.
    public let transcriptionUrl: URL?

    /// Logical media type, such as `.video`, `.image`, `.audio`, or `.document`.
    public let type: MediaType

    /// The primary URL where the media content is stored.
    public let url: URL

    // MARK: - Static Properties

    /// A default empty media instance with all properties set to their default values.
    public static let empty = Media(
        id: UUID(),
        active: false,
        createdDate: .distantPast,
        duration: nil,
        includeInReport: false,
        isLibrary: false,
        metadata: [:],
        previewUrl: nil,
        sanitizedTitle: "",
        tags: [:],
        thumbnailUrl: nil,
        title: nil,
        transcriptionLength: 0,
        transcriptionUrl: nil,
        type: .audio,
        url: URL(fileURLWithPath: "")
    )

    // MARK: Initializers

    /// Creates a new instance of the `MediaDTO`.
    ///
    /// - Parameters:
    ///   - id: Unique identifier of the media resource.
    ///   - active: Indicates whether the media is currently active.
    ///   - createdDate: The date and time when the media was created, as provided by the backend.
    ///   - duration: Duration of the media in seconds, when applicable.
    ///   - includeInReport: Indicates whether this media should be included in reporting or analytics.
    ///   - isLibrary: Indicates whether the media belongs to a shared/library collection.
    ///   - metadata: Structured metadata associated with the media.
    ///   - previewUrl: Optional URL to a preview version of the media.
    ///   - sanitizedTitle: A sanitized version of the media title.
    ///   - tags: Tags associated with the media, represented as key–value pairs.
    ///   - thumbnailUrl: Optional URL to a thumbnail image representing the media.
    ///   - title: Human-readable title of the media.
    ///   - transcriptionLength: Optional length or summary information about the transcription.
    ///   - transcriptionUrl: Optional URL pointing to a transcription resource for the media.
    ///   - type: Logical media type, such as `.video`, `.image`, `.audio`, or `.document`.
    ///   - url: The primary URL where the media content is stored.
    init(
        id: UUID,
        active: Bool,
        createdDate: Date,
        duration: Int?,
        includeInReport: Bool,
        isLibrary: Bool,
        metadata: Metadata,
        previewUrl: URL?,
        sanitizedTitle: String,
        tags: [String: String],
        thumbnailUrl: URL?,
        title: String?,
        transcriptionLength: Double,
        transcriptionUrl: URL?,
        type: MediaType,
        url: URL
    ) {
        self.id = id
        self.active = active
        self.createdDate = createdDate
        self.duration = duration
        self.includeInReport = includeInReport
        self.isLibrary = isLibrary
        self.metadata = metadata
        self.previewUrl = previewUrl
        self.sanitizedTitle = sanitizedTitle
        self.tags = tags
        self.thumbnailUrl = thumbnailUrl
        self.title = title
        self.transcriptionLength = transcriptionLength
        self.transcriptionUrl = transcriptionUrl
        self.type = type
        self.url = url
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let createdDateString = try container.decode(String.self, forKey: .createdDate)

        self.id = try container.decode(UUID.self, forKey: .id)
        self.active = try container.decode(Bool.self, forKey: .active)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        self.includeInReport = try container.decode(Bool.self, forKey: .includeInReport)
        self.isLibrary = try container.decode(Bool.self, forKey: .isLibrary)
        self.metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata) ?? [:]
        self.previewUrl = try container.decodeIfPresent(URL.self, forKey: .previewUrl)
        self.sanitizedTitle = try container.decode(String.self, forKey: .sanitizedTitle)
        self.tags = try container.decodeIfPresent([String: String].self, forKey: .tags) ?? [:]
        self.thumbnailUrl = try container.decodeIfPresent(URL.self, forKey: .thumbnailUrl)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.transcriptionUrl = try container.decodeIfPresent(URL.self, forKey: .transcriptionUrl)
        self.type = try container.decode(MediaType.self, forKey: .type)
        self.url = try container.decode(URL.self, forKey: .url)

        self.createdDate = try createdDateString.toDate("yyyy-MM-dd'T'HH:mm:ss'Z'")
            .unwrap(
                or: DecodingError.dataCorruptedError(
                    forKey: .createdDate,
                    in: container,
                    debugDescription: "Invalid ISO8601 date: \(createdDateString)"
                )
            )

        if
            // Raw transcription length as a String provided by the backend.
            let transcriptionLengthString = try container.decodeIfPresent(String.self, forKey: .transcriptionLength),

            // Parsed Double value from `transcriptionLengthString`.
            let transcriptionLength = Double(transcriptionLengthString) {
            self.transcriptionLength = transcriptionLength
        } else {
            self.transcriptionLength = 0
        }
    }
}
