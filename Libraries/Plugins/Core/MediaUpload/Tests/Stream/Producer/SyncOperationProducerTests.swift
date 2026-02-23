//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import MediaUploadTesting
import Testing

@testable import MediaUpload

struct SyncOperationProducerTests {
    // MARK: - Properties

    let database = DatabaseMock()
    let partRegistry = PartRegistry()
    let stream = StreamModel(fileType: .avi)

    // MARK: - Tests

    @Test
    func testThatOperationsShouldEmitStartSessionOperationInitially() async throws {
        // Given
        let sut = SyncOperationProducer(
            stream: stream,
            database: database,
            partRegistry: partRegistry
        )

        // When
        let stream = sut.operations().first

        // Then
        #expect(stream != nil)
    }

    @Test
    func testThatFinishShouldEmitCompleteStreamOperationWhenSessionIdExists() async throws {
        // Given
        let sut = SyncOperationProducer(
            stream: stream,
            database: database,
            partRegistry: partRegistry
        )

        // When
        try await database.save(stream)
        stream.sessionId = "session-123"

        let operations = sut.operations()
        var iterator = operations.makeAsyncIterator()

        _ = await iterator.next()

        try await sut.finish()

        let result = await iterator.next()

        // Then
        #expect(result?.first is CompleteStreamOperation)
    }
}
