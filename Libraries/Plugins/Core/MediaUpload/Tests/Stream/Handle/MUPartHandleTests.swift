//
// Copyright © 2026 TruVideo. All rights reserved.
//

import DI
import Foundation
import InternalUtilities
import MediaUploadTesting
import Testing
import TruVideoFoundation

@testable import TruVideoMediaUpload

struct MUPartHandleTests {
    // MARK: - Properties

    let database = DatabaseMock()
    let part = StreamPartModel(
        localFileUrl: URL(string: "foo-bar")!,
        number: 1,
        sessionId: "foo",
        streamId: UUID()
    )
    let emitter = EventEmitter()

    // MARK: - Tests

    @Test()
    func testThatRegisterOperationShouldSucceedWhenStatusIsPendingAndNoActiveOperationsExist() async throws {
        // Given
        let sut = MUPartHandle(part: part, database: database)
        let firstOperation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "foo"
        )
        let secondOperation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "bar"
        )

        // When
        _ = await sut.register(firstOperation)
        _ = await sut.register(secondOperation)
        let operations = await sut.operations

        // Then
        #expect(operations.count == 1)
        #expect(operations.first === firstOperation)
    }

    @Test()
    func testThatCancelStreamPartShouldCancelRegisteredOperations() async throws {
        // Given
        let sut = MUPartHandle(part: part, database: database)
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "foo"
        )

        // When
        _ = await sut.register(operation)

        sut.cancel()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        #expect(operation.isCancelled == true)
        #expect(part.status == .cancelled)
    }

    @Test()
    func testThatCancelShouldNotCancelRegisteredOperationsWhenDatabaseSaveFails() async throws {
        // Given
        let sut = MUPartHandle(part: part, database: database)
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "foo"
        )

        // When
        _ = await sut.register(operation)

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.cancel()

        // Then
        #expect(operation.isCancelled == false)
    }

    @Test()
    func testThatResumeShouldTransitionPartToPendingWhenStatusIsSuspended() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let part = StreamPartModel(
                localFileUrl: URL(string: "foo-bar")!,
                number: 1,
                sessionId: "foo",
                streamId: UUID(),
                status: .suspended
            )
            let sut = MUPartHandle(part: part, database: database)
            let operation = SyncPartOperation(
                part: part,
                fileType: .jpeg,
                sessionId: "foo"
            )

            // When
            _ = await sut.register(operation)

            try await Task.sleep(nanoseconds: 50_000_000)

            dependencies.eventEmitter.emit(StreamPartOperationEvent.resumed(partId: part.id))

            sut.resume()

            try await Task.sleep(nanoseconds: 1_000_000_000)

            // Then
            #expect(part.status == .pending)
        }
    }

    @Test()
    func testThatResumeDoesNotResumeOperationsWhenDatabaseSaveFails() async throws {
        // Given
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: UUID(),
            status: .suspended
        )
        let sut = MUPartHandle(part: part, database: database)
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "foo"
        )

        // When
        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        _ = await sut.register(operation)

        sut.resume()

        // Then
        #expect(operation.isSuspended == false)
        #expect(operation.isExecuting == false)
    }

    @Test()
    func testThatSuspendShouldTransitionPartToSuspendedWhenStatusIsPending() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let sut = MUPartHandle(part: part, database: database)
            let operation = SyncPartOperation(
                part: part,
                fileType: .jpeg,
                sessionId: "foo"
            )

            // When
            dependencies.eventEmitter.emit(StreamPartOperationEvent.suspended(partId: part.id))

            _ = await sut.register(operation)

            sut.suspend()

            try await Task.sleep(nanoseconds: 1_000_000_000)

            // Then
            #expect(part.status == .suspended)
        }
    }

    @Test()
    func testThatSuspendShouldRestoreFailedStatusWhenDatabaseSaveFails() async throws {
        // Given
        let sut = MUPartHandle(part: part, database: database)
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "foo"
        )

        // When
        _ = await sut.register(operation)

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.suspend()

        // Then
        #expect(part.status == .pending)
        #expect(operation.isSuspended == false)
    }

    @Test()
    func testThatRetryStreamPartShouldSucceedWhenPartStatusIsFailed() async throws {
        // Given
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: UUID(),
            status: .failed
        )
        let sut = MUPartHandle(part: part, database: database)
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "foo"
        )

        // When
        _ = await sut.register(operation)

        sut.retry()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        #expect(part.status == .retrying)
    }

    @Test()
    func testThatRetryShouldRestoreFailedStatusWhenDatabaseSaveFails() async throws {
        // Given
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: UUID(),
            status: .failed
        )
        let sut = MUPartHandle(part: part, database: database)
        let operation = SyncPartOperation(
            part: part,
            fileType: .jpeg,
            sessionId: "foo"
        )

        // When
        _ = await sut.register(operation)

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.retry()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        #expect(operation.isExecuting == false)
        #expect(part.status == .failed)
    }

    @Test
    func testThatFailedEventIncrementsAttemptsWhenPartAlreadyExceededMaxAttempts() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let part = StreamPartModel(
                localFileUrl: URL(string: "file://part")!,
                number: 1,
                sessionId: "foo",
                streamId: UUID(),
                attempts: 7,
                status: .failed
            )
            let sut = MUPartHandle(part: part, database: database)

            let operation = SyncPartOperation(
                part: part,
                fileType: .jpeg,
                sessionId: "foo"
            )

            // When
            _ = await sut.register(operation)

            try await Task.sleep(nanoseconds: 50_000_000)

            dependencies.eventEmitter.emit(StreamPartOperationEvent.failed(partId: part.id))

            try await Task.sleep(nanoseconds: 100_000_000)

            // Then
            #expect(part.status == .failed)
            #expect(part.attempts == 8)
        }
    }

    @Test
    func testThatPartRemainsUploadingWhenUploadingEventIsReceived() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let part = StreamPartModel(
                localFileUrl: URL(string: "file://part")!,
                number: 1,
                sessionId: "foo",
                streamId: UUID(),
                status: .uploading
            )
            let sut = MUPartHandle(part: part, database: database)

            let operation = SyncPartOperation(
                part: part,
                fileType: .jpeg,
                sessionId: "foo"
            )

            // When
            _ = await sut.register(operation)

            try await Task.sleep(nanoseconds: 50_000_000)

            dependencies.eventEmitter.emit(StreamPartOperationEvent.uploading(partId: part.id))

            try await Task.sleep(nanoseconds: 100_000_000)

            // Then
            #expect(part.status == .uploading)
        }
    }

    @Test
    func testThatPartRemainsCompletedWhenCompletedEventIsReceived() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let part = StreamPartModel(
                localFileUrl: URL(string: "file://part")!,
                number: 1,
                sessionId: "foo",
                streamId: UUID(),
                status: .completed
            )
            let sut = MUPartHandle(part: part, database: database)
            let operation = SyncPartOperation(
                part: part,
                fileType: .jpeg,
                sessionId: "foo"
            )

            // When
            _ = await sut.register(operation)

            try await Task.sleep(nanoseconds: 50_000_000)

            dependencies.eventEmitter.emit(StreamPartOperationEvent.completed(partId: part.id))

            try await Task.sleep(nanoseconds: 100_000_000)

            // Then
            #expect(part.status == .completed)
        }
    }

    @Test
    func testThatUploadedEventSetsETagOnPart() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let sut = MUPartHandle(part: part, database: database)
            let operation = SyncPartOperation(
                part: part,
                fileType: .jpeg,
                sessionId: "foo"
            )
            let expectedETag = "etag-123"

            // When
            _ = await sut.register(operation)

            try await Task.sleep(nanoseconds: 50_000_000)

            dependencies.eventEmitter.emit(StreamPartOperationEvent.uploaded(partId: part.id, eTag: expectedETag))

            try await Task.sleep(nanoseconds: 100_000_000)

            // Then
            #expect(part.eTag == expectedETag)
        }
    }
}
