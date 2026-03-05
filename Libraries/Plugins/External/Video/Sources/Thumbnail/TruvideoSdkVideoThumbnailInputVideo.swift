//
//  TruvideoSdkVideoThumbnailInputVideo.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 10/7/24.
//

import Foundation

/// Thumbnail generation input
struct TruvideoSdkVideoThumbnailInputVideo {
    /// Video URL
    let input: TruvideoSdkVideoFile
    /// Thumbnail URL destination
    let output: TruvideoSdkVideoFileDescriptor
    /// Specific time of the video to be used s thumbnail
    let position: TimeInterval
    /// Thumbnail width
    let width: Int?
    /// Thumbnail height
    let height: Int?

    init(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor,
        position: TimeInterval = 1000,
        width: Int? = nil,
        height: Int? = nil
    ) {
        self.input = input
        self.output = output
        self.position = position / 1000
        self.width = width
        self.height = height
    }
}
