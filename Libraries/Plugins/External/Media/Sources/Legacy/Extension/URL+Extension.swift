//
// Copyright © 2026 TruVideo. All rights reserved.
//

import AVFoundation
import Foundation

extension URL {
    private static let videoTypes: [UTType] = [.audiovisualContent, .mpeg4Movie, .quickTimeMovie, .movie]
    private static let imageTypes: [UTType] = [.jpeg, .png, .gif, .tiff, .bmp, .heic, .heif]
    private static let audioTypes: [UTType] = [.mp3, .wav, .audio]
    private static let pdfType: UTType = .pdf

    private var type: UTType {
        UTType(filenameExtension: pathExtension) ?? .url
    }

    private var isVideo: Bool {
        Self.videoTypes.contains { type.conforms(to: $0) }
    }

    private var isImage: Bool {
        Self.imageTypes.contains { type.conforms(to: $0) }
    }

    private var isAudio: Bool {
        Self.audioTypes.contains { type.conforms(to: $0) }
    }

    private var isPDF: Bool {
        Self.pdfType.conforms(to: type)
    }

    var fileSize: Int {
        let fileSize = try? resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize
        return fileSize ?? 0
    }

    var fileMimeType: String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }

    var isValid: Bool {
        isVideo || isImage || isAudio || isPDF
    }

    func makeFileName(with id: UUID) -> String {
        "\(id.uuidString).\(pathExtension)"
    }

    func getDuration() -> Int? {
        guard isVideo || isAudio else { return nil }

        let asset = AVAsset(url: self)
        let durationInSeconds = CMTimeGetSeconds(asset.duration)

        return durationInSeconds.isFinite ? Int(durationInSeconds) : nil
    }

    func getFileType() -> TruvideoSdkMediaType {
        if isAudio {
            return .audio
        }
        if isImage {
            return .image
        }
        if isVideo {
            return .video
        }
        return .document
    }
}
