//
//  TruvideoSdkVideoConcatEngineTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 13/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class TruvideoSdkVideoConcatEngineTests: XCTestCase {
    func test_throwsUserNotAuthenticatedException_whenUserIsNotAuthenticated() async throws {
        let sut = makeSUT(authenticated: false)
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [anyFileURL(), anyFileURL()]
            )
        )

        await assertError(
            expectedError: .userNotAuthenticated,
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.engine.process(request: request) }
        )
    }

    func test_throwsInvalidFile_whenOneOrMoreFilesDoNotExist() async throws {
        let sut = makeSUT(authenticated: true)
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [anyFileURL(), anyFileURL()]
            )
        )

        await assertError(
            expectedError: .invalidInputFiles(reason: .inputContainsNonExistingFiles),
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.engine.process(request: request) }
        )
    }

    func test_throwsNoEnoughFiles_whenPassingLessThanTheAmountOfNeededFiles() async throws {
        let sut = makeSUT(authenticated: true)
        let firstFile = try await getTestVideoURL()

        await assertError(
            expectedError: .invalidInputFiles(reason: .notEnoughVideos),
            commandExecutor: sut.commandExecutor,
            on: { _ = try self.anyConcatRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(videos: [firstFile])
            ) }
        )
    }

    func test_throwsInvalidFile_whenPassingAnEmptyList() async throws {
        let sut = makeSUT(authenticated: true)

        await assertError(
            expectedError: .invalidInputFiles(reason: .notEnoughVideos),
            commandExecutor: sut.commandExecutor,
            on: { _ = try self.anyConcatRequest(
                engine: sut.engine,
                store: sut.store,
                withData: .init(videos: [])
            ) }
        )
    }

    func test_validatesRequestStatus() async throws {
        let sut = makeSUT(authenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let auxVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, auxVideo]
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

        let secondRequest = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, auxVideo]
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
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo]
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
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo]
            )
        )

        sut.commandExecutor.cancellationBlock = { try request.cancel() }

        let receivedError = await errorFor(action: {
            _ = try await request.process()
        })

        let retrievedRequest = try store.getRequest(withId: request.id)
        XCTAssertEqual(sut.commandExecutor.cancelCallCount, 1)
        XCTAssertEqual(retrievedRequest?.status, .cancelled)
        XCTAssertEqual(receivedError, .concatFailed)
    }

    func test_throwsInvalidFile_whenPassingFilesWithDifferentConfigurations() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo]
            )
        )

        try await expect(
            request: request,
            commandExecutor: sut.commandExecutor,
            expectedError: .invalidInputFiles(reason: .differentAudioTracks),
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

    func test_performsConcat_whenPassingFilesWithSameConfig() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo]
            )
        )

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
                audioTracks: [.fixture(codec: "aac")],
                orientation: .portrait,
                videoSize: .init(width: 1920, height: 1080)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .portrait,
                videoSize: .init(width: 1920, height: 1080)
            )
        )
    }

    func test_storesConcatRequest_onConcat() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo]
            )
        )
        let requestId = request.id
        let store = sut.store
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
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 10, height: 20)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 10, height: 20)
            )
        )

        let receivedRequest = try store.getRequest(withId: requestId)
        XCTAssertEqual(receivedRequest?.id, requestId)
        XCTAssertEqual(receivedRequest?.type, .concat)
        XCTAssertEqual(receivedRequest?.status, .completed)
    }

    func test_marksLocalRequestAsFailed_ifCommandFailed() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideo = try await getTestVideoURL()
        let secondVideo = try await getTestVideoURL()
        let request = try anyConcatRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                videos: [firstVideo, secondVideo]
            )
        )
        let requestId = request.id
        let store = sut.store

        try await expect(
            request: request,
            commandExecutor: sut.commandExecutor,
            expectedError: .concatFailed,
            firstVideo: .init(
                url: firstVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 10, height: 20)
            ),
            secondVideo: .init(
                url: secondVideo,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h264", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac")],
                orientation: .landscape,
                videoSize: .init(width: 10, height: 20)
            ),
            withCommandFailure: true
        )

        let receivedRequest = try store.getRequest(withId: requestId)
        XCTAssertEqual(receivedRequest?.status, .error)
    }

    private func makeSUT(authenticated: Bool) -> (
        commandExecutor: MockFFMPEGCommandExecutor,
        engine: TruvideoSdkVideoConcatEngine,
        store: MockVideoStore
    ) {
        let credentialsManager = TruvideoCredentialsManagerSpy(isUserAuthenticated: authenticated)
        let commandExecutor = MockFFMPEGCommandExecutor()
        let store = MockVideoStore()
        let informationGenerator = VideosInformationGenerator(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor
        )
        let inputValidator = ConcatInputValidator(
            credentialsManager: credentialsManager,
            videosInformationGenerator: informationGenerator,
            commandExecutor: commandExecutor
        )
        let sut = TruvideoSdkVideoConcatEngine(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor,
            inputValidator: inputValidator,
            videosInformationGenerator: informationGenerator,
            store: store
        )

        return (commandExecutor, sut, store)
    }

    private func anyConcatRequest(
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore,
        withData data: TruvideoSdkVideoRequest.VideoConcatData? = nil
    ) throws -> TruvideoSdkVideoRequest {
        let builder = ConcatBuilder(
            videos: data?.videos.map { .init(url: $0) } ?? [],
            output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
            engine: engine,
            store: store
        )
        return try builder.build()
    }

    private func anyFileURL() -> URL {
        .init(string: "file://any-file.mov")!
    }
}
