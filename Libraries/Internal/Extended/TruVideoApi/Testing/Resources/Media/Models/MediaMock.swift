//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import TruVideoFoundation

@testable import TruVideoApi

public extension Media {
    /// Returns a mock instance `Media`.
    static var mock: Media {
        Media(
            id: UUID(),
            active: true,
            createdDate: Date(),
            duration: nil,
            includeInReport: true,
            isLibrary: true,
            metadata: [:],
            previewUrl: URL(string: "https://example.com/preview.jpg"),
            sanitizedTitle: "",
            tags: ["category": "test"],
            thumbnailUrl: URL(string: "https://example.com/thumbnail.jpg"),
            title: "foo-bar",
            transcriptionLength: 2.0,
            transcriptionUrl: nil,
            type: .image,
            url: URL(string: "https://example.com")!
        )
    }
}
