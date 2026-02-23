//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

@testable import Telemetry

/// A mock subclass of `TelemetryManager` used for testing session lifecycle behavior.
public final class TelemetryManagerMock: TelemetryManager, @unchecked Sendable {
    // MARK: - Private Properties

    private let lock = NSLock()

    // MARK: - Properties

    /// Stores all breadcrumbs captured.
    private(set) var capturedBreadcrumbs: [Breadcrumb] = []

    /// Indicates whether `startSession()` was called.
    private(set) var didStartSession = false

    /// Records the date passed to `endSession(at:)` when called.
    private(set) var endedSessionAt: Date?

    // MARK: - Overriden Methods

    /// Overrides `startSession()` to set `didStartSession` to `true`.
    override public func startSession() {
        didStartSession = true
    }

    /// Overrides `endSession(at:)` to store the passed `date` in `endedSessionAt`.
    override public func endSession(at date: Date) {
        endedSessionAt = date
    }

    override public func capture(_ breadcrumb: Breadcrumb) {
        lock.lock()
        defer { lock.unlock() }

        capturedBreadcrumbs.append(breadcrumb)
    }
}
