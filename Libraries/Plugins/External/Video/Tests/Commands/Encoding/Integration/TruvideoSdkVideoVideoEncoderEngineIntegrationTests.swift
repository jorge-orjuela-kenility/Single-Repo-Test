//
//  TruvideoSdkVideoVideoEncoderEngineIntegrationTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 16/2/24.
//

@testable import TruvideoSdkVideo
import XCTest

final class TruvideoSdkVideoVideoEncoderEngineIntegrationTests: XCTestCase {
    func test_encodesVideo_basedOnReceivedParameters() async throws {
        try await assertEncode(
            encodingWidth: 540,
            inputVideoWidth: 1080,
            inputVideoHeight: 1920,
            videoTracks: [.fixture()],
            audioTracks: [0],
            framesRate: .sixtyFps,
            expectedWidth: 540,
            expectedHeight: 960,
            expectedFrameRate: .sixtyFps
        )
        try await assertEncode(
            encodingWidth: 150,
            encodingHeight: 150,
            inputVideoWidth: 1080,
            inputVideoHeight: 1920,
            videoTracks: [.fixture()],
            audioTracks: [0],
            framesRate: .fiftyFps,
            expectedWidth: 150,
            expectedHeight: 150,
            expectedFrameRate: .fiftyFps
        )
        try await assertEncode(
            encodingWidth: 1080,
            encodingHeight: 1920,
            inputVideoWidth: 150,
            inputVideoHeight: 150,
            videoTracks: [.fixture()],
            audioTracks: [0],
            framesRate: .thirtyFps,
            expectedWidth: 1080,
            expectedHeight: 1920
        )
        try await assertEncode(
            encodingWidth: 960,
            inputVideoWidth: 1920,
            inputVideoHeight: 1080,
            videoTracks: [.fixture()],
            audioTracks: [0],
            framesRate: .twentyFourFps,
            expectedWidth: 960,
            expectedHeight: 540,
            expectedFrameRate: .twentyFourFps
        )
    }

    // MARK: - Helpers

    private func assertEncode(
        encodingWidth: CGFloat? = nil,
        encodingHeight: CGFloat? = nil,
        inputVideoWidth: Int,
        inputVideoHeight: Int,
        videoTracks: [TruvideoSdkVideoEncodeVideoEntry],
        audioTracks: [Int],
        framesRate: TruvideoSdkVideoFrameRate,
        expectedWidth: CGFloat,
        expectedHeight: CGFloat,
        expectedFrameRate: TruvideoSdkVideoFrameRate = .thirtyFps,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let commandExecutor = FFMPEGCommandExecutorImplementation(transformProvider: MockVideoTransformProvider())
        let store = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        let sut = TruvideoSdkVideoVideoEncoderEngine(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true),
            videoValidator: .init(),
            commandExecutor: commandExecutor,
            commandGenerator: .init(),
            store: store
        )
        let videoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(
            in: videoURL,
            width: inputVideoWidth,
            height: inputVideoHeight,
            withAudio: !audioTracks.isEmpty
        )
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        let request = buildEncodingRequest(
            inputFileURL: videoURL,
            width: encodingWidth,
            height: encodingHeight,
            videoTracks: videoTracks,
            audioTracks: audioTracks,
            framesRate: framesRate,
            outputURL: outputURL,
            engine: sut,
            store: store
        )

        let result = try await sut.process(request: request)
        let videoInfo = try await commandExecutor.getMediaInformation(result.videoURL)

        XCTAssertEqual(videoInfo.videoSize.width, expectedWidth, file: file, line: line)
        XCTAssertEqual(videoInfo.videoSize.height, expectedHeight, file: file, line: line)
        XCTAssertEqual(videoInfo.frameRate, expectedFrameRate, file: file, line: line)

        addURLForRemoval(videoURL)
        addURLForRemoval(result.videoURL)
    }

    private func buildEncodingRequest(
        inputFileURL: URL,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        videoTracks: [TruvideoSdkVideoEncodeVideoEntry] = [.fixture()],
        audioTracks: [Int] = [0],
        framesRate: TruvideoSdkVideoFrameRate = .thirtyFps,
        outputURL: URL,
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore
    ) -> TruvideoSdkVideoRequest {
        let builder = EncodingBuilder(
            video: .init(url: inputFileURL),
            output: .custom(rawPath: inputFileURL.deletingPathExtension().path),
            engine: engine,
            store: store
        )

        builder.width = width
        builder.height = height
        builder.framesRate = framesRate
        builder.videoTracks = videoTracks
        builder.audioTracks = audioTracks

        return builder.build()
    }
}
