//
//  FFMPEGMergeCommandGenerator.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 8/6/24.
//

import Foundation

struct VideoTrack {
    let width: Int
    let height: Int
    let tracks: [VideoItem]
}

struct VideoItem {
    let videoInfo: TruvideoSdkVideoInformation
    let trackInfo: TruvideoSdkVideoTrackInformation?
}

struct AudioTrack {
    let tracks: [AudioItem]
}

struct AudioItem {
    let videoInfo: TruvideoSdkVideoInformation
    let trackInfo: TruvideoSdkVideoAudioTrackInformation?
}

final class FFMPEGMergeCommandGenerator {
    func generateCommand(
        videosInfo: [TruvideoSdkVideoInformation],
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        videoTracks: [TruvideoSdkVideoMergeVideoTrack],
        audioTracks: [TruvideoSdkVideoMergeAudioTrack],
        framesRate: TruvideoSdkVideoFrameRate,
        outputPath: String
    ) -> FFMPEGCommand {
        let newWidth: Int? = width.map { Int($0) }
        let newHeight: Int? = height.map { Int($0) }

        let effectiveVideoTracks = convertVideoInput(
            videosInfo: videosInfo,
            data: videoTracks,
            width: newWidth,
            height: newHeight
        )
        let effectiveAudioTracks = convertAudioInput(
            videosInfo: videosInfo,
            data: audioTracks
        )

        guard !effectiveVideoTracks.isEmpty || !effectiveAudioTracks.isEmpty else {
            return .init(script: "", inputFilesListFilePaths: [])
        }

        var command = "-y " // Overwrite output file if it exists

        // Add inputs and select the first video and audio stream from each file
        let inputPaths = videosInfo.map(\.path)
        for file in inputPaths {
            command += "-i \(file.ffmpegFormatted()) "
        }

        var filterParts = [String]()

        // Video tracks
        var outVideos = [String]()
        for (videoTrackIndex, videoTrack) in effectiveVideoTracks.enumerated() {
            var videoCounter = 0
            var videoTrackDuration: Int64 = 0
            var videoTrackNames = [String]()

            let effectiveWidth = videoTrack.width
            let effectiveHeight = videoTrack.height

            for entry in videoTrack.tracks {
                let track = entry.trackInfo
                let videoInfo = entry.videoInfo
                let fileIndex = inputPaths.firstIndex(of: entry.videoInfo.path) ?? -1

                if let track {
                    let videoIndex = videoInfo.videoTracks.firstIndex { $0.index == track.index } ?? -1
                    let trackName = "[v_track\(videoTrackIndex)_video\(videoCounter)]"
                    videoTrackNames.append(trackName)

                    let scale = "'if(gt(iw/ih,\(effectiveWidth)/\(effectiveHeight)),\(effectiveWidth),-2)':'if(gt(iw/ih,\(effectiveWidth)/\(effectiveHeight)),-2,\(effectiveHeight))'"
                    let pad = "\(effectiveWidth):\(effectiveHeight):(ow-iw)/2:(oh-ih)/2"
                    filterParts.append("[\(fileIndex):v:\(videoIndex)]scale=\(scale),pad=\(pad),setsar=1\(trackName)")
                    videoCounter += 1
                    videoTrackDuration += track.durationMillis

                    // rest
                    let rest = videoInfo.durationMillis - track.durationMillis
                    if rest > 0 {
                        let restTrackName = "[v_track\(videoTrackIndex)_video\(videoCounter)]"
                        videoTrackNames.append(restTrackName)

                        filterParts
                            .append("color=c=black:s=\(effectiveWidth)x\(effectiveHeight):d=\(rest)ms\(restTrackName)")
                        videoCounter += 1
                        videoTrackDuration += rest
                    }
                } else {
                    let trackName = "[v_track\(videoTrackIndex)_video\(videoCounter)]"
                    videoTrackNames.append(trackName)

                    filterParts
                        .append(
                            "color=c=black:s=\(effectiveWidth)x\(effectiveHeight):d=\(videoInfo.durationMillis)ms\(trackName)"
                        )
                    videoCounter += 1
                    videoTrackDuration += videoInfo.durationMillis
                }
            }

            if !videoTrackNames.isEmpty {
                let count = videoTrackNames.count
                let name = "[v_track\(videoTrackIndex)]"
                outVideos.append(name)
                filterParts.append("\(videoTrackNames.joined())concat=n=\(count):v=1:a=0\(name)")
            }
        }

        // Audio tracks
        var outAudios = [String]()
        for (audioTrackIndex, audioTrack) in effectiveAudioTracks.enumerated() {
            var audioCounter = 0
            var audioTrackDuration: Int64 = 0
            var audioTrackNames = [String]()

            for entry in audioTrack.tracks {
                let track = entry.trackInfo
                let videoInfo = entry.videoInfo
                let fileIndex = inputPaths.firstIndex(of: entry.videoInfo.path) ?? -1

                if let track {
                    let audioIndex = videoInfo.audioTracks.firstIndex { $0.index == track.index } ?? -1
                    let trackName = "[a_track\(audioTrackIndex)_audio\(audioCounter)]"
                    audioTrackNames.append(trackName)

                    filterParts
                        .append(
                            "[\(fileIndex):a:\(audioIndex)]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo\(trackName)"
                        )
                    audioCounter += 1
                    audioTrackDuration += track.durationMillis

                    // rest
                    let rest = videoInfo.durationMillis - track.durationMillis
                    if rest > 0 {
                        let restTrackName = "[a_track\(audioTrackIndex)_audio\(audioCounter)]"
                        audioTrackNames.append(restTrackName)

                        let tempTrackName = "[a_track\(audioTrackIndex)_audio\(audioCounter)_rest]"
                        filterParts.append("aevalsrc=0:s=44100:d=\(rest)ms\(tempTrackName)")
                        filterParts
                            .append(
                                "\(tempTrackName)aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo\(restTrackName)"
                            )
                        audioCounter += 1
                        audioTrackDuration += rest
                    }
                } else {
                    let trackName = "[a_track\(audioTrackIndex)_audio\(audioCounter)]"
                    audioTrackNames.append(trackName)

                    let tempTrackName = "[a_track\(audioTrackIndex)_audio\(audioCounter)_rest]"
                    filterParts.append("aevalsrc=0:s=44100:d=\(videoInfo.durationMillis)ms\(tempTrackName)")
                    filterParts
                        .append(
                            "\(tempTrackName)aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo\(trackName)"
                        )
                    audioCounter += 1
                    audioTrackDuration += videoInfo.durationMillis
                }
            }

            if !audioTrackNames.isEmpty {
                let count = audioTrackNames.count
                let name = "[a_track\(audioTrackIndex)]"
                outAudios.append(name)
                filterParts.append("\(audioTrackNames.joined())concat=n=\(count):v=0:a=1\(name)")
            }
        }

        if !filterParts.isEmpty {
            command += "-filter_complex \"\(filterParts.joined(separator: ";"))\" "
        }

        for outVideo in outVideos {
            command += "-map \"\(outVideo)\" "
            command += "-c:v mpeg4 "
            command += "-pix_fmt yuv420p -r \(framesRate.rawValue) "
        }

        for outAudio in outAudios {
            command += "-map \"\(outAudio)\" "
            command += "-c:a aac -ar 44100 -ac 2 "
        }

        command += "-preset medium  "
        command += "\(outputPath.ffmpegFormatted())"

        return .init(script: command, inputFilesListFilePaths: [])
    }

    private func calculateMaxSize(
        widths: [Int],
        heights: [Int],
        streamMaxWidth: Int? = nil,
        streamMaxHeight: Int? = nil
    ) -> CGSize {
        let maxWidth: Int
        let maxHeight: Int

        if let streamMaxWidth, let streamMaxHeight {
            maxWidth = streamMaxWidth
            maxHeight = streamMaxHeight
        } else {
            guard let currentMaxWidth = widths.max(), let currentMaxHeight = heights.max() else {
                return .zero
            }

            if let streamMaxWidth {
                maxWidth = streamMaxWidth
                maxHeight = (streamMaxWidth * currentMaxHeight) / currentMaxWidth
            } else if let streamMaxHeight {
                maxWidth = (streamMaxHeight * currentMaxWidth) / currentMaxHeight
                maxHeight = streamMaxHeight
            } else {
                maxWidth = currentMaxWidth
                maxHeight = currentMaxHeight
            }
        }

        return CGSize(width: maxWidth, height: maxHeight)
    }

    private func convertVideoInput(
        videosInfo: [TruvideoSdkVideoInformation],
        data: [TruvideoSdkVideoMergeVideoTrack],
        width: Int?,
        height: Int?
    ) -> [VideoTrack] {
        var result = [VideoTrack]()

        if data.isEmpty {
            let maxVideoCount = videosInfo.map(\.videoTracks.count).max() ?? 0
            for videoTrackIndex in 0 ..< maxVideoCount {
                let tracks = videosInfo.map {
                    let trackInfo = $0.videoTracks.indices.contains(videoTrackIndex) ? $0
                        .videoTracks[videoTrackIndex] : nil
                    return VideoItem(videoInfo: $0, trackInfo: trackInfo)
                }
                if !tracks.isEmpty {
                    let size = calculateMaxSize(
                        widths: tracks.compactMap { $0.trackInfo?.rotatedWidth },
                        heights: tracks.compactMap { $0.trackInfo?.rotatedHeight },
                        streamMaxWidth: width,
                        streamMaxHeight: height
                    )
                    result.append(VideoTrack(width: Int(size.width), height: Int(size.height), tracks: tracks))
                }
            }
        } else {
            for item in data {
                let tracks: [VideoItem] = item.tracks.compactMap { track in
                    guard let videoInfo = videosInfo.indices
                        .contains(track.fileIndex) ? videosInfo[track.fileIndex] : nil else {
                        return nil
                    }

                    let trackInfo = videoInfo.videoTracks.first { $0.index == track.entryIndex }
                    return VideoItem(videoInfo: videoInfo, trackInfo: trackInfo)
                }
                if !tracks.isEmpty {
                    let size = calculateMaxSize(
                        widths: tracks.compactMap { $0.trackInfo?.rotatedWidth },
                        heights: tracks.compactMap { $0.trackInfo?.rotatedHeight },
                        streamMaxWidth: item.width ?? width,
                        streamMaxHeight: item.height ?? height
                    )

                    result.append(VideoTrack(width: Int(size.width), height: Int(size.height), tracks: tracks))
                }
            }
        }
        return result
    }

    private func convertAudioInput(
        videosInfo: [TruvideoSdkVideoInformation],
        data: [TruvideoSdkVideoMergeAudioTrack]
    ) -> [AudioTrack] {
        var result = [AudioTrack]()

        if data.isEmpty {
            let maxCount = videosInfo.map(\.audioTracks.count).max() ?? 0
            for i in 0 ..< maxCount {
                let tracks: [AudioItem] = videosInfo.map { videoInfo in
                    let trackInfo = videoInfo.audioTracks.indices.contains(i) ? videoInfo.audioTracks[i] : nil
                    return AudioItem(videoInfo: videoInfo, trackInfo: trackInfo)
                }

                if !tracks.isEmpty {
                    result.append(AudioTrack(tracks: tracks))
                }
            }
        } else {
            for item in data {
                let tracks: [AudioItem] = item.tracks.compactMap { track in
                    guard let videoInfo = videosInfo.indices
                        .contains(track.fileIndex) ? videosInfo[track.fileIndex] : nil else {
                        return nil
                    }

                    let trackInfo = videoInfo.audioTracks.first { $0.index == track.entryIndex }
                    return AudioItem(videoInfo: videoInfo, trackInfo: trackInfo)
                }

                if !tracks.isEmpty {
                    result.append(AudioTrack(tracks: tracks))
                }
            }
        }

        return result
    }
}
