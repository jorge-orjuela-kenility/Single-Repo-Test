//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
import StorageKit
import Testing
import Utilities

@testable import Telemetry
@testable import TelemetryTesting

private final class TelemetryManagerTests {
    // MARK: - Private Properties

    private var contextProvider: ContextProviderMock!
    private let storageURL: URL
    private var subscriber: TelemetryManagerSubscriberMock!

    // MARK: - Initializer

    init() {
        contextProvider = ContextProviderMock()
        storageURL = FileManager.default.telemetryDirectory.appendingPathComponent("\(UUID()).json")
        subscriber = TelemetryManagerSubscriberMock()
    }

    // MARK: - Tests

    @Test
    func testThatBreadcrumbsRespectScopeBoundaries() async throws {
        await withDependencyValues { dependencies in
            // Given
            let endDate = Date()
            let installation = TelemetryInstallationMock()
            let sut = TelemetryManager(eventsBuffer: EventDiskBuffer(storageURL: storageURL), integrations: [])

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = installation
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.startSession()

            let breadcroumb = Breadcrumb(severity: .info, source: "initial-source", category: "initial-test")
            sut.capture(breadcroumb)

            sut.withScope {
                let breadcrumb = Breadcrumb(severity: .info, source: "source", category: "test")
                sut.capture(breadcrumb)
                sut.captureEvent(name: "event-a", source: "source-a")
            }

            sut.withScope {
                let breadcrumb = Breadcrumb(severity: .warning, source: "source-b", category: "test-b")
                sut.capture(breadcrumb)
                sut.captureEvent(name: "event-b", source: "source-b")
            }

            sut.capture(NSError(domain: "", code: 0), name: "error", source: "SEE")
            sut.endSession(at: endDate)

            // Then
            let firstScope = subscriber.receivedReports.first?.events.first { $0.name == "event-a" }
            #expect(firstScope?.breadcrumbs?.first { $0.source == "source-b" } == nil)
            #expect(firstScope?.breadcrumbs?.first { $0.source == "source" } != nil)
            #expect(firstScope?.breadcrumbs?.first { $0.source == "initial-source" } != nil)

            let secondScope = subscriber.receivedReports.first?.events.first { $0.name == "event-b" }
            #expect(secondScope?.breadcrumbs?.first { $0.source == "initial-source" } != nil)
            #expect(secondScope?.breadcrumbs?.first { $0.source == "source" } == nil)
            #expect(secondScope?.breadcrumbs?.first { $0.source == "source-b" } != nil)

            let globalScope = subscriber.receivedReports.first?.events.first { $0.name == "error" }
            #expect(globalScope?.breadcrumbs?.first { $0.source == "initial-source" } != nil)
            #expect(globalScope?.breadcrumbs?.first { $0.source == "source" } == nil)
            #expect(globalScope?.breadcrumbs?.first { $0.source == "source-b" } == nil)
        }
    }

    @Test
    func testThatFlushPreviousSessionEmitsSessionEndedEvent() async throws {
        await withDependencyValues { dependencies in
            // Given
            let endDate = Date()
            let event: TelemetryReport.Event?
            let report: TelemetryReport?
            let installation = TelemetryInstallationMock()
            let session = Session(installationId: installation.uniqueIdentifier())
            let sut = TelemetryManager(
                eventsBuffer: EventDiskBuffer(storageURL: storageURL),
                integrations: []
            )

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = installation
            dependencies.storage = InMemoryStorage()

            try! dependencies.storage.write(session, forKey: TelemetryManager.SessionStorageKey.self)

            sut.add(subscriber)
            sut.flushPreviousSession(endedAt: endDate)

            report = subscriber.receivedReports.first
            event = report?.events.first { $0.name == "session_ended" }

            // Then
            #expect(subscriber.receivedReports.count == 1)
            #expect(contextProvider.makeContextCallCount == 1)
            #expect(event?.message == "Discarded stale session from previous app run.")
            #expect(event?.severity == .info, "Expected event severity to be info")
            #expect(event?.source == "Telemetry", "Expected event source to be Telemetry")
            #expect(report?.session.endedAt == endDate)
        }
    }

    @Test
    func testThatEndSessionEmitsSessionEndedEvent() async throws {
        await withDependencyValues { dependencies in
            // Given
            let event: TelemetryReport.Event?
            let report: TelemetryReport?
            let endDate = Date()
            let sut = TelemetryManager(
                eventsBuffer: EventDiskBuffer(storageURL: storageURL),
                integrations: []
            )

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)

            sut.startSession()
            sut.endSession(at: endDate)

            report = subscriber.receivedReports.last!
            event = report?.events.first { $0.name == "session_ended" }

            // Then
            #expect(subscriber.receivedReports.count == 1)
            #expect(contextProvider.makeContextCallCount == 1)
            #expect(event?.severity == .info)
            #expect(event?.source == "Telemetry")
            #expect(report?.session.endedAt == endDate)
            #expect(try! dependencies.storage.readValue(for: TelemetryManager.SessionStorageKey.self) == nil)
        }
    }

    @Test
    func testThatEndSessionDoesNothingWhenNoActiveSession() async throws {
        await withDependencyValues { dependencies in
            // Given
            let sut = TelemetryManager(
                eventsBuffer: EventDiskBuffer(storageURL: storageURL),
                integrations: []
            )

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.endSession(at: Date())

            // Then
            #expect(contextProvider.makeContextCallCount == 0)
            #expect(subscriber.receivedReports.isEmpty)
        }
    }

    @Test
    func testThatRemoveSubscriberUnregistersSubscriber() async throws {
        await withDependencyValues { dependencies in
            // Given
            let sut = TelemetryManager(
                eventsBuffer: EventDiskBuffer(storageURL: storageURL),
                integrations: []
            )

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.startSession()
            sut.endSession(at: Date())

            sut.remove(subscriber)
            sut.startSession()
            sut.endSession(at: Date())

            // Then
            #expect(subscriber.receivedReports.count == 1)
        }
    }

    @Test
    func testThatCaptureEventEmitsEvent() async throws {
        await withDependencyValues { dependencies in
            // Given
            let event: TelemetryReport.Event?
            let eventsBuffer = EventDiskBuffer(storageURL: storageURL)
            let sut = TelemetryManager(eventsBuffer: eventsBuffer, integrations: [])

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.startSession()
            sut.captureEvent(name: "custom_event", source: "test_source", metadata: ["foo": "bar"])

            event = eventsBuffer.snapshot().first(where: { $0.name == "custom_event" })

            // Then
            #expect(event?.metadata?["foo"] == "bar")
            #expect(event?.source == "test_source")
        }
    }

    @Test
    func testThatCaptureMessageEmitsEventWithMessage() async throws {
        await withDependencyValues { dependencies in
            // Given
            let event: TelemetryReport.Event?
            let eventsBuffer = EventDiskBuffer(storageURL: storageURL)
            let sut = TelemetryManager(eventsBuffer: eventsBuffer, integrations: [])

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.startSession()
            sut.capture(
                "A test message",
                name: "message_event",
                source: "test_source",
                metadata: ["foo": "bar"]
            )

            event = eventsBuffer.snapshot().first(where: { $0.name == "message_event" })

            // Then
            #expect(event?.message == "A test message")
            #expect(event?.metadata?["foo"] == "bar")
            #expect(event?.source == "test_source")
        }
    }

    @Test
    func testThatCaptureErrorEmitsErrorEvent() async throws {
        await withDependencyValues { dependencies in
            // Given
            let event: TelemetryReport.Event?
            let eventsBuffer = EventDiskBuffer(storageURL: storageURL)
            let sut = TelemetryManager(eventsBuffer: eventsBuffer, integrations: [])
            let error = NSError(
                domain: "TestDomain",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Something went wrong"]
            )

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.capture(error, name: "error_event", source: "test_source", metadata: ["foo": .string("bar")])

            event = eventsBuffer.snapshot().first(where: { $0.name == "error_event" })

            // Then
            #expect(event?.severity == .error)
            #expect(event?.exception?.message == "Something went wrong")
            #expect(event?.metadata?["foo"] == "bar")
        }
    }

    @Test
    func testThatStartSessionCreatesSessionWhenNoneExists() async throws {
        await withDependencyValues { dependencies in
            // Given
            let event: TelemetryReport.Event?
            let eventsBuffer = EventDiskBuffer(storageURL: storageURL)
            let sut = TelemetryManager(eventsBuffer: eventsBuffer, integrations: [])

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.startSession()

            event = eventsBuffer.snapshot().first(where: { $0.name == "session_started" })

            // Then
            #expect(try! dependencies.storage.readValue(for: TelemetryManager.SessionStorageKey.self) != nil)
            #expect(event?.severity == .info)
            #expect(event?.source == "Telemetry")
        }
    }

    @Test
    func testThatStartSessionReplacesStaleSessionInStorage() async throws {
        await withDependencyValues { dependencies in
            // Given
            let session = Session(installationId: UUID())
            let eventsBuffer = EventDiskBuffer(storageURL: storageURL)
            let sut = TelemetryManager(eventsBuffer: eventsBuffer, integrations: [])

            // When
            dependencies.storage = InMemoryStorage()
            dependencies.installation = TelemetryInstallationMock()
            dependencies.contextProvider = contextProvider

            try! dependencies.storage.write(session, forKey: TelemetryManager.SessionStorageKey.self)

            sut.add(subscriber)
            sut.startSession()

            // Then
            #expect(try! dependencies.storage.readValue(for: TelemetryManager.SessionStorageKey.self) != session)
            #expect(eventsBuffer.snapshot().count(where: { $0.name == "session_started" }) == 1)
        }
    }

    @Test
    func testThatStartSessionDoesNothingIfSessionAlreadyExists() async throws {
        await withDependencyValues { dependencies in
            // Given
            let eventsBuffer = EventDiskBuffer(storageURL: storageURL)
            let sut = TelemetryManager(eventsBuffer: eventsBuffer, integrations: [])

            // When
            dependencies.contextProvider = contextProvider
            dependencies.installation = TelemetryInstallationMock()
            dependencies.storage = InMemoryStorage()

            sut.add(subscriber)
            sut.startSession()

            let firstSession = try! dependencies.storage.readValue(for: TelemetryManager.SessionStorageKey.self)

            sut.startSession()
            let secondSession = try! dependencies.storage.readValue(for: TelemetryManager.SessionStorageKey.self)

            // Then
            #expect(firstSession == secondSession)
            #expect(eventsBuffer.snapshot().count(where: { $0.name == "session_started" }) == 1)
        }
    }
}
