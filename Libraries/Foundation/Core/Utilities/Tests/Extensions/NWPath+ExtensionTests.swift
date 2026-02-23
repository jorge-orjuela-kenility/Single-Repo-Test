//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Network
import Testing

@testable import Utilities

struct NWPathTests {
    // MARK: - Tests

    @Test
    func testThatNWPathStatusRequiresConnectionShouldReturnCorrectDebugDescription() {
        // Given, When, Then
        #expect(NWPath.Status.requiresConnection.debugDescription == "requiresConnection")
    }

    @Test
    func testThatNWPathStatusSatisfiedShouldReturnCorrectDebugDescription() {
        // Given, When, Then
        #expect(NWPath.Status.satisfied.debugDescription == "satisfied")
    }

    @Test
    func testThatNWPathStatusUnsatisfiedShouldReturnCorrectDebugDescription() {
        // Given, When, Then
        #expect(NWPath.Status.unsatisfied.debugDescription == "unsatisfied")
    }
}
