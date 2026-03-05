//
//  MergeIntegrationTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 13/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class MergeIntegrationTests: XCTestCase {
    func test_merger_generatesVideoOnConcat_withEqualConfiguredVideos() async throws {
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let thirdVideo = try await getTestVideoURL()
        let sut = makeSUT()
        var receivedError: Error?

        do {
            let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
            addURLForRemoval(outputURL)
            let request = try buildConcatRequest(
                outputURL: outputURL,
                videos: [firstVideo, secondVideo, thirdVideo],
                engine: sut.concatEngine,
                store: sut.store
            )
            let result = try await sut.concatEngine.process(request: request)
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.videoURL.path))
        } catch {
            receivedError = error
        }

        XCTAssertNil(receivedError)
    }

    func test_merger_generatesVideoOnMerge_withVideosWithDifferentSizes() async throws {
        let firstVideo = try await getTestVideoURL(width: 10, withAudio: true)
        let secondVideo = try await getTestVideoURL(height: 25, withAudio: true)
        let thirdVideo = try await getTestVideoURL(withAudio: true)
        let sut = makeSUT()
        var receivedError: Error?

        do {
            let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
            addURLForRemoval(outputURL)
            let request = try buildMergeRequest(
                inputPaths: [firstVideo, secondVideo, thirdVideo],
                outputURL: outputURL,
                engine: sut.mergeEngine,
                store: sut.store
            )
            let result = try await sut.mergeEngine.process(request: request)
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.videoURL.path))
        } catch {
            receivedError = error
        }

        XCTAssertNil(receivedError)
    }

    func test_merger_generatesVideoWithSpecifiedCodecsOnMerge_withVideosWithDifferentSizes() async throws {
        try await expectMerge(
            with: [
                getTestVideoURL(width: 848, height: 2040, withAudio: true),
                getTestVideoURL(width: 1080, height: 1946, withAudio: true),
                getTestVideoURL(width: 1200, height: 846, withAudio: true)
            ],
            width: 720,
            expectedWidth: 720,
            expectedHeight: 1224
        )

        try await expectMerge(
            with: [
                getTestVideoURL(width: 1020, height: 2040, withAudio: true),
                getTestVideoURL(width: 1946, height: 1020, withAudio: true),
                getTestVideoURL(width: 848, height: 946, withAudio: true)
            ],
            width: 720,
            height: 760,
            expectedWidth: 720,
            expectedHeight: 760
        )

        try await expectMerge(
            with: [
                getTestVideoURL(width: 1080, height: 1920, withAudio: true),
                getTestVideoURL(width: 1000, height: 1900)
            ],
            expectedWidth: 1080,
            expectedHeight: 1920
        )

        try await expectMerge(
            with: [
                getTestVideoURL(width: 1080, height: 1920, withAudio: true),
                getTestVideoURL(width: 1000, height: 1900)
            ],
            width: 540,
            expectedWidth: 540,
            expectedHeight: 960
        )
    }

    func test_merger_throwsInvalidFile_onGetInfo_whenPassingAnImageAsParameter() async {
        let testsURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "png")
        addURLForRemoval(testsURL)
        let image = UIImage.make(withColor: .black)
        FileManager.default.createFile(
            atPath: testsURL.path,
            contents: image.pngData()!
        )
        let sut = makeSUT()

        let error = await errorFor {
            _ = try await sut.informationGenerator.getVideoInformation(video: testsURL)
        }

        XCTAssertEqual(error, .missingVideoTrackToMerge)
    }

    func test_merger_onGetInfo_generatesValidMetaData() async throws {
        let testsURL = try await getTestVideoURL()
        let sut = makeSUT()

        let result = try await sut.informationGenerator.getVideoInformation(video: testsURL)

        XCTAssertEqual(result.videoCodec, "mpeg4")
        XCTAssertEqual(result.videoSize.width, 20)
        XCTAssertEqual(result.videoSize.height, 20)
        XCTAssertEqual(result.orientation, .portrait)
        XCTAssertFalse(result.hasAudio)
        XCTAssertEqual(result.audioCodec, "")
    }

    private func expectMerge(
        with videos: [URL],
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        videoTracks: [TruvideoSdkVideoMergeVideoTrack] = [],
        audioTracks: [TruvideoSdkVideoMergeAudioTrack] = [],
        expectedWidth: CGFloat,
        expectedHeight: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let sut = makeSUT(transformProvider: MockVideoTransformProvider())
        var videoInfo: TruvideoSdkVideoInformation

        do {
            let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
            let request = try buildMergeRequest(
                inputPaths: videos,
                outputURL: outputURL,
                width: width,
                height: height,
                framesRate: .thirtyFps,
                videoTracks: videoTracks,
                audioTracks: audioTracks,
                engine: sut.mergeEngine,
                store: sut.store
            )
            let result = try await sut.mergeEngine.process(request: request)
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.videoURL.path))
            videoInfo = try await sut.informationGenerator.getVideoInformation(video: result.videoURL)

            XCTAssertEqual(videoInfo.videoSize.width, expectedWidth, file: file, line: line)
            XCTAssertEqual(videoInfo.videoSize.height, expectedHeight, file: file, line: line)
            addURLForRemoval(result.videoURL)
        } catch {
            XCTFail("Merge failed with error \(error)", file: file, line: line)
        }
    }

    // MARK: - Helpers

    private func makeSUT(transformProvider: VideoTransformProvider = AVAssetVideoTransformProvider()) -> (
        mergeEngine: TruvideoSdkVideoMergeEngine,
        concatEngine: TruvideoSdkVideoConcatEngine,
        informationGenerator: VideosInformationGenerator,
        store: VideoStore
    ) {
        let store = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        let credentialsManager = TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        let mergeEngine = TruvideoSdkVideoMergeEngine(
            credentialsManager: credentialsManager,
            store: store
        )
        let concatEngine = TruvideoSdkVideoConcatEngine(
            credentialsManager: credentialsManager,
            store: store
        )
        let informationGenerator = VideosInformationGenerator(
            credentialsManager: credentialsManager,
            commandExecutor: FFMPEGCommandExecutorImplementation(transformProvider: transformProvider)
        )

        return (mergeEngine, concatEngine, informationGenerator, store)
    }

    private func buildConcatRequest(
        outputURL: URL,
        videos: [URL],
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore
    ) throws -> TruvideoSdkVideoRequest {
        let builder = ConcatBuilder(
            videos: videos.map { .init(url: $0) },
            output: .custom(rawPath: outputURL.deletingPathExtension().path),
            engine: engine,
            store: store
        )
        return try builder.build()
    }

    private func buildMergeRequest(
        inputPaths: [URL],
        outputURL: URL,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        framesRate: TruvideoSdkVideoFrameRate = .thirtyFps,
        videoTracks: [TruvideoSdkVideoMergeVideoTrack] = [],
        audioTracks: [TruvideoSdkVideoMergeAudioTrack] = [],
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore
    ) throws -> TruvideoSdkVideoRequest {
        let builder = MergeBuilder(
            videos: inputPaths.map { .init(url: $0) },
            output: .custom(rawPath: outputURL.deletingPathExtension().path),
            engine: engine,
            store: store
        )

        builder.width = width
        builder.height = height
        builder.framesRate = framesRate
        builder.videoTracks = videoTracks
        builder.audioTracks = audioTracks

        return try builder.build()
    }
}
