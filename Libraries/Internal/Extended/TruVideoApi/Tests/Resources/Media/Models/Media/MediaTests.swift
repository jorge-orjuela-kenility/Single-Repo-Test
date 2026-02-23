//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import InternalUtilities
import Testing
import TruVideoFoundation

@testable import TruVideoApi

struct MediaTests {
    // MARK: - Tests

    @Test
    func testThatMediaShouldDecodeSuccessfullyWhenPayloadIsValid() async throws {
        // Given
        let json = """
        {
          "id": "E9C8A3B6-9A3F-4D9B-8E42-3A6D9E1A9F01",
          "active": true,
          "createdDate": "2025-01-10T15:30:45.123Z",
          "duration": 120,
          "includeInReport": true,
          "isLibrary": false,
          "metadata": "{\\"key\\":\\"value\\"}",
          "previewUrl": "https://example.com/preview.mp4",
          "sanitizedTitle": "foo-bar",
          "tags": { "env": "test" },
          "thumbnailUrl": "https://example.com/thumb.png",
          "title": "Foo Bar",
          "transcriptionLength": "12.5",
          "transcriptionUrl": "https://example.com/transcription",
          "type": "AUDIO",
          "url": "https://example.com/media.mp3"
        }
        """

        // When
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        let media = try decoder.decode(Media.self, from: data)

        // Then
        #expect(media.title == "Foo Bar")
        #expect(media.duration == 120)
        #expect(media.transcriptionLength == 12.5)
    }

    @Test
    func testThatMediaShouldDefaultTranscriptionLengthToZeroWhenValueIsInvalid() throws {
        // Given
        let json = """
        {
          "id": "E9C8A3B6-9A3F-4D9B-8E42-3A6D9E1A9F01",
          "active": true,
          "createdDate": "2025-01-10T15:30:45.123Z",
          "includeInReport": false,
          "isLibrary": false,
          "sanitizedTitle": "test",
          "tags": {},
          "title": "Test",
          "transcriptionLength": "abc",
          "type": "AUDIO",
          "url": "https://example.com/media.mp3"
        }
        """

        // When
        let media = try JSONDecoder().decode(Media.self, from: Data(json.utf8))

        // Then
        #expect(media.transcriptionLength == 0)
    }

    @Test
    func testThatMediaShouldDefaultTranscriptionLengthToZeroWhenValueIsMissing() throws {
        // Given
        let json = """
        {
          "id": "E9C8A3B6-9A3F-4D9B-8E42-3A6D9E1A9F01",
          "active": true,
          "createdDate": "2025-01-10T15:30:45.123Z",
          "includeInReport": false,
          "isLibrary": false,
          "sanitizedTitle": "test",
          "tags": {},
          "title": "Test",
          "type": "AUDIO",
          "url": "https://example.com/media.mp3"
        }
        """

        // When
        let media = try JSONDecoder().decode(Media.self, from: Data(json.utf8))

        // Then
        #expect(media.transcriptionLength == 0)
    }

    @Test
    func testThatMediaShouldDecodeWithEmptyMetadataWhenMetadataIsMissing() throws {
        // Given
        let json = """
        {
          "id": "E9C8A3B6-9A3F-4D9B-8E42-3A6D9E1A9F01",
          "active": true,
          "createdDate": "2025-01-10T15:30:45.123Z",
          "includeInReport": false,
          "isLibrary": false,
          "sanitizedTitle": "test",
          "tags": {},
          "title": "Test",
          "type": "AUDIO",
          "url": "https://example.com/media.mp3"
        }
        """

        // When
        let media = try JSONDecoder().decode(Media.self, from: Data(json.utf8))

        // Then
        #expect(media.metadata.isEmpty)
    }

    @Test
    func testThatMediaShouldDecodeWithEmptyTagsWhenTagsAreMissing() throws {
        // Given
        let json = """
        {
          "id": "E9C8A3B6-9A3F-4D9B-8E42-3A6D9E1A9F01",
          "active": true,
          "createdDate": "2025-01-10T15:30:45.123Z",
          "includeInReport": false,
          "isLibrary": false,
          "sanitizedTitle": "test",
          "title": "Test",
          "type": "AUDIO",
          "url": "https://example.com/media.mp3"
        }
        """

        // When
        let media = try JSONDecoder().decode(Media.self, from: Data(json.utf8))

        // Then
        #expect(media.tags.isEmpty)
    }
}
