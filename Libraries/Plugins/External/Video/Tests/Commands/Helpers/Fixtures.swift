//
//  Fixtures.swift
//  TruvideoSdkVideoTests
//
//  Created by Victor Arana on 8/8/24.
//

import Foundation
@testable import TruvideoSdkVideo

extension TruvideoSdkVideoInformation {
    static func fixture(
        url: URL = .fixture(),
        size: Int64 = 10_000,
        durationMillis: Int64 = 12_000,
        format: String = "mp4",
        videoTracks: [TruvideoSdkVideoTrackInformation] = [.fixture()],
        audioTracks: [TruvideoSdkVideoAudioTrackInformation] = [.fixture()],
        orientation: TruvideoSdkVideoInformation.Orientation = .portrait,
        videoSize: CGSize = CGSize(width: 100, height: 100)
    ) -> TruvideoSdkVideoInformation {
        .init(
            url: url,
            size: size,
            durationMillis: durationMillis,
            format: format,
            videoTracks: videoTracks,
            audioTracks: audioTracks,
            orientation: orientation,
            videoSize: videoSize
        )
    }
}

extension TruvideoSdkVideoTrackInformation {
    static func fixture(
        index: Int = 0,
        width: Int = 200,
        height: Int = 200,
        codec: String = "hvc",
        codecTag: String = "tag",
        pixelFormat: String = "px",
        bitRate: Int = 40_000,
        frameRate: String = "24/1",
        rotation: Int = 0,
        durationMillis: Int64 = 30_000
    ) -> TruvideoSdkVideoTrackInformation {
        .init(
            index: index,
            width: width,
            height: height,
            codec: codec,
            codecTag: codecTag,
            pixelFormat: pixelFormat,
            bitRate: bitRate,
            frameRate: frameRate,
            rotation: rotation,
            durationMillis: durationMillis
        )
    }
}

extension TruvideoSdkVideoAudioTrackInformation {
    static func fixture(
        index: Int = 0,
        codec: String = "cod",
        codecTag: String = "tag",
        sampleFormat: String = "sam",
        bitRate: Int = 12_000,
        sampleRate: Int = 10_000,
        channels: Int = 2,
        channelLayout: String = "lay",
        durationMillis: Int64 = 25_000
    ) -> TruvideoSdkVideoAudioTrackInformation {
        .init(
            index: index,
            codec: codec,
            codecTag: codecTag,
            sampleFormat: sampleFormat,
            bitRate: bitRate,
            sampleRate: sampleRate,
            channels: channels,
            channelLayout: channelLayout,
            durationMillis: durationMillis
        )
    }
}

extension URL {
    static func fixture(_ url: String = "file://any-url.com") -> URL {
        URL(string: url)!
    }
}

extension TruvideoSdkVideoMergeVideoTrack {
    static func fixture(
        tracks: [TruvideoSdkVideoMergeMediaEntry] = [
            .fixture(fileIndex: 0, entryIndex: 0),
            .fixture(fileIndex: 1, entryIndex: 0)
        ],
        width: Int? = nil,
        height: Int? = nil
    ) -> TruvideoSdkVideoMergeVideoTrack {
        .init(
            tracks: tracks,
            width: width,
            height: height
        )
    }
}

extension TruvideoSdkVideoMergeAudioTrack {
    static func fixture(
        tracks: [TruvideoSdkVideoMergeMediaEntry] = [
            .fixture(fileIndex: 0, entryIndex: 0),
            .fixture(fileIndex: 1, entryIndex: 0)
        ]
    ) -> TruvideoSdkVideoMergeAudioTrack {
        .init(tracks: tracks)
    }
}

extension TruvideoSdkVideoMergeMediaEntry {
    static func fixture(fileIndex: Int = 0, entryIndex: Int = 0) -> TruvideoSdkVideoMergeMediaEntry {
        .init(fileIndex: fileIndex, entryIndex: entryIndex)
    }
}

extension TruvideoSdkVideoEncodeVideoEntry {
    static func fixture(
        width: Int? = nil,
        height: Int? = nil,
        entryIndex: Int = 0
    ) -> TruvideoSdkVideoEncodeVideoEntry {
        .init(entryIndex: entryIndex, width: width, height: height)
    }
}
