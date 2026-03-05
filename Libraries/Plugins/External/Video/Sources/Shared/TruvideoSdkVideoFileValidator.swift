//
//  TruvideoSdkVideoFileValidator.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 16/2/24.
//

import AVKit

final class TruvideoSdkVideoFileValidator {
    private let minimumSupportedResolutionDimension: CGFloat = 128

    func validateFileAt(url: URL) throws {
        if #available(iOS 16.0, *) {
            guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
                throw TruvideoSdkVideoError.notFoundVideo
            }
        } else {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw TruvideoSdkVideoError.notFoundVideo
            }
        }

        guard url.isVideo else {
            throw TruvideoSdkVideoError.invalidFile
        }
    }

    func validateResolution(component: CGFloat?) throws {
        guard let component else {
            return
        }

        guard component >= minimumSupportedResolutionDimension else {
            throw TruvideoSdkVideoError.invalidResolution
        }
    }

    func validateVideosExistence(videos: [URL], minVideosCount: Int = 1) throws {
        guard videos.count >= minVideosCount else {
            throw TruvideoSdkVideoError.invalidInputFiles(reason: .notEnoughVideos)
        }
        for video in videos {
            if !FileManager.default.fileExists(atPath: video.path) {
                throw TruvideoSdkVideoError.invalidInputFiles(reason: .inputContainsNonExistingFiles)
            }
        }
    }
}

private extension URL {
    var isVideo: Bool {
        let fileMimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        return UTType(mimeType: fileMimeType)?.conforms(to: .audiovisualContent) ?? false
    }
}
