//
//  TruvideoFileProcessor.swift
//  TruvideoSdkNoiseCancelling
//
//  Created by Luis Francisco Piura Mejia on 19/10/23.
//

import AudioToolbox
import AVFoundation
import Foundation

/// An `TruvideoFileProcessor` is a processor in charge to prepare the
/// inputs and outputs for noise cancellation
final class TruvideoFileProcessor {
    /// Merges the video file with clean audio
    /// - Parameters:
    ///   - videoUrl: Video URL
    ///   - audioUrl: Clean audio URL
    /// - Returns: Returns the URL of the new video
    func mergeVideoWithAudio(videoURL: URL, audioURL: URL, outputURL: URL) async throws -> URL {
        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction = AVMutableVideoCompositionInstruction()

        let aVideoAsset = AVAsset(url: videoURL)
        let aAudioAsset = AVAsset(url: audioURL)

        guard
            let videoTrack = mixComposition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let audioTrack = mixComposition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let aVideoAssetTrack = try await aVideoAsset.loadTracks(withMediaType: .video).first,
            let aAudioAssetTrack = try await aAudioAsset.loadTracks(withMediaType: .audio).first,
            let exportSession = AVAssetExportSession(
                asset: mixComposition,
                presetName: AVAssetExportPresetHighestQuality
            )
        else {
            throw TruvideoSdkVideoError.unableToProcessOutput
        }

        mutableCompositionVideoTrack.append(videoTrack)
        mutableCompositionAudioTrack.append(audioTrack)

        do {
            try await mutableCompositionVideoTrack.first?.insertTimeRange(
                CMTimeRangeMake(
                    start: CMTime.zero,
                    duration: aVideoAssetTrack.load(.timeRange).duration
                ),
                of: aVideoAssetTrack,
                at: CMTime.zero
            )
            try await mutableCompositionAudioTrack.first?.insertTimeRange(
                CMTimeRangeMake(
                    start: CMTime.zero,
                    duration: aVideoAssetTrack.load(.timeRange).duration
                ),
                of: aAudioAssetTrack,
                at: CMTime.zero
            )
            videoTrack.preferredTransform = try await aVideoAssetTrack.load(.preferredTransform)

        } catch {
            Logger.logError(event: .mergeVideoAndAudioFailed, eventMessage: .mergeVideoAndAudioFailed(error: error))
            throw TruvideoSdkVideoError.unableToProcessOutput
        }

        totalVideoCompositionInstruction.timeRange = try await CMTimeRangeMake(
            start: CMTime.zero, duration: aVideoAssetTrack.load(.timeRange).duration
        )

        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        await exportSession.export()
        return outputURL
    }

    /// Removes the file from the file system
    /// - Parameter path: file path
    func removeFile(at path: URL) {
        try? FileManager.default.removeItem(atPath: path.path)
    }
}
