//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// Represents the result of a media file upload through the Truvideo SDK.
///
/// This type alias maps `TruvideoSdkMediaFileUploadResult` to `TruvideoSDKMedia`,
/// allowing the use of a more descriptive name when working with the result of media file uploads.
public typealias TruvideoSdkMediaFileUploadResult = TruvideoSDKMedia

/// Represents the response from the Truvideo SDK media.
///
/// This struct encapsulates the metadata, tags, and URLs related to a media file uploaded
/// through the Truvideo SDK.
public struct TruvideoSDKMedia: Equatable {
    /// The date when this media was created.
    public let createdDate: Date

    /// Additional metadata attached to the uploaded file.
    public let metadata: TruvideoSdkMediaMetadata

    /// The preview URL of the media, if available
    public let previewUrl: URL?

    /// The stable identity of the entity associated with this instance.
    public let remoteId: String

    /// Additional tags attached to the uploaded file.
    public let tags: TruvideoSdkMediaTags

    /// The thumbnail image URL of the media, if available.
    public let thumbnailUrl: URL?

    /// The length of the transcription in seconds.
    public let transcriptionLength: Float

    /// The URL of the transcription associated with the uploaded file.
    public let transcriptionURL: URL?

    /// The type of the media.
    public let type: TruvideoSdkMediaType

    /// The URL of the uploaded file.
    public let uploadedFileURL: URL

    /// A flag indicating whether this media should be included in the report.
    public let includeInReport: Bool

    /// Is Library
    public let isLibrary: Bool

    // MARK: Static methods

    /// Creates an instance of the `TruvideoSDKMedia` from the given DTO.
    ///
    /// - Parameter media: The DTO containing the information.
    /// - Returns: A new instance of the `TruvideoSDKMedia`.
    static func from(_ media: MediaDTO) throws -> TruvideoSDKMedia {
        try .init(
            createdDate: media.createdDate.toDate().unwrap(or: TruvideoSdkMediaError.generic),
            metadata: TruvideoSdkMediaMetadata(metadata: media.metadata),
            previewUrl: media.previewUrl,
            remoteId: media.id,
            tags: .init(dictionary: media.tags),
            thumbnailUrl: media.thumbnailUrl,
            transcriptionLength: media.transcriptionLength,
            transcriptionURL: media.transcriptionUrl,
            type: media.type,
            uploadedFileURL: media.url,
            includeInReport: media.includeInReport,
            isLibrary: media.isLibrary
        )
    }
}
