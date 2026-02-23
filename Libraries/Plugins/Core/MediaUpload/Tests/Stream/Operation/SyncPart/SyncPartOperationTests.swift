//
// Copyright © 2026 TruVideo. All rights reserved.
//

import DI
import Foundation
import Networking
import NetworkingTesting
import Testing

@testable import MediaUpload

struct SyncPartOperationTests {
    // MARK: - Properties

    let uploadResponse = UploadPartResponse(uploadId: "\(UUID())-upload", parts: [])

    // MARK: - Tests

    @Test
    func testThatSyncOperationSuccessfullyWhenRequestReturns() async throws {
        // Given
        let part = try makeStreamPart()
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpg,
            sessionId: "session-123"
        )

        // When
        operation.start()

        await operation.waitUntilFinished()

        // Then
        #expect(operation.isFinished)
        #expect(!operation.isExecuting)
        #expect(!operation.isCancelled)
    }

    @Test
    func testThatSyncPartOperationFailsWhenETagIsEmpty() async throws {
        // Given
        let part = try makeStreamPart()
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpg,
            sessionId: "session-123"
        )

        // When
        part.eTag = ""

        operation.start()
        await operation.waitUntilFinished()

        // Then
        let error = try #require(operation.result?.failure)
        let underlying = try #require(error.underlyingError as? SyncPartOperation.SyncPartError)
        #expect(underlying == .missingETagHeader)
    }

    @Test
    func testThatSyncPartOperationSuspendAndResumeWhenRequestReturns() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let part = try makeStreamPart()
            let operation = SyncPartOperation(
                part: part,
                fileType: .jpg,
                sessionId: "session-123"
            )
            let dataRequest = DataRequestMock(delay: 500_000_000)
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

            try await Task.sleep(nanoseconds: 50_000_000)
            operation.resume()

            await operation.waitUntilFinished()

            // Then
            #expect(operation.isFinished)
        }
    }

    @Test
    func testThatSyncPartOperationCancelWhenRequestReturns() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let part = try makeStreamPart()
            let operation = SyncPartOperation(
                part: part,
                fileType: .jpg,
                sessionId: "session-123"
            )
            let dataRequest = DataRequestMock(delay: 500_000_000)
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
            #expect(operation.isCancelled)
        }
    }

    // MARK: - Helpers method

    private func makeStreamPart() throws -> StreamPartModel {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try Data("test-data".utf8).write(to: tempURL)

        return StreamPartModel(
            localFileUrl: tempURL,
            number: 1,
            sessionId: "foo",
            streamId: UUID(),
            status: .uploading
        )
    }
}
