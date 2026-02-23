//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
@testable import TruvideoSdkCamera
import UIKit

// MARK: - Mock Media Factory

/// Factory for creating mock media items for snapshot testing.
///
/// This factory provides methods to create realistic mock `Photo` and `VideoClip`
/// instances that can be used in snapshot tests to simulate various camera states
/// such as having captured media items.
enum MockMediaFactory {
    /// Creates a mock photo with default test values.
    ///
    /// - Parameters:
    ///   - lensPosition: The camera lens position (defaults to `.back`)
    ///   - orientation: The device orientation (defaults to `.portrait`)
    ///   - preset: The capture preset (defaults to `.hd1280x720`)
    /// - Returns: A `Photo` instance configured for testing
    static func createMockPhoto(
        lensPosition: AVCaptureDevice.Position = .back,
        orientation: UIDeviceOrientation = .portrait,
        preset: AVCaptureSession.Preset = .hd1280x720
    ) -> Photo {
        let tempDirectory = FileManager.default.temporaryDirectory
        let url = tempDirectory.appendingPathComponent("mock_photo_\(UUID().uuidString).jpg")
        let thumbnailURL = tempDirectory.appendingPathComponent("mock_thumb_\(UUID().uuidString).jpg")

        return Photo(
            url: url,
            thumbnailURL: thumbnailURL,
            format: .jpeg,
            lensPosition: lensPosition,
            orientation: orientation,
            preset: preset
        )
    }

    /// Creates a mock video clip with default test values.
    ///
    /// - Parameters:
    ///   - duration: The video duration in seconds (defaults to 10.0)
    ///   - lensPosition: The camera lens position (defaults to `.back`)
    ///   - orientation: The device orientation (defaults to `.portrait`)
    ///   - preset: The capture preset (defaults to `.hd1280x720`)
    ///   - size: The file size in bytes (defaults to 1MB)
    /// - Returns: A `VideoClip` instance configured for testing
    static func createMockVideoClip(
        duration: TimeInterval = 10.0,
        lensPosition: AVCaptureDevice.Position = .back,
        orientation: UIDeviceOrientation = .portrait,
        preset: AVCaptureSession.Preset = .hd1280x720,
        size: Int64 = 1_000_000
    ) -> VideoClip {
        let tempDirectory = FileManager.default.temporaryDirectory
        let url = tempDirectory.appendingPathComponent("mock_video_\(UUID().uuidString).mp4")
        let thumbnailURL = tempDirectory.appendingPathComponent("mock_thumb_\(UUID().uuidString).jpg")

        return VideoClip(
            duration: duration,
            lensPosition: lensPosition,
            orientation: orientation,
            preset: preset,
            size: size,
            thumbnailURL: thumbnailURL,
            url: url
        )
    }

    /// Creates a `Media` instance wrapping a mock photo.
    ///
    /// - Parameters:
    ///   - lensPosition: The camera lens position (defaults to `.back`)
    ///   - orientation: The device orientation (defaults to `.portrait`)
    /// - Returns: A `Media.photo` instance configured for testing
    static func createMockPhotoMedia(
        lensPosition: AVCaptureDevice.Position = .back,
        orientation: UIDeviceOrientation = .portrait
    ) -> Media {
        .photo(createMockPhoto(lensPosition: lensPosition, orientation: orientation))
    }

    /// Creates a `Media` instance wrapping a mock video clip.
    ///
    /// - Parameters:
    ///   - duration: The video duration in seconds (defaults to 10.0)
    ///   - lensPosition: The camera lens position (defaults to `.back`)
    ///   - orientation: The device orientation (defaults to `.portrait`)
    /// - Returns: A `Media.clip` instance configured for testing
    static func createMockClipMedia(
        duration: TimeInterval = 10.0,
        lensPosition: AVCaptureDevice.Position = .back,
        orientation: UIDeviceOrientation = .portrait
    ) -> Media {
        .clip(createMockVideoClip(duration: duration, lensPosition: lensPosition, orientation: orientation))
    }
}
