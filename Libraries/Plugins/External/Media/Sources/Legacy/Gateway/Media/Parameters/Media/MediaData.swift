//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

/// The media creation request body data
struct MediaData {
    // MARK: Properties

    /// File title
    let title: String

    /// File type
    let type: TruvideoSdkMediaType

    /// File url
    let url: URL

    /// File size
    let size: Int

    /// File resolution
    let resolution: String

    /// Additional metadata attached to the uploaded file.
    let metadata: Metadata

    /// Additional tags attached to the uploaded file.
    let tags: [String: String]

    /// Send To OEM flag
    let includeInReport: Bool?

    /// File duration
    let duration: Int?

    /// Is Library property
    let isLibrary: Bool?

    /// Codable representation used to generate the HTTP reuest body
    var codableRepresentation: CodableMediaData {
        var urlComponents = URLComponents(string: url.absoluteString)
        urlComponents?.query = nil
        return CodableMediaData(
            title: title,
            type: type.rawValue,
            url: urlComponents?.url?.absoluteString ?? "",
            size: size,
            resolution: resolution,
            metadata: metadata.description,
            tags: tags,
            includeInReport: includeInReport,
            duration: duration,
            isLibrary: isLibrary
        )
    }

    /// Media data codable representation
    struct CodableMediaData: Codable {
        let title: String
        let type: String
        let url: String
        let size: Int
        let resolution: String
        let metadata: String
        let tags: [String: String]
        let includeInReport: Bool?
        let duration: Int?
        let isLibrary: Bool?
    }
}
