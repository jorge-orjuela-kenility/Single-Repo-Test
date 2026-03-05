//
//  TruvideoSdkVideoInformationImp.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 1/12/23.
//

import AVKit
import Foundation

@objc public class TruvideoSdkVideoTrackInformation: NSObject {
    @objc public let index: Int
    @objc public let width: Int
    @objc public let height: Int
    @objc public let rotatedWidth: Int
    @objc public let rotatedHeight: Int
    @objc public let codec: String
    @objc public let codecTag: String
    @objc public let pixelFormat: String
    @objc public let bitRate: Int
    @objc public let frameRate: String
    @objc public let rotation: Int
    @objc public let durationMillis: Int64

    init(
        index: Int,
        width: Int,
        height: Int,
        codec: String,
        codecTag: String,
        pixelFormat: String,
        bitRate: Int,
        frameRate: String,
        rotation: Int,
        durationMillis: Int64
    ) {
        self.index = index
        self.width = width
        self.height = height
        self.rotatedWidth = rotation == 90 || rotation == 270 ? height : width
        self.rotatedHeight = rotation == 90 || rotation == 270 ? width : height
        self.codec = codec
        self.codecTag = codecTag
        self.pixelFormat = pixelFormat
        self.bitRate = bitRate
        self.frameRate = frameRate
        self.rotation = rotation
        self.durationMillis = durationMillis
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? TruvideoSdkVideoTrackInformation else { return false }

        return self.width == other.width &&
            self.height == other.height &&
            self.rotatedWidth == other.rotatedWidth &&
            self.rotatedHeight == other.rotatedHeight &&
            self.codec == other.codec &&
            self.codecTag == other.codecTag &&
            self.pixelFormat == other.pixelFormat &&
            self.frameRate == other.frameRate &&
            self.rotation == other.rotation
    }
}

@objc public class TruvideoSdkVideoAudioTrackInformation: NSObject {
    @objc public let index: Int
    @objc public let codec: String
    @objc public let codecTag: String
    @objc public let sampleFormat: String
    @objc public let bitRate: Int
    @objc public let sampleRate: Int
    @objc public let channels: Int
    @objc public let channelLayout: String
    @objc public let durationMillis: Int64

    init(
        index: Int,
        codec: String,
        codecTag: String,
        sampleFormat: String,
        bitRate: Int,
        sampleRate: Int,
        channels: Int,
        channelLayout: String,
        durationMillis: Int64
    ) {
        self.index = index
        self.codec = codec
        self.codecTag = codecTag
        self.sampleFormat = sampleFormat
        self.bitRate = bitRate
        self.sampleRate = sampleRate
        self.channels = channels
        self.channelLayout = channelLayout
        self.durationMillis = durationMillis
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? TruvideoSdkVideoAudioTrackInformation else { return false }

        return self.codec == other.codec &&
            self.codecTag == other.codecTag &&
            self.sampleFormat == other.sampleFormat &&
            self.sampleRate == other.sampleRate &&
            self.channels == other.channels &&
            self.channelLayout == other.channelLayout
    }
}

@objc public class TruvideoSdkVideoInformation: NSObject {
    @objc public let path: String
    @objc public let size: Int64
    @objc public let durationMillis: Int64
    @objc public let format: String
    @objc public let videoTracks: [TruvideoSdkVideoTrackInformation]
    @objc public let audioTracks: [TruvideoSdkVideoAudioTrackInformation]

    let url: URL
    let orientation: Orientation
    let videoSize: CGSize

    var videoCodec: String {
        guard let firstVideo = videoTracks.first else {
            return ""
        }
        return firstVideo.codec
    }

    var audioCodec: String {
        guard let firstAudio = audioTracks.first else {
            return ""
        }
        return firstAudio.codec
    }

    var audioSampleRates: Double {
        guard let firstAudio = audioTracks.first else {
            return 0
        }
        return Double(firstAudio.sampleRate)
    }

    var frameRate: TruvideoSdkVideoFrameRate {
        guard let firstVideo = videoTracks.first else {
            return .unknown
        }
        return .getValue(from: firstVideo.frameRate)
    }

    var hasAudio: Bool {
        !audioTracks.isEmpty
    }

    var rotation: Int {
        guard let firstVideo = videoTracks.first else {
            return 0
        }
        return firstVideo.rotation
    }

    enum Orientation {
        case portrait
        case landscape
    }

    init(
        url: URL,
        size: Int64,
        durationMillis: Int64,
        format: String,
        videoTracks: [TruvideoSdkVideoTrackInformation],
        audioTracks: [TruvideoSdkVideoAudioTrackInformation],
        orientation: Orientation,
        videoSize: CGSize
    ) {
        self.url = url
        self.path = url.absoluteString
        self.size = size
        self.durationMillis = durationMillis
        self.format = format
        self.videoTracks = videoTracks
        self.audioTracks = audioTracks
        self.orientation = orientation
        self.videoSize = videoSize
    }
}
