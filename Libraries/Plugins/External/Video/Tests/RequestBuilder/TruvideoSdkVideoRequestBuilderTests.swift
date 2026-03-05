//
//  TruvideoSdkVideoRequestBuilderTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 8/3/24.
//

import Combine
import Foundation
import XCTest

@testable import TruvideoSdkVideo

final class TruvideoSdkVideoRequestBuilderTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testThatStreamRequests() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        var requests: [TruvideoSdkVideoRequest] = []
        let sut = makeSUT(authenticated: true)

        // When
        try sut.store.insert(
            request: .init(
                id: id,
                status: .idle,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .merge,
                inputFiles: [.init(path: anyFileURL(), index: 0), .init(path: anyFileURL(), index: 1)],
                rawData: TruvideoSdkVideoRequest.VideoMergeData(
                    videos: [anyFileURL(), anyFileURL()],
                    width: 100,
                    height: 100,
                    framesRate: .fiftyFps,
                    videoTracks: [.fixture()],
                    audioTracks: [.fixture()]
                ).serializable.jsonRepresentation,
                createdAt: .init(),
                updatedAt: .init()
            )
        )

        sut.requestBuilder.streamRequests(withStatus: nil)
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { value in
                requests = value
            })
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertEqual(requests.first?.id, id)
        XCTAssertEqual(requests.count, 1)
    }

    func testThatStreamRequestsWithStatus() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        var requests: [TruvideoSdkVideoRequest] = []
        let sut = makeSUT(authenticated: true)

        // When
        try sut.store.insert(
            request: .init(
                id: id,
                status: .idle,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .merge,
                inputFiles: [.init(path: anyFileURL(), index: 0), .init(path: anyFileURL(), index: 1)],
                rawData: TruvideoSdkVideoRequest.VideoMergeData(
                    videos: [anyFileURL(), anyFileURL()],
                    width: 100,
                    height: 100,
                    framesRate: .fiftyFps,
                    videoTracks: [.fixture()],
                    audioTracks: [.fixture()]
                ).serializable.jsonRepresentation,
                createdAt: .init(),
                updatedAt: .init()
            )
        )

        sut.requestBuilder.streamRequests(withStatus: .complete)
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { value in
                requests = value
            })
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertEqual(sut.store.status, .complete)
        XCTAssertEqual(requests.first?.id, id)
        XCTAssertEqual(requests.count, 1)
    }

    func testThatStreamVideoRequest() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        var request: TruvideoSdkVideoRequest?
        let sut = makeSUT(authenticated: true)

        // When
        try sut.store.insert(
            request: .init(
                id: id,
                status: .idle,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .merge,
                inputFiles: [.init(path: anyFileURL(), index: 0), .init(path: anyFileURL(), index: 1)],
                rawData: TruvideoSdkVideoRequest.VideoMergeData(
                    videos: [anyFileURL(), anyFileURL()],
                    width: 100,
                    height: 100,
                    framesRate: .fiftyFps,
                    videoTracks: [.fixture()],
                    audioTracks: [.fixture()]
                ).serializable.jsonRepresentation,
                createdAt: .init(),
                updatedAt: .init()
            )
        )

        try sut.requestBuilder.streamVideoRequest(withId: id)
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { value in
                request = value
            })
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertNotNil(request)
    }

    func test_throwsUserNotAuthenticatedException_whenUserIsNotAuthenticated() async {
        let sut = makeSUT(authenticated: false)

        let receivedError = await errorFor {
            _ = try sut.requestBuilder.getRequestsByStatus(status: .cancelled)
        }

        XCTAssertEqual(receivedError, .userNotAuthenticated)
    }

    func test_fetchesPreviouslyCreatedRequests() async throws {
        let sut = makeSUT(authenticated: true)

        try sut.store.insert(
            request: .init(
                id: .init(),
                status: .idle,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .merge,
                inputFiles: [.init(path: anyFileURL(), index: 0), .init(path: anyFileURL(), index: 1)],
                rawData: TruvideoSdkVideoRequest.VideoMergeData(
                    videos: [anyFileURL(), anyFileURL()],
                    width: 100,
                    height: 100,
                    framesRate: .fiftyFps,
                    videoTracks: [.fixture()],
                    audioTracks: [.fixture()]
                ).serializable.jsonRepresentation,
                createdAt: .init(),
                updatedAt: .init()
            )
        )
        try sut.store.insert(
            request: .init(
                id: .init(),
                status: .completed,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .merge,
                inputFiles: [.init(path: anyFileURL(), index: 0), .init(path: anyFileURL(), index: 1)],
                rawData: TruvideoSdkVideoRequest.VideoMergeData(
                    videos: [anyFileURL(), anyFileURL()],
                    width: 100,
                    height: 100,
                    framesRate: .fiftyFps,
                    videoTracks: [.fixture()],
                    audioTracks: [.fixture()]
                ).serializable.jsonRepresentation,
                createdAt: .init(),
                updatedAt: .init()
            )
        )
        try sut.store.insert(
            request: .init(
                id: .init(),
                status: .idle,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .concat,
                inputFiles: [.init(path: anyFileURL(), index: 0), .init(path: anyFileURL(), index: 1)],
                createdAt: .init(),
                updatedAt: .init()
            )
        )
        try sut.store.insert(
            request: .init(
                id: .init(),
                status: .completed,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .concat,
                inputFiles: [.init(path: anyFileURL(), index: 0), .init(path: anyFileURL(), index: 1)],
                createdAt: .init(),
                updatedAt: .init()
            )
        )
        try sut.store.insert(
            request: .init(
                id: .init(),
                status: .idle,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .encode,
                inputFiles: [.init(path: anyFileURL(), index: 0)],
                rawData: TruvideoSdkVideoRequest.VideoEncodingData(
                    inputFileURL: anyFileURL(),
                    width: 100,
                    height: 100,
                    videoTracks: [.fixture()],
                    audioTracks: [0],
                    framesRate: .fiftyFps
                ).serializable.jsonRepresentation,
                createdAt: .init(),
                updatedAt: .init()
            )
        )
        try sut.store.insert(
            request: .init(
                id: .init(),
                status: .completed,
                outputPath: anyFileURL(),
                output: .custom(rawPath: anyFileURL().deletingPathExtension().path),
                type: .encode,
                inputFiles: [.init(path: anyFileURL(), index: 0)],
                rawData: TruvideoSdkVideoRequest.VideoEncodingData(
                    inputFileURL: anyFileURL(),
                    width: 100,
                    height: 100,
                    videoTracks: [.fixture()],
                    audioTracks: [0],
                    framesRate: .fiftyFps
                ).serializable.jsonRepresentation,
                createdAt: .init(),
                updatedAt: .init()
            )
        )

        let retrievedRequests = try sut.requestBuilder.getRequestsByStatus(status: .idle)

        if retrievedRequests.count == 3 {
            let firstRequest = retrievedRequests[0]
            XCTAssertEqual(
                firstRequest.mergeData,
                .init(
                    videos: [anyFileURL(), anyFileURL()],
                    width: 100,
                    height: 100,
                    framesRate: .fiftyFps,
                    videoTracks: [.fixture(tracks: [.fixture(), .fixture(fileIndex: 1)])],
                    audioTracks: [.fixture(tracks: [.fixture(), .fixture(fileIndex: 1)])]
                )
            )
            let secondRequest = retrievedRequests[1]
            XCTAssertEqual(
                secondRequest.concatData,
                .init(videos: [anyFileURL(), anyFileURL()])
            )
            let thirdRequest = retrievedRequests[2]
            XCTAssertEqual(
                thirdRequest.encodingData,
                .init(
                    inputFileURL: anyFileURL(),
                    width: 100,
                    height: 100,
                    videoTracks: [.fixture()],
                    audioTracks: [0],
                    framesRate: .fiftyFps
                )
            )
        } else {
            XCTFail("Expected to retrieve 3 requests got \(retrievedRequests.count) instead")
        }
    }

    // MARK: - Helpers

    private func anyFileURL() -> URL {
        .init(string: "file://any-file.mov")!
    }

    private func makeSUT(authenticated: Bool) -> (
        commandExecutor: MockFFMPEGCommandExecutor,
        concatEngine: TruvideoSdkVideoConcatEngine,
        mergeEngine: TruvideoSdkVideoMergeEngine,
        encodingEngine: TruvideoSdkVideoVideoEncoderEngine,
        requestBuilder: TruvideoSdkVideoRequestBuilder,
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
        let concatEngine = TruvideoSdkVideoConcatEngine(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor,
            inputValidator: inputValidator,
            videosInformationGenerator: informationGenerator,
            store: store
        )
        let mergeEngine = TruvideoSdkVideoMergeEngine(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor,
            videosInformationGenerator: informationGenerator,
            store: store
        )
        let encodingEngine = TruvideoSdkVideoVideoEncoderEngine(
            credentialsManager: credentialsManager,
            videoValidator: .init(),
            commandExecutor: commandExecutor,
            commandGenerator: .init(),
            store: store
        )
        let requestBuilder = TruvideoSdkVideoRequestBuilder(
            store: store,
            mergeEngine: mergeEngine,
            concatEngine: concatEngine,
            encodingEngine: encodingEngine,
            credentialsManager: credentialsManager
        )
        return (commandExecutor, concatEngine, mergeEngine, encodingEngine, requestBuilder, store)
    }
}
