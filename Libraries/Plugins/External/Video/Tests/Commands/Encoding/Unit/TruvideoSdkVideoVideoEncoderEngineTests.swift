//
//  TruvideoSdkVideoVideoEncoderEngineTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 14/2/24.
//

import AVKit
@testable import TruvideoSdkVideo
import XCTest

final class TruvideoSdkVideoVideoEncoderEngineTests: XCTestCase {
    func test_throwsNotAuthenticatedException_whenUserNotAuthenticated() async throws {
        let sut = makeSUT()
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: anyFileURL(),
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )

        await assertError(
            expectedError: .userNotAuthenticated,
            commandExecutor: .init(),
            on: {
                _ = try await sut.engine.process(request: request)
            }
        )
    }

    func test_throwsFileNotFound_whenNonExistingFileWasProvided() async throws {
        let sut = makeSUT(isAuthenticated: true)
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: anyFileURL(),
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )

        await assertError(
            expectedError: .notFoundVideo,
            commandExecutor: .init(),
            on: {
                _ = try await sut.engine.process(request: request)
            }
        )
    }

    func test_throwsInvalidFile_whenNonVideoFileWasProvided() async throws {
        let sut = makeSUT(isAuthenticated: true)
        let imageURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "png")
        let image = UIImage.make(withColor: .black)
        FileManager.default.createFile(atPath: imageURL.path, contents: image.pngData()!)
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: imageURL,
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )

        await assertError(
            expectedError: .invalidFile,
            commandExecutor: .init(),
            on: {
                _ = try await sut.engine.process(request: request)
            }
        )

        addURLForRemoval(imageURL)
    }

    func test_validatesRequestStatus() async throws {
        let sut = makeSUT(isAuthenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: firstVideo,
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )
        let requestId = request.id
        try store.updateRequest(withId: requestId, data: .init(fields: [.status(value: .processing)]))

        await assertError(
            expectedError: .operationStillsInProgress,
            commandExecutor: sut.commandExecutor,
            on: {
                _ = try await sut.engine.process(request: request)
            }
        )

        let secondRequest = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: firstVideo,
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )
        let secondRequestId = secondRequest.id
        try store.updateRequest(withId: secondRequestId, data: .init(fields: [.status(value: .completed)]))

        await assertError(
            expectedError: .operationAlreadyCompleted,
            commandExecutor: sut.commandExecutor,
            on: {
                _ = try await sut.engine.process(request: secondRequest)
            }
        )
    }

    func test_cancelThrowsException_whenRequestIsNotProcessing() async throws {
        let sut = makeSUT(isAuthenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: firstVideo,
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
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
        let sut = makeSUT(isAuthenticated: true)
        let store = sut.store
        let firstVideo = try await getTestVideoURL()
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: firstVideo,
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )
        sut.commandExecutor.cancellationBlock = { try request.cancel() }

        let receivedError = await errorFor(action: {
            _ = try await request.process()
        })

        let retrievedRequest = try store.getRequest(withId: request.id)
        XCTAssertEqual(sut.commandExecutor.cancelCallCount, 1)
        XCTAssertEqual(retrievedRequest?.status, .cancelled)
        XCTAssertEqual(receivedError, .encodingFailed)
    }

    func test_throwsInvalidResolution_whenPassedRsolutionIsLowerThanSupportedValues() async throws {
        let sut = makeSUT(isAuthenticated: true)
        let videoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: videoURL)
        let firstRequest = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: videoURL,
                width: 120,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )

        await assertError(
            expectedError: .invalidResolution,
            commandExecutor: .init(),
            on: {
                _ = try await sut.engine.process(request: firstRequest)
            }
        )

        let secondRequest = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: videoURL,
                width: 120,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )
        await assertError(
            expectedError: .invalidResolution,
            commandExecutor: .init(),
            on: {
                _ = try await sut.engine.process(request: secondRequest)
            }
        )

        let thirdRequest = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: videoURL,
                width: 120,
                height: 120,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )
        await assertError(
            expectedError: .invalidResolution,
            commandExecutor: .init(),
            on: {
                _ = try await sut.engine.process(request: thirdRequest)
            }
        )

        addURLForRemoval(videoURL)
    }

    func test_throwsEncodingFail_whenFFMPEGCommandExecutionFailed() async throws {
        let sut = makeSUT(isAuthenticated: true)
        sut.commandExecutor.mockedResult = .failure(NSError(domain: "Any error", code: 0))
        let videoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: videoURL)
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: videoURL,
                width: 128,
                height: 128,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )
        let requestId = request.id

        await assertError(
            expectedError: .encodingFailed,
            commandExecutor: .init(),
            on: {
                _ = try await sut.engine.process(request: request)
            }
        )
        let retrievedRequest = try sut.store.getRequest(withId: requestId)

        XCTAssertEqual(retrievedRequest?.status, .error)

        addURLForRemoval(videoURL)
    }

    func test_returnsEncodedVideoURL_whenFFMPEGCommandExecutionCompletedSuccessfully() async throws {
        let sut = makeSUT(isAuthenticated: true)
        let videoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: videoURL)
        let request = anyEncodingRequest(
            engine: sut.engine,
            store: sut.store,
            withData: .init(
                inputFileURL: videoURL,
                width: 128,
                height: 150,
                videoTracks: [],
                audioTracks: [],
                framesRate: .thirtyFps
            )
        )
        let requestId = request.id

        _ = try await sut.engine.process(request: request)
        let retrievedRequest = try sut.store.getRequest(withId: requestId)

        XCTAssertEqual(sut.commandExecutor.executeCommandCallCount, 1)
        XCTAssertFalse(sut.commandExecutor.lastExecutedCommand.isEmpty)

        XCTAssertEqual(retrievedRequest?.id, requestId)
        XCTAssertEqual(retrievedRequest?.status, .completed)

        addURLForRemoval(videoURL)
    }

    // MARK: - Helpers

    private func makeSUT(isAuthenticated: Bool = false) -> (
        credentialsManager: TruvideoCredentialsManagerSpy,
        engine: TruvideoSdkVideoVideoEncoderEngine,
        commandExecutor: MockFFMPEGCommandExecutor,
        store: MockVideoStore
    ) {
        let store = MockVideoStore()
        let commandExecutor = MockFFMPEGCommandExecutor()
        let credentialsManager = TruvideoCredentialsManagerSpy(isUserAuthenticated: isAuthenticated)
        let sut = TruvideoSdkVideoVideoEncoderEngine(
            credentialsManager: credentialsManager,
            videoValidator: .init(),
            commandExecutor: commandExecutor,
            commandGenerator: .init(),
            store: store
        )

        return (
            credentialsManager: credentialsManager,
            engine: sut,
            commandExecutor: commandExecutor,
            store: store
        )
    }

    private func anyEncodingRequest(
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore,
        withData data: TruvideoSdkVideoRequest.VideoEncodingData? = nil
    ) -> TruvideoSdkVideoRequest {
        let builder = EncodingBuilder(
            video: .init(url: data?.inputFileURL ?? anyFileURL()),
            output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
            engine: engine,
            store: store
        )

        builder.width = data?.width
        builder.height = data?.height
        builder.framesRate = data?.framesRate ?? .thirtyFps
        builder.videoTracks = data?.videoTracks ?? []
        builder.audioTracks = data?.audioTracks ?? []

        return builder.build()
    }

    private func anyFileURL() -> URL {
        .init(string: "file://any-file.mov")!
    }
}
