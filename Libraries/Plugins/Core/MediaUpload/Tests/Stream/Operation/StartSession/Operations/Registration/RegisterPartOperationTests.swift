//
// Copyright © 2026 TruVideo. All rights reserved.
//

import DI
import Foundation
import Networking
import NetworkingTesting
import Testing

@testable import MediaUpload

struct RegisterPartOperationTests {
    // MARK: - Properties

    let uploadPartStatus = UploadPartStatus(
        uploadId: "upload-123",
        partNumber: 1,
        status: "COMPLETED"
    )
    let stream = StreamModel(fileType: .avi)

    // MARK: - Tests

    @Test
    func testThatRegisterPartOperationSuccessfullyWhenRequestReturns() async throws {
        // Given
        let operation = RegisterPartOperation(eTag: "etag-123", number: 1, sessionId: "session-123")

        // When
        operation.start()

        await operation.waitUntilFinished()

        // Then
        #expect(operation.isFinished)
        #expect(!operation.isExecuting)
        #expect(!operation.isCancelled)
    }

    @Test
    func testThatRegisterPartOperationShouldSuspendUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = RegisterPartOperation(eTag: "etag-123", number: 1, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = try Response<UploadPartStatus, NetworkingError>(
                data: JSONEncoder().encode(uploadPartStatus),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadPartStatus),
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
    func testThatRegisterPartOperationShouldResumeUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = RegisterPartOperation(eTag: "etag-123", number: 1, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = try Response<UploadPartStatus, NetworkingError>(
                data: JSONEncoder().encode(uploadPartStatus),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadPartStatus),
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
    func testThatRegisterPartOperationShouldCancelUnderlyingRequest() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let operation = RegisterPartOperation(eTag: "etag-123", number: 1, sessionId: "session-123")
            let dataRequest = DataRequestMock(delay: 5_000_000_000)
            let session = SessionMock()
            let response = try Response<UploadPartStatus, NetworkingError>(
                data: JSONEncoder().encode(uploadPartStatus),
                metrics: nil,
                request: nil,
                response: HTTPURLResponse(
                    url: URL(string: "https://\(UUID())-test")!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                ),
                result: .success(uploadPartStatus),
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
