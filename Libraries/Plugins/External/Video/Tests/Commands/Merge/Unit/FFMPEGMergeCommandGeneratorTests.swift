//
//  FFMPEGMergeCommandGeneratorTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 13/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class FFMPEGMergeCommandGeneratorTests: XCTestCase {
    var sut: FFMPEGMergeCommandGenerator!

    override func setUp() {
        super.setUp()
        sut = FFMPEGMergeCommandGenerator()
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenPassingTwoVideos() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture()
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(url: .fixture("file://any-url2.com"))
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenPassingThreeVideos() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture()
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(url: .fixture("file://any-url2.com"))
        let thirdVidelInfo: TruvideoSdkVideoInformation = .fixture(url: .fixture("file://any-url3.com"))
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -i \"file://any-url3.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[2:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video2];[v_track0_video0][v_track0_video1][v_track0_video2]concat=n=3:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[2:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio2];[a_track0_audio0][a_track0_audio1][a_track0_audio2]concat=n=3:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo, thirdVidelInfo],
            videoTracks: [],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenPassingTwoVideosWithMultipleVideoTracks() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            videoTracks: [.fixture(), .fixture(index: 1)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            videoTracks: [.fixture(), .fixture(index: 1)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track1_video0];[1:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track1_video1];[v_track1_video0][v_track1_video1]concat=n=2:v=1:a=0[v_track1];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[v_track1]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenPassingTwoVideosWithMultipleAudioTracks() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0];[0:a:1]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track1_audio0];[1:a:1]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track1_audio1];[a_track1_audio0][a_track1_audio1]concat=n=2:v=0:a=1[a_track1]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -map \"[a_track1]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenPassingTwoVideosWithMultipleVideoAndAudioTracks() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            videoTracks: [.fixture(), .fixture(index: 1)],
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            videoTracks: [.fixture(), .fixture(index: 1)],
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track1_video0];[1:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track1_video1];[v_track1_video0][v_track1_video1]concat=n=2:v=1:a=0[v_track1];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0];[0:a:1]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track1_audio0];[1:a:1]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track1_audio1];[a_track1_audio0][a_track1_audio1]concat=n=2:v=0:a=1[a_track1]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[v_track1]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -map \"[a_track1]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenSelectingFirstVideoTrack() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            videoTracks: [.fixture(), .fixture(index: 1)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            videoTracks: [.fixture(), .fixture(index: 1)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [.fixture(tracks: [.fixture(), .fixture(fileIndex: 1)])],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenSelectingSecondVideoTrack() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            videoTracks: [.fixture(), .fixture(index: 1)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            videoTracks: [.fixture(), .fixture(index: 1)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [.fixture(tracks: [
                .fixture(fileIndex: 0, entryIndex: 1),
                .fixture(fileIndex: 1, entryIndex: 1)
            ])],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenSelectingFirstAudioTrack() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [],
            audioTracks: [.fixture(tracks: [.fixture(), .fixture(fileIndex: 1)])],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenSelectingSecondAudioTrack() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            audioTracks: [.fixture(), .fixture(index: 1)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:a:1]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:1]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [],
            audioTracks: [.fixture(tracks: [
                .fixture(fileIndex: 0, entryIndex: 1),
                .fixture(fileIndex: 1, entryIndex: 1)
            ])],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesCorrectMergeCommand_whenSelectingMultipleVideoAndAudioTrack() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture(
            videoTracks: [.fixture(), .fixture(index: 1), .fixture(index: 2)],
            audioTracks: [.fixture(), .fixture(index: 1), .fixture(index: 2)]
        )
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            videoTracks: [.fixture(), .fixture(index: 1), .fixture(index: 2)],
            audioTracks: [.fixture(), .fixture(index: 1), .fixture(index: 2)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:v:1]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track1_video0];[1:v:2]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track1_video1];[v_track1_video0][v_track1_video1]concat=n=2:v=1:a=0[v_track1];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0];[0:a:2]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track1_audio0];[1:a:1]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track1_audio1];[a_track1_audio0][a_track1_audio1]concat=n=2:v=0:a=1[a_track1]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[v_track1]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -map \"[a_track1]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let videoTracks: [TruvideoSdkVideoMergeVideoTrack] = [
            .fixture(tracks: [
                .fixture(fileIndex: 0, entryIndex: 0),
                .fixture(fileIndex: 1, entryIndex: 1),
                .fixture(fileIndex: 2, entryIndex: 2)
            ]),
            .fixture(tracks: [
                .fixture(fileIndex: 0, entryIndex: 1),
                .fixture(fileIndex: 1, entryIndex: 2),
                .fixture(fileIndex: 2, entryIndex: 2)
            ])
        ]
        let audioTracks: [TruvideoSdkVideoMergeAudioTrack] = [
            .fixture(tracks: [
                .fixture(fileIndex: 0, entryIndex: 0),
                .fixture(fileIndex: 1, entryIndex: 0),
                .fixture(fileIndex: 2, entryIndex: 1)
            ]),
            .fixture(tracks: [
                .fixture(fileIndex: 0, entryIndex: 2),
                .fixture(fileIndex: 1, entryIndex: 1),
                .fixture(fileIndex: 2, entryIndex: 2)
            ])
        ]
        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: videoTracks,
            audioTracks: audioTracks,
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesExpectedMergeCommand_whenUsignVideosWithSameOrientationAndDifferentSize() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture()
        let secondVidelInfo: TruvideoSdkVideoInformation = .fixture(
            url: .fixture("file://any-url2.com"),
            videoTracks: [.fixture(width: 500, height: 500)]
        )
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -i \"file://any-url2.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,500/500),500,-2)':'if(gt(iw/ih,500/500),-2,500)',pad=500:500:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[1:v:0]scale='if(gt(iw/ih,500/500),500,-2)':'if(gt(iw/ih,500/500),-2,500)',pad=500:500:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video1];[v_track0_video0][v_track0_video1]concat=n=2:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio1];[a_track0_audio0][a_track0_audio1]concat=n=2:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo, secondVidelInfo],
            videoTracks: [],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }

    func test_commandGenerator_generatesExpectedMergeCommand_whenPassingOneVideo() {
        let firstVideoInfo: TruvideoSdkVideoInformation = .fixture()
        let outputPath = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov").path

        let expectedCommand = "-y -i \"file://any-url.com\" -filter_complex \"[0:v:0]scale='if(gt(iw/ih,200/200),200,-2)':'if(gt(iw/ih,200/200),-2,200)',pad=200:200:(ow-iw)/2:(oh-ih)/2,setsar=1[v_track0_video0];[v_track0_video0]concat=n=1:v=1:a=0[v_track0];[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a_track0_audio0];[a_track0_audio0]concat=n=1:v=0:a=1[a_track0]\" -map \"[v_track0]\" -c:v mpeg4 -pix_fmt yuv420p -r 24 -map \"[a_track0]\" -c:a aac -ar 44100 -ac 2 -preset medium  \"{outputPath}\""
            .replacingOccurrences(of: "{outputPath}", with: outputPath)

        let receivedCommand = sut.generateCommand(
            videosInfo: [firstVideoInfo],
            videoTracks: [],
            audioTracks: [],
            framesRate: .twentyFourFps,
            outputPath: outputPath
        )

        XCTAssertEqual(expectedCommand, receivedCommand.script)
    }
}
