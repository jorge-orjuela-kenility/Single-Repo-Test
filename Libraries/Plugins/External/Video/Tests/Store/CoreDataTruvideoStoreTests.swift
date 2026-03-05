//
//  CoreDataTruvideoStoreTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 22/2/24.
//

import Combine
import XCTest

@testable import TruvideoSdkVideo

final class CoreDataTruvideoStoreTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func test_coreDataStore_retrievesPreviouslyInsertedRequest_withPassedId() throws {
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        let request = makeRequest()

        try sut.insert(
            request: request
        )
        let result = try sut.getRequest(withId: request.id)

        XCTAssertEqual(result?.id, request.id)
        XCTAssertEqual(result?.status, request.status)
        XCTAssertEqual(result?.type, request.type)
        XCTAssertEqual(result?.inputFiles.count, 2)
        XCTAssertEqual(result?.inputFiles.first?.path, request.inputFiles.first?.path)
        XCTAssertEqual(result?.inputFiles.last?.path, request.inputFiles.last?.path)
    }

    func test_coreDataStore_retrievesPreviouslyInsertedRequest_withPassedStatus() throws {
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        let firstRequest = makeRequest()
        let secondRequest = makeRequest(status: .cancelled)
        let thirdRequest = makeRequest()

        try sut.insert(
            request: firstRequest
        )
        try sut.insert(
            request: secondRequest
        )
        try sut.insert(
            request: thirdRequest
        )
        let result = try sut.getRequests(withStatus: .processing)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.id, firstRequest.id)
        XCTAssertEqual(result.last?.id, thirdRequest.id)
    }

    func test_coreDataStore_deletesPreviouslyCreatedRequest_withPassedId() throws {
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        let firstRequest = makeRequest()

        try sut.insert(
            request: firstRequest
        )
        try sut.deleteRequest(withId: firstRequest.id)
        let result = try sut.getRequest(withId: firstRequest.id)

        XCTAssertNil(result)
    }

    func test_coreDataStore_updatesPreviouslyCreatedRequest_withPassedId() throws {
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        let firstRequest = makeRequest()
        let errorMessage = "Any error message"

        try sut.insert(request: firstRequest)
        try sut.updateRequest(
            withId: firstRequest.id,
            data: .init(fields: [.error(value: errorMessage), .status(value: .completed)])
        )
        let result = try sut.getRequest(withId: firstRequest.id)

        XCTAssertEqual(result?.error, errorMessage)
        XCTAssertEqual(result?.status, .completed)
    }

    func test_coreDataStore_marksPreviousRequests_asCancelled() throws {
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        let firstRequest = makeRequest()

        try sut.insert(
            request: firstRequest
        )
        sut.resetPendingRequests()
        let retrievedRequest = try sut.getRequest(withId: firstRequest.id)

        XCTAssertEqual(retrievedRequest?.status, .cancelled)
    }

    func testThatStreamAllVideosWhenSaveInformationAfterToCreateThePublisher() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        var requests: [LocalVideoRequest] = []
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))

        // When
        sut.streamVideos()
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                requests = value
                expectation.fulfill()
            })
            .store(in: &cancellables)

        try? sut.insert(
            request: LocalVideoRequest(
                id: id,
                status: .completed,
                outputPath: URL(string: "url.com")!,
                output: .custom(rawPath: URL(string: "url.com")!.deletingPathExtension().path),
                type: .encode,
                inputFiles: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertEqual(requests.first?.id, id)
    }

    func testThatStreamAllVideosWhenSaveInformationBeforeToCreateThePublisher() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        var requests: [LocalVideoRequest] = []
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))

        // When
        try? sut.insert(
            request: LocalVideoRequest(
                id: id,
                status: .completed,
                outputPath: URL(string: "url.com")!,
                output: .custom(rawPath: URL(string: "url.com")!.deletingPathExtension().path),
                type: .encode,
                inputFiles: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )

        sut.streamVideos()
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                requests = value
                expectation.fulfill()
            })
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertEqual(requests.first?.id, id)
    }

    func testThatStreamAllVideos() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        let id2 = UUID()
        let date = Date()
        var requests: [LocalVideoRequest] = []
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))

        // When
        try? sut.insert(
            request: LocalVideoRequest(
                id: id,
                status: .completed,
                outputPath: URL(string: "url.com")!,
                output: .custom(rawPath: URL(string: "url.com")!.deletingPathExtension().path),
                type: .encode,
                inputFiles: [],
                createdAt: date,
                updatedAt: date
            )
        )

        sut.streamVideos()
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                if value.count == 1 {
                    try? sut.insert(
                        request: LocalVideoRequest(
                            id: id2,
                            status: .completed,
                            outputPath: URL(string: "url.com")!,
                            output: .custom(rawPath: URL(string: "url.com")!.deletingPathExtension().path),
                            type: .encode,
                            inputFiles: [],
                            createdAt: date,
                            updatedAt: date
                        )
                    )
                } else {
                    requests = value
                    expectation.fulfill()
                }
            })
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertEqual(requests.first?.id, id)
        XCTAssertEqual(requests.last?.id, id2)
    }

    func testThatStreamVideosByStatus() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        var requests: [LocalVideoRequest] = []
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))

        // When
        try? sut.insert(
            request: LocalVideoRequest(
                id: id,
                status: .cancelled,
                outputPath: URL(string: "url.com")!,
                output: .custom(rawPath: URL(string: "url.com")!.deletingPathExtension().path),
                type: .encode,
                inputFiles: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )

        sut.streamVideos(withStatus: .cancelled)
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                requests = value
                expectation.fulfill()
            })
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertEqual(requests.first?.id, id)
    }

    func testThatStreamVideosById() throws {
        // Given
        let expectation = expectation(description: #function)
        let id = UUID()
        var request: LocalVideoRequest?
        let sut = try! CoreDataTruvideoStore(storeURL: URL(fileURLWithPath: "/dev/null"))

        // When
        try? sut.insert(
            request: LocalVideoRequest(
                id: id,
                status: .completed,
                outputPath: URL(string: "url.com")!,
                output: .custom(rawPath: URL(string: "url.com")!.deletingPathExtension().path),
                type: .encode,
                inputFiles: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )

        try sut.streamVideo(with: id)
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                request = value
                expectation.fulfill()
            })
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertEqual(request?.id, id)
    }

    // MARK: - Helpers

    func makeRequest(status: LocalVideoRequest.Status = .processing) -> LocalVideoRequest {
        .init(
            id: UUID(),
            status: status,
            outputPath: TruvideoSdkVideoUtils.outputURL(for: "output", fileExtension: "mp4"),
            output: .files(fileName: "output"),
            type: .merge,
            inputFiles: [
                .init(
                    path: TruvideoSdkVideoUtils.outputURL(for: "input-1", fileExtension: "mov"),
                    index: 0
                ),
                .init(
                    path: TruvideoSdkVideoUtils.outputURL(for: "input-2", fileExtension: "mov"),
                    index: 1
                )
            ],
            createdAt: .init(),
            updatedAt: .init()
        )
    }
}
