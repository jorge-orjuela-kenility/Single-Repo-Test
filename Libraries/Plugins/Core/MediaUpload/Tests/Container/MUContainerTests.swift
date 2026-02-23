//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreDataUtilities
import Foundation
import MediaUploadTesting
import Testing
import TruVideoFoundation

@testable import TruVideoMediaUpload

struct MUContainerTests {
    // MARK: - Properties

    let database = DatabaseMock()
    let operationProducer = OperationProducerMock()
    let partRegistry = PartRegistry()
    let stream = StreamModel(fileType: .avi)

    // MARK: - Tests

    @Test()
    func testThatNewStreamCreatesStreamInReadyState() async throws {
        // Given
        let sut = MUContainer(database: database)

        // When
        let stream = try await sut.newStream(of: .jpeg)

        // Then
        #expect(stream.status == .ready)
    }

    @Test()
    func testThatNewStreamCreatesStreamsDirectoryIfNeeded() async throws {
        // Given
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID())-stream")
        let sut = MUContainer(database: database, streamsDirectoryURL: url)

        // When
        _ = try await sut.newStream(of: .mov)

        // Then
        #expect(stream.status == .ready)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test()
    func testThatNewStreamShouldFailWhenDatabaseThrowsError() async throws {
        // Given
        let sut = MUContainer(database: database)

        // When, Then
        await #expect {
            await database.setError(UtilityError(kind: .DatabaseError.saveFailed))
            _ = try await sut.newStream(of: .flac)
        } throws: { error in
            let error = error as! UtilityError

            return error.kind == .MUContainerErrorReason.newStreamFailed
        }
    }

    @Test()
    func testThatRetrieveStreamsReturnsExistingActiveStreams() async throws {
        // Given
        let sut = MUContainer(database: database)

        // When
        _ = try await sut.newStream(of: .jpeg)

        let activeStreams = try await sut.retrieveStreams()

        // Then
        #expect(activeStreams.count == 1)
    }

    @Test()
    func testRetrieveStreamsAppliesFilter() async throws {
        // Given
        let sut = MUContainer(database: database)

        // When
        _ = try await sut.newStream(of: .avi)
        _ = try await sut.newStream(of: .jpeg)
        let streams = try await sut.retrieveStreams {
            $0.fileType == .avi
        }

        // Then
        #expect(streams.count == 1)
        #expect(streams.first?.fileType == .avi)
    }

    @Test()
    func testThatRetrieveStreamsShouldReturnStreamsSortedByCreationDate() async throws {
        // Given
        let sut = MUContainer(database: database)

        // When
        let firstStream = try await sut.newStream(of: .avi)

        try await Task.sleep(nanoseconds: 1_000_000)

        let secondStream = try await sut.newStream(of: .jpeg)

        let streams = try await sut.retrieveStreams()

        // Then
        #expect(streams.first?.id == firstStream.id)
        #expect(streams.last?.id == secondStream.id)
    }

    @Test()
    func testThatRetrieveStreamsRebuildsInactiveStreamsWithParts() async throws {
        // Given
        let sut = MUContainer(database: database)

        // When
        _ = try await sut.newStream(of: .png)
        let cancelledStream = try await sut.newStream(of: .png)

        cancelledStream.cancel()

        try await Task.sleep(nanoseconds: 500_000)

        let streams = try await sut.retrieveStreams()

        // Then
        #expect(streams.count == 2)
    }

    @Test()
    func testThatRetrieveStreamsShouldFailOnDatabaseError() async throws {
        // Given
        let sut = MUContainer(database: database)

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        // When, Then
        await #expect {
            _ = try await sut.retrieveStreams()
        } throws: { error in
            let error = error as! UtilityError

            return error.kind == .MUContainerErrorReason.retrieveStreamsFailed
        }
    }
}
