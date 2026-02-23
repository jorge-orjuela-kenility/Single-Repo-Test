//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

/// The media endpoint http response
struct MediaDTO: Decodable {
    /// The stable identity of the entity associated with this instance.
    let id: String

    /// The date when this media was created.
    let createdDate: String

    /// A flag indicating whether this media should be included in the report.
    let includeInReport: Bool

    /// Is Library
    let isLibrary: Bool

    /// Additional metadata attached to the uploaded file.
    let metadata: Metadata

    /// The preview URL of the media, if available
    let previewUrl: URL?

    /// Additional tags attached to the uploaded file.
    let tags: [String: String]

    /// The thumbnail image URL of the media, if available.
    let thumbnailUrl: URL?

    /// The length of the transcription in seconds.
    let transcriptionLength: Float

    /// The URL of the transcription associated with the uploaded file.
    let transcriptionUrl: URL?

    /// The type of the media.
    let type: TruvideoSdkMediaType

    /// The URL of the uploaded file.
    let url: URL

    /// Allowable keys for the  model.
    private enum CodingKeys: String, CodingKey {
        case id
        case createdDate
        case includeInReport
        case isLibrary
        case metadata
        case previewUrl
        case tags
        case transcriptionLength
        case transcriptionUrl
        case thumbnailUrl
        case type
        case url
    }

    // MARK: Initializers

    /// Creates a new instance of the `MediaDTO`.
    ///
    /// - Parameters:
    ///   - id: The stable identity of the entity associated with this instance.
    ///   - createdDate: The date when this media was created.
    ///   - includeInReport: A flag indicating whether this media should be included in the report.
    ///   - metadata: Additional metadata attached to the uploaded file.
    ///   - previewUrl: The preview URL of the media, if available
    ///   - tags: Additional tags attached to the uploaded file.
    ///   - thumbnailUrl: The thumbnail image URL of the media, if available.
    ///   - transcriptionLength: The length of the transcription in seconds.
    ///   - transcriptionUrl: The URL of the transcription associated with the uploaded file.
    ///   - url: The URL of the uploaded file.
    init(
        id: String,
        createdDate: String,
        metadata: Metadata,
        includeInReport: Bool,
        isLibrary: Bool,
        previewUrl: URL?,
        tags: [String: String],
        thumbnailUrl: URL?,
        transcriptionLength: Float,
        transcriptionUrl: URL?,
        type: TruvideoSdkMediaType,
        url: URL
    ) {
        self.id = id
        self.createdDate = createdDate
        self.includeInReport = includeInReport
        self.isLibrary = isLibrary
        self.metadata = metadata
        self.previewUrl = previewUrl
        self.tags = tags
        self.thumbnailUrl = thumbnailUrl
        self.transcriptionLength = transcriptionLength
        self.transcriptionUrl = transcriptionUrl
        self.type = type
        self.url = url
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let transcriptionLength = try container.decodeIfPresent(String.self, forKey: .transcriptionLength) ?? "0"

        self.id = try container.decode(String.self, forKey: .id)
        self.createdDate = try container.decode(String.self, forKey: .createdDate)
        self.includeInReport = try container.decodeIfPresent(Bool.self, forKey: .includeInReport) ?? false
        self.isLibrary = try container.decodeIfPresent(Bool.self, forKey: .isLibrary) ?? false
        self.previewUrl = try container.decodeIfPresent(URL.self, forKey: .previewUrl)
        self.tags = try container.decodeIfPresent([String: String].self, forKey: .tags) ?? [:]
        self.thumbnailUrl = try container.decodeIfPresent(URL.self, forKey: .thumbnailUrl)
        self.transcriptionLength = Float(transcriptionLength) ?? 0
        self.transcriptionUrl = try container.decodeIfPresent(URL.self, forKey: .transcriptionUrl)
        self.type = try container.decode(TruvideoSdkMediaType.self, forKey: .type)
        self.url = try container.decode(URL.self, forKey: .url)

        if
            /// The raw string metadata.
            let stringMetadata = try container.decodeIfPresent(String.self, forKey: .metadata),

            /// The data representing the content of `stringMetadata`.
            let data = stringMetadata.data(using: .utf8) {
            let decoder = JSONDecoder()
            self.metadata = try decoder.decode(Metadata.self, from: data)
        } else {
            self.metadata = [:]
        }
    }
}
