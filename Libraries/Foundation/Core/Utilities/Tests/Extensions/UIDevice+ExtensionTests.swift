//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Testing
import UIKit

@testable import Utilities

struct UIDeviceTests {
    // MARK: - Tests

    @Test
    func testThatFreeDiskSpaceShouldBeNonNegativeWhenQueried() {
        // Given, When
        let freeSpace = UIDevice.current.freeDiskSpace

        // Then
        #expect(freeSpace >= 0)
    }

    @Test
    func testThatCpuArchitectureShouldReturnValidValueWhenQueried() {
        // Given, When
        let architecture = UIDevice.current.cpuArchitecture

        // Then
        #expect(["arm64", "x86_64", "unknown"].contains(architecture))
    }

    @Test
    func testThatFreeMemoryShouldReturnPositiveValueWhenAvailable() {
        // Given, When
        let memory = UIDevice.current.freeMemory

        // Then
        #expect(memory != nil)
        #expect(memory! > 0)
    }

    @Test
    func testThatModelIdentifierShouldNotBeEmptyWhenQueried() {
        // Given, When
        let identifier = UIDevice.current.modelIdentifier

        // Then
        #expect(!identifier.isEmpty)
    }

    @Test
    func testThatTotalDiskSpaceShouldBeNonNegativeWhenQueried() {
        // Given, When
        let total = UIDevice.current.totalDiskSpace

        // Then
        #expect(total >= 0)
    }

    @Test
    func testThatBatteryStateChargingShouldReturnChargingDebugDescription() {
        // Given, When, Then
        #expect(UIDevice.BatteryState.charging.debugDescription == "charging")
    }

    @Test
    func testThatBatteryStateFullShouldReturnFullDebugDescription() {
        // Given, When, Then
        #expect(UIDevice.BatteryState.full.debugDescription == "full")
    }

    @Test
    func testThatBatteryStateUnpluggedShouldReturnUnpluggedDebugDescription() {
        // Given, When, Then
        #expect(UIDevice.BatteryState.unplugged.debugDescription == "unplugged")
    }

    @Test
    func testThatBatteryStateUnknownShouldReturnUnknownDebugDescription() {
        // Given, When, Then
        #expect(UIDevice.BatteryState.unknown.debugDescription == "unknown")
    }
}
