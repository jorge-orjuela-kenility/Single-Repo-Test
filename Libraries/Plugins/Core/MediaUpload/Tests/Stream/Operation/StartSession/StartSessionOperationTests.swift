//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreDataUtilities
import DI
import Foundation
import MediaUploadTesting
import Networking
import NetworkingTesting
import Testing
import TruVideoFoundation

@testable import TruVideoMediaUpload

struct StartSessionOperationTests {
    // MARK: - Properties

    let uploadSession = UploadSession(uploadId: "test-123", mediaId: UUID())
    let stream = StreamModel(fileType: .avi)

    // MARK: - Tests

    @Test
    func testThatStartSessionOperationSuccessfullyWhenRequestReturns() async throws {
        // Given
        let operation = StartSessionOperation(stream: stream)

        // When
        operation.start()

        await operation.waitUntilFinished()

        // Then
        #expect(operation.isFinished)
        #expect(!operation.isExecuting)
        #expect(!operation.isCancelled)
    }

    @Test
    func testThatStartSessionOperationShouldSuspendUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = StartSessionOperation(stream: stream)
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = try Response<UploadSession, NetworkingError>(
                data: JSONEncoder().encode(uploadSession),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadSession),
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
    func testThatStartSessionOperationShouldResumeUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = StartSessionOperation(stream: stream)
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = try Response<UploadSession, NetworkingError>(
                data: JSONEncoder().encode(uploadSession),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadSession),
                type: .localCache
            )

            // When
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
    func testThatStartSessionOperationShouldCancelUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = StartSessionOperation(stream: stream)
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = try Response<UploadSession, NetworkingError>(
                data: JSONEncoder().encode(uploadSession),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadSession),
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

    @Test
    func testThatStartSessionOperationFinishesImmediatelyWhenSessionIdAlreadyExists() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = StartSessionOperation(stream: stream)

            // When
            stream.sessionId = "session-id"

            dependencies.eventEmitter
                .emit(
                    StreamOperationEvent.sessionCreated(
                        for: stream.id,
                        sessionId: stream.sessionId ?? "",
                        mediaId: stream.mediaId ?? UUID()
                    )
                )

            operation.start()
            await operation.waitUntilFinished()

            // Then
            #expect(operation.isFinished)
            #expect(!operation.isExecuting)
            #expect(!operation.isCancelled)
            #expect(operation.result != nil)
        }
    }
}
