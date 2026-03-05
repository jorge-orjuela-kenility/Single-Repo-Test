//
//  FFMPEGCommandGenerator.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 5/12/23.
//

import Foundation

struct FFMPEGCommand {
    let script: String
    let inputFilesListFilePaths: [String]
}

final class FFMPEGCommandGenerator {
    func generateEditCommand(
        inputFile: URL,
        trimStart: TimeInterval,
        trimEnd: TimeInterval,
        rotationAngle: Int,
        volumenLevel: Float,
        outputFile: URL
    ) -> FFMPEGCommand {
        let commandStructure =
            """
            -y -i {inputFile} -ss {trimStart} -to {trimEnd} -c:v copy -c:a aac {rotationMetadata} {volumeCommand} -preset superfast {outputFile}
            """

        let rotationMetadata = "-metadata:s:v:0 rotate=\(rotationAngle.ffmpegFormatted())"
        let volumeCommand = "-af \"volume=\(volumenLevel)\""

        let command = commandStructure
            .replacingOccurrences(of: "{inputFile}", with: inputFile.path.ffmpegFormatted())
            .replacingOccurrences(of: "{trimStart}", with: trimStart.formattedTime())
            .replacingOccurrences(of: "{trimEnd}", with: trimEnd.formattedTime())
            .replacingOccurrences(of: "{rotationMetadata}", with: rotationMetadata)
            .replacingOccurrences(of: "{volumeCommand}", with: volumeCommand)
            .replacingOccurrences(of: "{outputFile}", with: outputFile.path.ffmpegFormatted())

        return .init(script: command, inputFilesListFilePaths: [])
    }

    func generateConcatCommandFor(
        videosInfo: [TruvideoSdkVideoInformation],
        inputPath: URL,
        outputPath: String
    ) -> FFMPEGCommand {
        let inputFilesListFilePath = createConcatCommandInputFile(
            assetsMetadata: videosInfo,
            inputFileURL: inputPath
        )
        let commandStructure = "-y -f concat -safe 0 -i {inputFilesListsPath} -c copy {output}"
        let command = commandStructure
            .replacingOccurrences(of: "{inputFilesListsPath}", with: inputFilesListFilePath)
            .replacingOccurrences(of: "{output}", with: outputPath.ffmpegFormatted())
        return .init(script: command, inputFilesListFilePaths: [inputFilesListFilePath])
    }

    func deleteInputFilesListFile(path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {}
    }

    func generateThumbnailGenerationCommandFor(video: TruvideoSdkVideoThumbnailInputVideo, outputPath: URL) -> String {
        let commandParameters: [Any] = [
            "-i",
            video.input.url,
            "-ss",
            video.position,
            "-vframes",
            "1",
            "-vf",
            "scale=\(video.width ?? -1):\(video.height ?? -1)",
            outputPath.path.ffmpegFormatted()
        ]
        return commandParameters.reduce("") { $0.isEmpty ? "\($1)" : "\($0) \($1)" }
    }

    func generateThumbnailForTrim(
        video: URL,
        interval: TimeInterval,
        width: Int? = nil,
        height: Int? = nil,
        outputPath: String
    ) -> FFMPEGCommand {
        let commandParameters: [Any] = [
            "-sseof",
            "-\(interval)",
            "-i",
            video.path.ffmpegFormatted(),
            "-vframes",
            "1",
            "-vf",
            "scale=\(width ?? -1):\(height ?? -1)",
            outputPath.ffmpegFormatted()
        ]
        return .init(script: commandParameters.reduce("") { "\($0) \($1)" }, inputFilesListFilePaths: [])
    }

    func generateExtractAudioCommandFor(
        videoURL: URL,
        outputPath: URL,
        audioChannels: Int = 1,
        samplingRate: Int = 32000,
        bitRate: Int = 320,
        format: String = "wav"
    ) -> String {
        let commandParameters: [Any] = [
            "-i", videoURL.path.ffmpegFormatted(), "-vn",
            "-ac", audioChannels,
            "-ar", samplingRate,
            "-ab", "\(bitRate)k",
            "-f", format,
            outputPath.path.ffmpegFormatted()
        ]
        return commandParameters.reduce("") { $0.isEmpty ? "\($1)" : "\($0) \($1)" }
    }

    // MARK: - Private methods

    private func createConcatCommandInputFile(
        assetsMetadata: [TruvideoSdkVideoInformation],
        inputFileURL: URL
    ) -> String {
        let content = assetsMetadata.reduce("") {
            "\($0)file \($1.url.path)\n"
        }
        FileManager.default.createFile(atPath: inputFileURL.path, contents: Data(content.utf8))
        return inputFileURL.path
    }
}

private extension CGFloat {
    var ceiledCommand: String {
        "floor(\(self)/2)*2"
    }
}

private extension TimeInterval {
    func formattedTime() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 4
        numberFormatter.maximumFractionDigits = 4
        numberFormatter.decimalSeparator = "."
        return numberFormatter.string(from: .init(value: self)) ?? "0"
    }
}

private extension Int {
    func ffmpegFormatted() -> String {
        switch self {
        case 90, -270, 450:
            "270"
        case 180, -180, 540, -540:
            "180"
        case -90, 270, -450:
            "90"
        default:
            "0"
        }
    }
}
