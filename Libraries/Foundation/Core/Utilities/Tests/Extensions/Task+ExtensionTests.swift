//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable import Utilities

struct TaskTests {
    // MARK: - Tests

    @Test
    func testThatDelayedShouldExecuteOperationAfterSpecifiedDelay() async {
        // Given
        let start = Date()

        // When
        let task = Task.delayed(milliseconds: 50) {
            Date()
        }

        let result = await task.value
        let elapsed = result.timeIntervalSince(start)

        // Then
        #expect(elapsed >= 0.05)
    }

    @Test
    func testThatDelayedShouldReturnOperationResultWhenCompleted() async {
        // When
        let task = Task.delayed(milliseconds: 10) {
            42
        }

        // When
        let result = await task.value

        // Then
        #expect(result == 42)
    }

    @Test
    func testThatDelayedShouldNotExecuteOperationImmediately() async throws {
        // Given
        var executed = false

        // When
        _ = Task.delayed(milliseconds: 50) {
            executed = true
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        // Then
        #expect(executed == false)
    }
}
