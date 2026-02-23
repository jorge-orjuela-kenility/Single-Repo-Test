
//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import InternalUtilities
import MediaUploadTesting
import Testing
import TruVideoFoundation

@testable import TruVideoMediaUpload

struct PartRegistryTests {
    // MARK: - Properties

    let database = DatabaseMock()
    let partRegistry = PartRegistry()

    // MARK: - Tests

    @Test()
    func testThatRegisterAndValueForKeyShouldReturnRegisteredHandle() async throws {
        // Given
        let part = makePart()
        let handle = makeHandle(for: part)

        // When
        partRegistry.register(handle, for: part.id)
        let retrieved = partRegistry.value(forKey: part.id)

        // Then
        #expect(retrieved === handle)
    }

    @Test()
    func testThatRemoveValueShouldRemoveHandle() async throws {
        // Given
        let part = makePart()
        let handle = makeHandle(for: part)

        // When
        partRegistry.register(handle, for: part.id)
        partRegistry.removeValue(for: part.id)
        let retrieved = partRegistry.value(forKey: part.id)

        // Then
        #expect(retrieved == nil)
    }

    @Test()
    func testThatRegisteredPartsReturnsAllHandles() async throws {
        // Given
        let part1 = makePart()
        let part2 = makePart()
        let handle1 = makeHandle(for: part1)
        let handle2 = makeHandle(for: part2)

        partRegistry.register(handle1, for: part1.id)
        partRegistry.register(handle2, for: part2.id)

        // When
        let allHandles = partRegistry.registeredParts()

        // Then
        #expect(allHandles.count == 2)
        #expect(allHandles.contains(where: { $0 === handle1 }))
        #expect(allHandles.contains(where: { $0 === handle2 }))
    }

    @Test()
    func testThatIteratorShouldIterateOverAllRegisteredPartHandles() async throws {
        // Given
        var iteratedHandles: [MUPartHandle] = []
        let part1 = makePart()
        let part2 = makePart()
        let handle1 = makeHandle(for: part1)
        let handle2 = makeHandle(for: part2)

        // When
        partRegistry.register(handle1, for: part1.id)
        partRegistry.register(handle2, for: part2.id)

        for handle in partRegistry {
            iteratedHandles.append(handle)
        }

        // Then
        #expect(iteratedHandles.count == 2)
        #expect(iteratedHandles.contains(where: { $0 === handle1 }))
        #expect(iteratedHandles.contains(where: { $0 === handle2 }))
    }

    // MARK: Helper Method

    private func makePart(id: UUID = UUID()) -> StreamPartModel {
        StreamPartModel(
            localFileUrl: URL(string: "foo-\(id)")!,
            number: 1,
            sessionId: "foo",
            streamId: UUID(),
            status: .pending
        )
    }

    private func makeHandle(for part: StreamPartModel) -> MUPartHandle {
        MUPartHandle(part: part, database: database)
    }
}
