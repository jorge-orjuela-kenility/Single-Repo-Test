//
// Copyright © 2026 TruVideo. All rights reserved.
//

import DI
import Foundation
import Networking
import NetworkingTesting
import Testing

@testable import MediaUpload

struct UploadDataOperationTests {
    // MARK: - Properties

    let uploadResponse = UploadPartResponse(uploadId: "upload-123", parts: [])
    let stream = StreamModel(fileType: .avi)

    // MARK: - Tests

    @Test
    func testThatUploadDataOperationSuccessfullyWhenRequestReturns() async throws {
        // Given
        let operation = UploadDataOperation(data: Data(), fileType: .jpeg, sessionId: "session-123")

        // When
        operation.start()

        await operation.waitUntilFinished()

        // Then
        #expect(operation.isFinished)
        #expect(!operation.isExecuting)
        #expect(!operation.isCancelled)
    }

    @Test
    func testThatUploadDataOperationShouldSuspendUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = UploadDataOperation(data: Data(), fileType: .jpeg, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = Response<UploadPartResponse, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadResponse),
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
    func testThatUploadDataPartOperationShouldResumeUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = UploadDataOperation(data: Data(), fileType: .jpeg, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = Response<UploadPartResponse, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadResponse),
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
    func testThatUploadDataPartOperationShouldCancelUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = UploadDataOperation(data: Data(), fileType: .jpeg, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = Response<UploadPartResponse, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadResponse),
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
