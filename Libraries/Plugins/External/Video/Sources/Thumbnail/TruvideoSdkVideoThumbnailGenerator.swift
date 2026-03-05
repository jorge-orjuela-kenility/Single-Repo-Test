//
//  TruvideoSdkVideoThumbnailGenerator.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 10/7/24.
//

import Foundation

protocol TruvideoSdkVideoThumbnailGenerator {
    /// Method used to generate a thumbnail from a given video.
    /// - Parameter video: A `TruvideoSdkVideoThumbnailInputVideo` containing the information to generated the
    /// thumbnail.
    /// - Returns:A `TruvideoSdkVideoThumbnailResult` containing the result of the thumbnail generation.
    func generateThumbnail(for video: TruvideoSdkVideoThumbnailInputVideo) async throws
        -> TruvideoSdkVideoThumbnailResult
}
