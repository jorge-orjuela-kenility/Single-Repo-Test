//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable import Utilities

struct FileManagerTests {
    // MARK: - Tests

    @Test
    func testThatTelemetryDirectoryShouldBeLocatedInCachesDirectoryWhenResolved() {
        // Given
        let fileManager = FileManager.default
        let cachesURL = fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!

        // When
        let telemetryURL = fileManager.telemetryDirectory

        // Then
        #expect(telemetryURL == cachesURL.appendingPathComponent("com.truvideo.telemetry"))
    }

    @Test
    func testThatTelemetryDirectoryShouldEndWithTelemetryFolderWhenResolved() {
        // Given
        let fileManager = FileManager.default

        // When
        let telemetryURL = fileManager.telemetryDirectory

        // Then
        #expect(telemetryURL.lastPathComponent == "com.truvideo.telemetry")
    }
}
