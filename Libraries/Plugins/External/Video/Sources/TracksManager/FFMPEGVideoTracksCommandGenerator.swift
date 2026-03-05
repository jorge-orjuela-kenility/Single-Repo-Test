//
//  FFMPEGVideoTracksCommandGenerator.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 8/12/24.
//

import Foundation

class FFMPEGVideoTracksCommandGenerator {
    func createVideoTrackCommand(
        tempURL: URL,
        duration: Int64,
        width: Int,
        height: Int
    ) -> String {
        let durationSeconds = Float(duration) / 1000
        let command = "-y -f lavfi -i color=c=red:s=\(width)x\(height):d=\(durationSeconds) -vf \"format=yuv420p\" -c:v mpeg4 -r 30 -g 30 -b:v 500k \(tempURL.path.ffmpegFormatted())"
        return command
    }

    func createAudioTrackCommand(
        tempURL: URL,
        duration: Int64
    ) -> String {
        let durationSeconds = Float(duration) / 1000
        let command = "-y -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100:duration=\(durationSeconds) -c:a aac \(tempURL.path.ffmpegFormatted())"
        return command
    }

    func generateAddVideoTrackCommand(
        inputPath: String,
        tempPath: String,
        outputPath: String
    ) -> String {
        let command = "-y -i \(inputPath.ffmpegFormatted()) -i \(tempPath.ffmpegFormatted()) -map 0:v -map 0:a -map 1:v -c:v copy -c:a copy \(outputPath.ffmpegFormatted())"
        return command
    }

    func generateAddAudioTrackCommand(
        inputPath: String,
        tempPath: String,
        outputPath: String
    ) -> String {
        let command = "-y -i \(inputPath.ffmpegFormatted()) -i \(tempPath.ffmpegFormatted()) -map 0:v -map 0:a -map 1:a -c:v copy -c:a copy \(outputPath.ffmpegFormatted())"
        return command
    }

    func generateRemoveVideoTrackCommand(
        inputPath: URL,
        outputPath: URL
    ) -> String {
        let command = "-y -i \(inputPath.path.ffmpegFormatted()) -vn -c:a copy \(outputPath.path.ffmpegFormatted())"
        return command
    }

    func generateRemoveAudioTrackCommand(
        inputPath: URL,
        outputPath: URL
    ) -> String {
        let command = "-y -i \(inputPath) -an -c:v copy \(outputPath)"
        return command
    }
}
