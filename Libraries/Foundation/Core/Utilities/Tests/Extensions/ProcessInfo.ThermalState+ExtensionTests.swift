//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable import Utilities

struct ProcessInfoThermalStateTests {
    // MARK: - Tests

    @Test
    func testThatThermalStateCriticalShouldReturnCorrectDebugDescription() {
        // Given, When, Then
        #expect(ProcessInfo.ThermalState.critical.debugDescription == "critical")
    }

    @Test
    func testThatThermalStateFairShouldReturnCorrectDebugDescription() {
        // Given, When, Then
        #expect(ProcessInfo.ThermalState.fair.debugDescription == "fair")
    }

    @Test
    func testThatThermalStateNominalShouldReturnCorrectDebugDescription() {
        // Given, When, Then
        #expect(ProcessInfo.ThermalState.nominal.debugDescription == "nominal")
    }

    @Test
    func testThatThermalStateSeriousShouldReturnCorrectDebugDescription() {
        // Given, When, Then
        #expect(ProcessInfo.ThermalState.serious.debugDescription == "serious")
    }
}
