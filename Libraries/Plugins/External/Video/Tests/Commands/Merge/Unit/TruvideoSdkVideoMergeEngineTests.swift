//
//  TruvideoSdkVideoMergeEngineTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 12/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class TruvideoSdkVideoMergeEngineTests: XCTestCase {
    func test_throwsUserNotAuthenticatedException_whenUserIsNotAuthenticated() async {
        let sut = makeSUT(authenticated: false)
        guard let firstVideo = try? await getTestVideoURL(),
              let secondVideo = try? await getTestVideoURL(),
              let request = try? anyMergeRequest(
                  engine: sut.engine,
                  store: sut.store,
                  withData: .init(
                      videos: [firstVideo, secondVideo],
                      width: 111,
                      height: 111,
                      framesRate: .fiftyFps,
                      videoTracks: [],
                      audioTracks: []
                  )
              ) else {
            XCTFail("Failing at getting test videos' url or request")
            return
        }

        await assertError(
            expectedError: .userNotAuthenticated,
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.engine.process(request: request) }
        )
    }

    func test_throwsInvalidFile_whenOneOrMoreFilesDoNotExist() async throws {
        let sut = makeSUT(authenticated: true)
        let request = try anyMergeRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [anyFileURL(), anyFileURL()],
                width: nil,
                height: nil,
                framesRate: .fiftyFps,
                videoTracks: [],
                audioTracks: []
            )
        )

        await assertError(
            expectedError: .invalidInputFiles(reason: .inputContainsNonExistingFiles),
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.engine.process(request: request) }
        )
    }

    func test_throwsInvalidFile_whenPassingAnEmptyList() async throws {
        let sut = makeSUT(authenticated: true)

        await assertError(
            expectedError: .invalidInputFiles(reason: .notEnoughVideos),
            commandExecutor: sut.commandExecutor,
            on: { _ = try self.anyMergeRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(
                    videos: [],
                    width: nil,
                    height: nil,
                    framesRate: .fiftyFps,
                    videoTracks: [],
                    audioTracks: []
                )
            ) }
        )
    }

    func test_throwsMergeFailed_whenCommandExecutorFails() async throws {
        let sut = makeSUT(authenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyMergeRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo],
                width: nil,
                height: nil,
                framesRate: .fiftyFps,
                videoTracks: [],
                audioTracks: []
            )
        )
        let requestId = request.id

        try await expect(
            request: request,
            commandExecutor: sut.commandExecutor,
            expectedError: .mergeFailed,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            ),
            withCommandFailure: true
        )

        let retrievedRequest = try store.getRequest(withId: requestId)
        XCTAssertEqual(retrievedRequest?.status, .error)
    }

    func test_validatesRequestStatus() async throws {
        let sut = makeSUT(authenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyMergeRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo],
                width: nil,
                height: nil,
                framesRate: .fiftyFps,
                videoTracks: [],
                audioTracks: []
            )
        )
        let requestId = request.id
        try store.updateRequest(withId: requestId, data: .init(fields: [.status(value: .processing)]))

        try await expect(
            request: request,
            commandExecutor: sut.commandExecutor,
            expectedError: .operationStillsInProgress,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )

        let secondRequest = try anyMergeRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo],
                width: nil,
                height: nil,
                framesRate: .fiftyFps,
                videoTracks: [],
                audioTracks: []
            )
        )
        let secondRequestId = secondRequest.id
        try store.updateRequest(withId: secondRequestId, data: .init(fields: [.status(value: .completed)]))

        try await expect(
            request: secondRequest,
            commandExecutor: sut.commandExecutor,
            expectedError: .operationAlreadyCompleted,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )
    }

    func test_cancelThrowsException_whenRequestIsNotProcessing() async throws {
        let sut = makeSUT(authenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyMergeRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo],
                width: nil,
                height: nil,
                framesRate: .fiftyFps,
                videoTracks: [],
                audioTracks: []
            )
        )
        try sut.store.updateRequest(
            withId: request.id,
            data: .init(fields: [.processId(value: "1234")])
        )
        var receivedError = await errorFor(action: {
            try request.cancel()
        })

        var retrievedRequest = try store.getRequest(withId: request.id)
        XCTAssertEqual(sut.commandExecutor.cancelCallCount, 0)
        XCTAssertEqual(retrievedRequest?.status, .idle)
        XCTAssertEqual(receivedError, .operationMustBeProcessingToBeCancelled)

        receivedError = await errorFor(action: {
            try request.cancel()
        })

        try sut.store.updateRequest(
            withId: request.id,
            data: .init(fields: [.status(value: .completed)])
        )
        retrievedRequest = try store.getRequest(withId: request.id)
        XCTAssertEqual(sut.commandExecutor.cancelCallCount, 0)
        XCTAssertEqual(retrievedRequest?.status, .completed)
        XCTAssertEqual(receivedError, .operationMustBeProcessingToBeCancelled)
    }

    func test_cancelsTheRequest_uponCancellation() async throws {
        let sut = makeSUT(authenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyMergeRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo],
                width: nil,
                height: nil,
                framesRate: .fiftyFps,
                videoTracks: [],
                audioTracks: []
            )
        )
        sut.commandExecutor.cancellationBlock = { try request.cancel() }

        let receivedError = await errorFor(action: {
            _ = try await request.process()
        })

        let retrievedRequest = try store.getRequest(withId: request.id)
        XCTAssertEqual(sut.commandExecutor.cancelCallCount, 1)
        XCTAssertEqual(retrievedRequest?.status, .cancelled)
        XCTAssertEqual(receivedError, .mergeFailed)
    }

    func test_throwsInvalidResolution_whenUsingInvalidResolution() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        try await expect(
            request: anyMergeRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(
                    videos: [firstVideo, secondVideo],
                    width: 111,
                    height: nil,
                    framesRate: .fiftyFps,
                    videoTracks: [],
                    audioTracks: []
                )
            ),
            commandExecutor: sut.commandExecutor,
            expectedError: .invalidResolution,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )
        try await expect(
            request: anyMergeRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(
                    videos: [firstVideo, secondVideo],
                    width: 3,
                    height: 111,
                    framesRate: .fiftyFps,
                    videoTracks: [],
                    audioTracks: []
                )
            ),
            commandExecutor: sut.commandExecutor,
            expectedError: .invalidResolution,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )
        try await expect(
            request: anyMergeRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(
                    videos: [firstVideo, secondVideo],
                    width: 0,
                    height: nil,
                    framesRate: .fiftyFps,
                    videoTracks: [],
                    audioTracks: []
                )
            ),
            commandExecutor: sut.commandExecutor,
            expectedError: .invalidResolution,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )
        try await expect(
            request: anyMergeRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(
                    videos: [firstVideo, secondVideo],
                    width: nil,
                    height: 0,
                    framesRate: .fiftyFps,
                    videoTracks: [],
                    audioTracks: []
                )
            ),
            commandExecutor: sut.commandExecutor,
            expectedError: .invalidResolution,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )
    }

    func test_completesSuccessfully_whenUsingVideosWithDifferentAudioLayers() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        try await expect(
            request: anyMergeRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(
                    videos: [firstVideo, secondVideo],
                    width: nil,
                    height: nil,
                    framesRate: .fiftyFps,
                    videoTracks: [],
                    audioTracks: []
                )
            ),
            commandExecutor: sut.commandExecutor,
            expectedError: nil,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )
    }

    func test_storesLocalRequest_onMergeCompletion() async throws {
        let sut = makeSUT(authenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyMergeRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo],
                width: 1200,
                height: 1400,
                framesRate: .fiftyFps,
                videoTracks: [],
                audioTracks: []
            )
        )
        let requestId = request.id

        try await expect(
            request: request,
            commandExecutor: sut.commandExecutor,
            expectedError: nil,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "")],
                orientation: .portrait,
                videoSize: .init(width: 1080, height: 1920)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 1920, height: 1000)
            )
        )

        let retrievedRequest = try store.getRequest(withId: requestId)
        XCTAssertEqual(retrievedRequest?.id, requestId)
        XCTAssertEqual(retrievedRequest?.status, .completed)
    }

    // MARK: - Helpers

    private func makeSUT(authenticated: Bool) -> (
        commandExecutor: MockFFMPEGCommandExecutor,
        engine: TruvideoSdkVideoMergeEngine,
        store: MockVideoStore
    ) {
        let credentialsManager = TruvideoCredentialsManagerSpy(isUserAuthenticated: authenticated)
        let commandExecutor = MockFFMPEGCommandExecutor()
        let store = MockVideoStore()
        let informationGenerator = VideosInformationGenerator(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor
        )
        let sut = TruvideoSdkVideoMergeEngine(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor,
            videosInformationGenerator: informationGenerator,
            store: store
        )

        return (commandExecutor, sut, store)
    }

    private func anyMergeRequest(
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore,
        withData data: TruvideoSdkVideoRequest.VideoMergeData? = nil
    ) throws -> TruvideoSdkVideoRequest {
        let builder = MergeBuilder(
            videos: data?.videos.map { .init(url: $0) } ?? [],
            output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
            engine: engine,
            store: store
        )

        builder.width = data?.width
        builder.height = data?.height
        builder.framesRate = data?.framesRate ?? .thirtyFps
        builder.videoTracks = data?.videoTracks ?? []
        builder.audioTracks = data?.audioTracks ?? []

        return try builder.build()
    }

    private func anyFileURL() -> URL {
        .init(string: "file://any-file.mov")!
    }
}
