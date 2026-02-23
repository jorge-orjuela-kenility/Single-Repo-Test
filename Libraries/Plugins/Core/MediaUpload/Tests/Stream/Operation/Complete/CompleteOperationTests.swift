//
// Copyright © 2026 TruVideo. All rights reserved.
//

import DI
import Foundation
import Networking
import NetworkingTesting
import Testing

@testable import MediaUpload

struct CompleteOperationTests {
    // MARK: - Properties

    let stream = StreamModel(fileType: .avi)

    // MARK: - Tests

    @Test
    func testThatOperationCompletesSuccessfullyWhenRequestReturns() async throws {
        // Given
        let operation = CompleteStreamOperation(stream: stream, sessionId: "session-123")

        // When
        operation.start()

        await operation.waitUntilFinished()

        // Then
        #expect(operation.isFinished)
        #expect(!operation.isExecuting)
        #expect(!operation.isCancelled)
    }

    @Test
    func testThatOperationFailsWhenSessionIdIsEmpty() async throws {
        // Given
        let operation = CompleteStreamOperation(stream: stream, sessionId: "")

        // When
        operation.start()

        await operation.waitUntilFinished()

        // Then
        let error = try #require(operation.result?.failure)
        #expect(error.kind == .CompleteStreamOperationErrorReason.failedToCompleteStream)
    }

    @Test
    func testThatCompleteOperationShouldSuspendUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = CompleteStreamOperation(stream: stream, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 500_000_000)
            let session = SessionMock()
            let response = Response<Empty, NetworkingError>(
                data: Data("{}".utf8),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(try! JSONDecoder().decode(Empty.self, from: Data("{}".utf8))),
                type: .localCache
            )

            // When
            dataRequest.mockResponse = response
            session.dataRequest = dataRequest
            dependencies.truVideoSession = session

            operation.start()

            try await Task.sleep(nanoseconds: 50_000_000)

            operation.suspend()

            // Then
            #expect(dataRequest.suspendCallCount == 1)
            #expect(operation.state == .suspended)
        }
    }

    @Test
    func testThatCompleteOperationShouldResumeUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = CompleteStreamOperation(stream: stream, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 500_000_000)
            let session = SessionMock()
            let response = Response<Empty, NetworkingError>(
                data: Data("{}".utf8),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(try! JSONDecoder().decode(Empty.self, from: Data("{}".utf8))),
                type: .localCache
            )

            // When, Then
            dataRequest.mockResponse = response
            session.dataRequest = dataRequest
            dependencies.truVideoSession = session

            operation.start()

            try await Task.sleep(nanoseconds: 50_000_000)

            operation.suspend()

            #expect(dataRequest.suspendCallCount == 1)
            #expect(operation.state == .suspended)

            operation.resume()

            #expect(dataRequest.resumeCallCount == 1)
            #expect(operation.state == .running)
        }
    }

    @Test
    func testThatCompleteOperationShouldCancelUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = CompleteStreamOperation(stream: stream, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 500_000_000)
            let session = SessionMock()
            let response = Response<Empty, NetworkingError>(
                data: Data("{}".utf8),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(try! JSONDecoder().decode(Empty.self, from: Data("{}".utf8))),
                type: .localCache
            )

            // When
            dataRequest.mockResponse = response
            session.dataRequest = dataRequest
            dependencies.truVideoSession = session

            operation.start()

            try await Task.sleep(nanoseconds: 50_000_000)

            operation.cancel()

            // Then
            #expect(dataRequest.cancelCallCount == 1)
        }
    }
}
