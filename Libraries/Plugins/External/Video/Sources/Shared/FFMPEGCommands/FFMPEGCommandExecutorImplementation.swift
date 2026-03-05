//
//  FFMPEGCommandExecutorImplementation.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 5/12/23.
//

import AVKit
@_implementationOnly import ffmpegkit
import Foundation

struct ExecutionResult {
    let output: String
}

protocol VideoTransformProvider {
    func getTransform(for url: URL) async throws -> CGAffineTransform
}

class AVAssetVideoTransformProvider: VideoTransformProvider {
    func getTransform(for url: URL) async throws -> CGAffineTransform {
        do {
            let asset = AVAsset(url: url)
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            guard let firstTrack = videoTracks.first else {
                throw TruvideoSdkVideoError.missingVideoTrackToMerge
            }
            return try await firstTrack.load(.preferredTransform)
        } catch {
            throw TruvideoSdkVideoError.missingVideoTrackToMerge
        }
    }
}

final class FFMPEGCommandExecutorImplementation: FFMPEGCommandExecutor {
    private let transformProvider: VideoTransformProvider

    init(transformProvider: VideoTransformProvider = AVAssetVideoTransformProvider()) {
        self.transformProvider = transformProvider
    }

    func cancelCommandExecution(sessionId: Int) {
        FFmpegKit.cancel(sessionId)
    }

    @discardableResult
    func executeFFMPEGCommand(
        _ command: String,
        onUpdateSessionId: ((Int) -> Void)?
    ) async throws -> Result<Void, Error> {
        try await withCheckedThrowingContinuation { continuation in
            let sessionId = FFmpegKit.executeAsync(
                command,
                withCompleteCallback: { session in
                    guard let session, let returnCode = session.getReturnCode() else {
                        return
                    }
                    let sessionState = session.getState()
                    let stateString = FFmpegKitConfig.sessionState(toString: sessionState)

                    if returnCode.isValueSuccess() {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(throwing: NSError(
                            domain: stateString ?? "",
                            code: Int(returnCode.getValue())
                        ))
                    }
                },
                withLogCallback: {
                    print("\(String(describing: $0?.getMessage()))")
                },
                withStatisticsCallback: nil
            ).getId()
            onUpdateSessionId?(sessionId)
        }
    }

    @discardableResult
    func executeFFMPEGProbeCommand(_ command: String) async throws -> ExecutionResult {
        try await withCheckedThrowingContinuation { continuation in
            FFprobeKit.executeAsync(command) { session in
                guard let session, let returnCode = session.getReturnCode() else {
                    return
                }
                let sessionState = session.getState()
                let stateString = FFmpegKitConfig.sessionState(toString: sessionState)

                if returnCode.isValueSuccess() {
                    let output: String = session.getOutput() ?? ""
                    continuation.resume(returning: .init(output: output))
                } else {
                    continuation.resume(throwing: NSError(domain: stateString ?? "", code: Int(returnCode.getValue())))
                }
            }
        }
    }

    private func mapVideoTracks(from streams: [[String: Any]]) -> [TruvideoSdkVideoTrackInformation] {
        let videoStreams = streams.filter {
            ($0["codec_type"] as? String ?? "") == "video"
        }
        return videoStreams.map { stream in
            let duration = Double(stream["duration"] as? String ?? "0") ?? 0.0
            var rotation = 0
            if let sideDataList = stream["side_data_list"] as? [[String: Any]] {
                for sideData in sideDataList {
                    if let rotationAngle = sideData["rotation"] as? Int {
                        rotation = rotationAngle
                    }
                }
            }

            return TruvideoSdkVideoTrackInformation(
                index: stream["index"] as? Int ?? 0,
                width: stream["width"] as? Int ?? 0,
                height: stream["height"] as? Int ?? 0,
                codec: stream["codec_name"] as? String ?? "",
                codecTag: stream["codec_tag_string"] as? String ?? "",
                pixelFormat: stream["pix_fmt"] as? String ?? "",
                bitRate: Int(stream["bit_rate"] as? String ?? "0") ?? 0,
                frameRate: stream["r_frame_rate"] as? String ?? "",
                rotation: rotation,
                durationMillis: Int64(duration * 1000)
            )
        }
    }

    private func mapAudioTracks(from streams: [[String: Any]]) -> [TruvideoSdkVideoAudioTrackInformation] {
        let audioStreams = streams.filter {
            ($0["codec_type"] as? String ?? "") == "audio"
        }
        return audioStreams.map { stream in
            let duration = Double(stream["duration"] as? String ?? "0") ?? 0.0
            return TruvideoSdkVideoAudioTrackInformation(
                index: stream["index"] as? Int ?? 0,
                codec: stream["codec_name"] as? String ?? "",
                codecTag: stream["codec_tag_string"] as? String ?? "",
                sampleFormat: stream["sample_fmt"] as? String ?? "",
                bitRate: Int(stream["bit_rate"] as? String ?? "0") ?? 0,
                sampleRate: Int(stream["sample_rate"] as? String ?? "0") ?? 0,
                channels: stream["channels"] as? Int ?? 0,
                channelLayout: stream["channel_layout"] as? String ?? "",
                durationMillis: Int64(duration * 1000)
            )
        }
    }

    func getMediaInformation(_ url: URL) async throws -> TruvideoSdkVideoInformation {
        let result: ExecutionResult

        do {
            let commandParameters: [Any] = [
                "-i", url.absoluteString.ffmpegFormatted(),
                "-v quiet -print_format json -show_format -show_streams -hide_banner"
            ]
            let command = commandParameters.reduce("") { $0.isEmpty ? "\($1)" : "\($0) \($1)" }

            result = try await executeFFMPEGProbeCommand(command)

        } catch {
            throw TruvideoSdkVideoError.getInformationFailed
        }

        guard
            let jsonData = result.output.data(using: .utf8),
            let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
            let format = jsonDict["format"] as? [String: Any],
            let streams = jsonDict["streams"] as? [[String: Any]]
        else {
            throw TruvideoSdkVideoError.getInformationFailed
        }

        let size = Int64(format["size"] as? String ?? "0") ?? 0
        let duration = Double(format["duration"] as? String ?? "0") ?? 0
        let formatName = format["format_name"] as? String ?? ""

        let videos = mapVideoTracks(from: streams)
        let audios = mapAudioTracks(from: streams)

        var orientation: TruvideoSdkVideoInformation.Orientation = .portrait
        var videoSize: CGSize = .zero

        for video in videos {
            let streamWidth = video.width
            let streamHeight = video.height
            let transform = try await transformProvider.getTransform(for: url)
            let streamSize = CGSize(width: streamWidth, height: streamHeight).applying(transform)
            videoSize = .init(width: abs(streamSize.width), height: abs(streamSize.height))
            orientation = videoSize.width > videoSize.height ? .landscape : .portrait
        }

        return TruvideoSdkVideoInformation(
            url: url,
            size: size,
            durationMillis: Int64(duration * 1000.0),
            format: formatName,
            videoTracks: videos,
            audioTracks: audios,
            orientation: orientation,
            videoSize: videoSize
        )
    }
}
