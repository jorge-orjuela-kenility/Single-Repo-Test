//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreData
import DI
import Foundation
import InternalUtilities
import MediaUploadTesting
import Testing
import TruVideoFoundation

@testable import TruVideoMediaUpload

struct MUStreamTests {
    // MARK: - Properties

    let database = DatabaseMock()
    let operationProducer = OperationProducerMock()
    let partRegistry = PartRegistry()
    let stream = StreamModel(fileType: .avi)

    // MARK: - Tests

    @Test
    func testThatRegisterPartShouldRegisterANewPart() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let sut = MUStream(
                stream: stream,
                database: database,
                operationProducer: operationProducer,
                partRegistry: partRegistry,
                streamsDirectoryURL: FileManager.default.temporaryDirectory
            )
            let part = StreamPartModel(
                localFileUrl: URL(string: "foo-bar")!,
                number: 1,
                sessionId: "foo",
                streamId: stream.id
            )

            // When
            dependencies.eventEmitter.emit(
                StreamOperationEvent.sessionCreated(
                    for: stream.id,
                    sessionId: "foo",
                    mediaId: UUID()
                )
            )

            try await Task.sleep(nanoseconds: 50_000_000)

            _ = await sut.registerPart(part)

            let registeredParts = partRegistry.registeredParts()
            _ = registeredParts.first

            // Then
            #expect(registeredParts.count > 0)
        }
    }

    @Test()
    func testThatAppendShouldReturnANewPartHandleOnSucceed() async throws {
        // Given
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let data = Data("Payload".utf8)

        // When / Then
        await #expect(throws: Never.self) {
            _ = try await sut.append(data)
        }
    }

    @Test()
    func testThatAppendShouldFailWhenStreamIsFailed() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .failed)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When, Then
        await #expect {
            try await sut.append(Data())
        } throws: { error in
            let error = error as! UtilityError

            return error.kind == .StreamErrorReason.failedToAppendData
        }
    }

    @Test()
    func testThatAppendShouldFailWhenStreamIsCancelled() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .cancelled)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When, Then
        await #expect {
            try await sut.append(Data())
        } throws: { error in
            let error = error as! UtilityError

            return error.kind == .StreamErrorReason.failedToAppendData
        }
    }

    @Test()
    func testThatAppendShouldFailWhenStreamIsCompleted() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .completed)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When, Then
        await #expect {
            try await sut.append(Data())
        } throws: { error in
            let error = error as! UtilityError

            return error.kind == .StreamErrorReason.failedToAppendData
        }
    }

    @Test()
    func testThatAppendShouldFailWhenStreamIsFinishing() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .finishing)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When, Then
        await #expect {
            try await sut.append(Data())
        } throws: { error in
            let error = error as! UtilityError

            return error.kind == .StreamErrorReason.failedToAppendData
        }
    }

    @Test()
    func testThatAppendContentsOfURLShouldReturnEmptyArrayWhenFileIsEmpty() async throws {
        // Given
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dat")
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)

        // When
        let handles = try await sut.append(contentsOf: fileURL)

        // Then
        #expect(handles.isEmpty)
    }

    @Test()
    func testThatAppendContentsOfURLShouldReturnSinglePartWhenFileIsSmallerThanChunkSize() async throws {
        // Given
        let data = Data("Payload".utf8)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dat")
        let chunkSize = 1024
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        try data.write(to: fileURL)

        // When
        let handles = try await sut.append(contentsOf: fileURL, chunkSize: chunkSize)

        // Then
        #expect(handles.count == 1)
    }

    @Test()
    func testThatAppendContentsOfURLShouldReturnCorrectNumberOfPartsWhenFileSizeIsExactMultipleOfChunkSize(
    ) async throws {
        // Given
        let chunkSize = 1024
        let numberOfChunks = 3
        let totalSize = chunkSize * numberOfChunks
        let data = Data(repeating: 0x1, count: totalSize)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dat")
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        try data.write(to: fileURL)

        // When
        let handles = try await sut.append(contentsOf: fileURL, chunkSize: chunkSize)

        // Then
        #expect(handles.count == numberOfChunks)
    }

    @Test()
    func testThatAppendContentsOfURLShouldSplitFileIntoMultipleChunks() async throws {
        // Given
        let chunkSize = 1024
        let totalSize = chunkSize + 512
        let data = Data(repeating: 0x2, count: totalSize)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dat")
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        try data.write(to: fileURL)

        // When
        let handles = try await sut.append(contentsOf: fileURL, chunkSize: chunkSize)

        // Then
        #expect(handles.count == 2)
    }

    @Test()
    func testThatAppendContentsOfURLShouldUseMaxChunkSizeWhenNumberOfPartsExceedsLimit() async throws {
        // Given
        let chunkSize = 1
        let totalSize = 10_000
        let maxNumberOfParts = 120
        let data = Data(repeating: 0x2, count: totalSize)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dat")
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        try data.write(to: fileURL)

        // When
        let handles = try await sut.append(contentsOf: fileURL, chunkSize: chunkSize)

        // Then
        #expect(!handles.isEmpty)
        #expect(handles.count <= maxNumberOfParts)
    }

    @Test()
    func testThatAppendContentsOfURLShouldThrowWhenStreamIsFailed() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .failed)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dat")
        let data = Data("Payload".utf8)
        try data.write(to: url)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When / Then
        await #expect {
            try await sut.append(contentsOf: url)
        } throws: { error in
            let utilityError = error as? UtilityError
            return utilityError?.kind == .StreamErrorReason.failedToAppendContentsOfURL
        }
    }

    @Test()
    func testThatCancelSShouldCancelStreamAndRegisteredParts() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .running)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: stream.id
        )

        // When
        _ = await sut.registerPart(part)

        sut.cancel()

        try await Task.sleep(nanoseconds: 500_000_000)

        let partHandle = try await database.find(StreamPartModel.self, with: part.id)

        #expect(stream.status == .cancelled)
        #expect(partHandle.status == .cancelled)
    }

    @Test()
    func testThatCancelShouldRestoreStatusWhenDatabaseSaveFails() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .running)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When
        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.cancel()

        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        #expect(stream.status == .running)
    }

    @Test()
    func testThatFinishShouldRestoreStreamStatusIfDatabaseSaveFails() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .failed)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When
        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.finish()

        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        #expect(stream.status == .failed)
    }

    @Test()
    func testThatResumeStreamShouldResumeStream() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .suspended)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: stream.id
        )

        // When
        _ = await sut.registerPart(part)

        sut.resume()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        #expect(stream.status == .running)
    }

    @Test()
    func testThatResumeShouldRestoreStreamStatusIfDatabaseSaveFails() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .suspended)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: stream.id
        )

        // When
        _ = await sut.registerPart(part)

        let registeredParts = partRegistry.registeredParts()
        let handle = registeredParts.first

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.resume()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        #expect(stream.status == .suspended)
        #expect(handle?.status == .pending)
    }

    @Test()
    func testThatSuspendStreamShouldSuspendStreamAndRegisteredParts() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .running)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: stream.id
        )

        // When
        _ = await sut.registerPart(part)

        sut.suspend()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let partHandle = try await database.find(StreamPartModel.self, with: part.id)

        // Then
        #expect(stream.status == .suspended)
        #expect(partHandle.status == .suspended)
    }

    @Test()
    func testThatSuspendShouldRestoreStreamStatusIfDatabaseSaveFails() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .running)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: stream.id
        )

        // When
        _ = await sut.registerPart(part)

        let registeredParts = partRegistry.registeredParts()
        let handle = registeredParts.first

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.suspend()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        #expect(stream.status == .running)
        #expect(handle?.status == .pending)
    }

    @Test
    func testThatObservePartsEmitsWhenAppendingData() async throws {
        // Given
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When
        let partsStream = sut.observeParts()
        var iterator = partsStream.makeAsyncIterator()

        _ = await iterator.next()

        let handle = try await sut.append(Data("payload".utf8))

        let updated = await iterator.next()

        // Then
        #expect(updated?.count == 1)
        #expect(updated?.first?.id == handle.id)
    }

    @Test
    func testThatFinishCompletesObservePartsStream() async throws {
        // Given
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )

        // When
        let partsStream = sut.observeParts()
        var iterator = partsStream.makeAsyncIterator()

        _ = await iterator.next()

        sut.finish()

        // Then
        let afterFinish = await iterator.next()
        #expect(afterFinish == nil)
    }

    @Test
    func testThatFinishRestoresStreamStatusIfDatabaseSaveFails() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .suspended)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "foo-bar")!,
            number: 1,
            sessionId: "foo",
            streamId: stream.id
        )

        // When
        _ = await sut.registerPart(part)

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        sut.finish()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        #expect(stream.status == .suspended)
    }

    @Test
    func testThatStreamTransitionsToCompletedWhenCompletedEventIsReceived() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let stream = StreamModel(fileType: .avi, status: .running)
            _ = MUStream(
                stream: stream,
                database: database,
                operationProducer: operationProducer,
                partRegistry: partRegistry,
                streamsDirectoryURL: FileManager.default.temporaryDirectory
            )

            // When
            try await Task.sleep(nanoseconds: 500_000_000)

            dependencies.eventEmitter.emit(StreamOperationEvent.completed(streamId: stream.id))

            try await Task.sleep(nanoseconds: 500_000_000)

            // Then
            #expect(stream.completedAt != nil)
            #expect(stream.status == .completed)
        }
    }

    @Test
    func testThatStreamSuspendsWhenAllActivePartsAreSuspended() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .running)
        _ = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "file://part")!,
            number: 1,
            sessionId: "s",
            streamId: stream.id,
            status: .suspended
        )

        // When
        try await database.save(part)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(part.status == .suspended)
    }

    @Test
    func testThatFailedPartWithMaxAttemptsRemainsFailed() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .running)
        let sut = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "file://part")!,
            number: 1,
            sessionId: "s",
            streamId: stream.id,
            attempts: 6,
            status: .failed
        )

        // When
        _ = await sut.registerPart(part)

        try await database.save(part)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(part.status == .failed)
        #expect(part.attempts == 6)
    }

    @Test
    func testThatStreamResumesWhenRetryingPartExistsAndStreamIsSuspended() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .suspended)
        _ = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "file://part")!,
            number: 1,
            sessionId: "session",
            streamId: stream.id,
            attempts: 1,
            status: .retrying
        )

        // When
        try await database.save(part)

        try await Task.sleep(nanoseconds: 100_000_000)

        await database.setError(UtilityError(kind: .DatabaseError.saveFailed))

        // Then
        #expect(stream.status == .running)
    }

    @Test
    func testThatStreamCancelsWhenCancelledPartIsDetected() async throws {
        // Given
        let stream = StreamModel(fileType: .avi, status: .running)
        _ = MUStream(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry,
            streamsDirectoryURL: FileManager.default.temporaryDirectory
        )
        let part = StreamPartModel(
            localFileUrl: URL(string: "file://part")!,
            number: 1,
            sessionId: "session",
            streamId: stream.id,
            status: .cancelled
        )

        // When
        try await database.save(part)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(stream.status == .cancelled)
        #expect(part.status == .cancelled)
    }
}
