//
//  FFMPEGCommandGeneratorTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 13/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class FFMPEGCommandGeneratorTests: XCTestCase {
    func test_commandGenerator_generatesExpectedConcatCommand_whenPassingFilesWithSameConfig() async throws {
        try await concat(
            commandLines: [
                "-y -f concat -safe 0 -i {inputFile} -c copy \"{output}\""
            ],
            firstVideo: .init(
                url: getTestVideoURL(),
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 10, height: 20)
            ),
            secondVideo: .init(
                url: getTestVideoURL(),
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 10, height: 20)
            ),
            commandGenerator: .init()
        )
    }

    func test_commandGenerator_generatesExpectedEditCommand_whitPassedValues() {
        let sut = FFMPEGCommandGenerator()
        let inputURL = TruvideoSdkVideoUtils.outputURL(for: "input", fileExtension: "mov")
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: "output", fileExtension: "mov")
        let trimCommand = sut.generateEditCommand(
            inputFile: inputURL,
            trimStart: 3,
            trimEnd: 10,
            rotationAngle: 180,
            volumenLevel: 0.75,
            outputFile: outputURL
        )

        let commandStructure =
            """
            -y -i "{inputFile}" -ss {trimStart} -to {trimEnd} -c:v copy -c:a aac {rotationMetadata} {volumeCommand} -preset superfast "{outputFile}"
            """
        let rotationMetadata = "-metadata:s:v:0 rotate=180"
        let volumeCommand = "-af \"volume=0.75\""

        let command = commandStructure
            .replacingOccurrences(of: "{inputFile}", with: inputURL.path)
            .replacingOccurrences(of: "{trimStart}", with: "3.0000")
            .replacingOccurrences(of: "{trimEnd}", with: "10.0000")
            .replacingOccurrences(of: "{rotationMetadata}", with: rotationMetadata)
            .replacingOccurrences(of: "{volumeCommand}", with: volumeCommand)
            .replacingOccurrences(of: "{outputFile}", with: outputURL.path)

        XCTAssertEqual(command, trimCommand.script)
    }

    func test_commandGenerator_generatesExpectedEditThumbnailCommand_whitPassedValues() {
        let sut = FFMPEGCommandGenerator()
        let inputURL = TruvideoSdkVideoUtils.outputURL(for: "input", fileExtension: "mov")
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: "output", fileExtension: "mov")
        let trimCommand = sut.generateThumbnailForTrim(
            video: inputURL,
            interval: 2,
            width: 1,
            height: 1,
            outputPath: outputURL.path
        )

        let commandStructure =
            """
             -sseof {trimStart} -i "{inputFile}" -vframes 1 -vf scale=1:1 "{outputFile}"
            """
        let command = commandStructure
            .replacingOccurrences(of: "{inputFile}", with: inputURL.path)
            .replacingOccurrences(of: "{outputFile}", with: outputURL.path)
            .replacingOccurrences(of: "{trimStart}", with: "-2.0")

        XCTAssertEqual(command, trimCommand.script)
    }

    func test_commandGenerator_generatesValidCommandForVideoEncoding_withDifferentInputs() {
        let videoInfo: TruvideoSdkVideoInformation = .init(
            url: TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov"),
            size: 10,
            durationMillis: 10,
            format: "format_name",
            videoTracks: [.fixture(codec: "h264", pixelFormat: "")],
            audioTracks: [.fixture(codec: "aac")],
            orientation: .landscape,
            videoSize: .init(width: 1080, height: 1920)
        )

        encode(
            commandLines: [
                "-y -i \"{input}\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[v_track0_video0]concat=n=1:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[a_track0_audio0]concat=n=1:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 30 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{output}\""
            ],
            video: videoInfo,
            commandGenerator: .init(),
            width: 150,
            height: 150,
            framesRate: .thirtyFps,
            outputURL: TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        )

        encode(
            commandLines: [
                "-y -i \"{input}\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[v_track0_video0]concat=n=1:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[a_track0_audio0]concat=n=1:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 30 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{output}\""
            ],
            video: videoInfo,
            commandGenerator: .init(),
            width: 150,
            height: 150,
            framesRate: .thirtyFps,
            outputURL: TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mp4")
        )

        encode(
            commandLines: [
                "-y -i \"{input}\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[v_track0_video0]concat=n=1:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[a_track0_audio0]concat=n=1:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{output}\""
            ],
            video: videoInfo,
            commandGenerator: .init(),
            width: 150,
            height: 150,
            framesRate: .twentyFourFps,
            outputURL: TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mp4")
        )

        encode(
            commandLines: [
                "-y -i \"{input}\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[v_track0_video0]concat=n=1:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[a_track0_audio0]concat=n=1:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 60 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{output}\""
            ],
            video: videoInfo,
            commandGenerator: .init(),
            width: 150,
            height: 150,
            framesRate: .sixtyFps,
            outputURL: TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mp4")
        )
    }

    private func concat(
        commandLines: [String],
        firstVideo: TruvideoSdkVideoInformation,
        secondVideo: TruvideoSdkVideoInformation,
        commandGenerator: FFMPEGCommandGenerator,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let expectedCommandStructure = commandLines.reduce("") { partialResult, nextLine in
            "\(partialResult)\(nextLine)"
        }

        let inputFile = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "txt")
        let outputFile = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "move")
        let expectedCommand = expectedCommandStructure
            .replacingOccurrences(of: "{inputFile}", with: inputFile.path)
            .replacingOccurrences(of: "{output}", with: outputFile.path)
        let command = commandGenerator.generateConcatCommandFor(
            videosInfo: [firstVideo, secondVideo],
            inputPath: inputFile,
            outputPath: outputFile.path
        )
        XCTAssertEqual(command.script, expectedCommand, file: file, line: line)
    }

    private func encode(
        commandLines: [String],
        video: TruvideoSdkVideoInformation,
        commandGenerator: FFMPEGMergeCommandGenerator,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        videoTracks: [TruvideoSdkVideoMergeVideoTrack] = [.fixture()],
        audioTracks: [TruvideoSdkVideoMergeAudioTrack] = [.fixture()],
        framesRate: TruvideoSdkVideoFrameRate = .thirtyFps,
        outputURL: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let command = commandGenerator.generateCommand(
            videosInfo: [video],
            videoTracks: videoTracks,
            audioTracks: audioTracks,
            framesRate: framesRate,
            outputPath: outputURL.path
        )
        let expectedCommandStructure = commandLines.reduce("") { partialResult, nextLine in
            "\(partialResult)\(nextLine)"
        }
        let expectedCommand = expectedCommandStructure
            .replacingOccurrences(of: "{input}", with: video.url.absoluteString)
            .replacingOccurrences(of: "{output}", with: outputURL.path)
        XCTAssertEqual(expectedCommand, command.script, file: file, line: line)
    }
}
