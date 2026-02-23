//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable import MediaUpload

struct FileTypeTests {
    // MARK: - Tests

    @Test
    func testThatVideoFileTypesMapToVideoMediaType() {
        let videoTypes: [FileType] = [
            .mp4, .mov, .avi, .mkv, .flv, .wmv, .g3pp, .webm
        ]

        for type in videoTypes {
            #expect(type.mediaType == .video)
        }
    }

    @Test
    func testThatImageFileTypesMapToImageMediaType() {
        let imageTypes: [FileType] = [.jpg, .jpeg, .png, .svg]

        for type in imageTypes {
            #expect(type.mediaType == .image)
        }
    }

    @Test
    func testThatAudioFileTypesMapToAudioMediaType() {
        let audioTypes: [FileType] = [.mp3, .wav, .aac, .flac]

        for type in audioTypes {
            #expect(type.mediaType == .audio)
        }
    }

    @Test
    func testThatPdfFileTypeMapsToDocumentMediaType() {
        #expect(FileType.pdf.mediaType == .document)
    }

    @Test
    func testThatUnknownFileTypeMapsToUnknownMediaType() {
        #expect(FileType.unknown.mediaType == .unknown)
    }
}
