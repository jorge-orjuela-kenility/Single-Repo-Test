//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// The media endpoint http response
struct SearchMediaParameters: Encodable {
    // MARK: Properties

    /// The stable identity of the entity to search for.
    let ids: [String]?

    /// A boolean indicating whether the search includes a library filter.
    let isLibrary: Bool

    /// The additional tags to query.
    let tags: [String: String]?

    /// The media type to filter.
    let type: TruvideoSdkMediaType?

    // MARK: - CodingKeys

    /// Allowable keys for the  model.
    private enum CodingKeys: String, CodingKey {
        case ids
        case isLibrary
        case tags
        case type
    }

    // MARK: - Initializer

    /// Creates a new instance of the `SearchMediaParameters`.
    ///
    /// - Parameters:
    ///   - ids: The stable identity of the entity to search for.
    ///   - tags: The additional tags to query.
    ///   - isLibrary: A boolean indicating whether the search includes a library filter.
    ///   - type: The media type to filter.
    init(
        ids: [String]? = nil,
        tags: [String: String]? = nil,
        isLibrary: Bool = false,
        type: TruvideoSdkMediaType? = nil
    ) {
        self.ids = ids
        self.isLibrary = isLibrary
        self.tags = tags
        self.type = type
    }

    // MARK: - Encodable

    /// Encodes this value into the given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(ids, forKey: .ids)
        try container.encode(isLibrary, forKey: .isLibrary)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(type, forKey: .type)
    }
}
