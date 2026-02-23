//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
import StorageKit
import TruVideoFoundation
import Utilities

/// A central manager for collecting, buffering, and dispatching telemetry data throughout the application.
///
/// The `TelemetryManager` coordinates the capture of telemetry events, contextual information, and breadcrumbs.
/// It allows subscribers to receive structured `TelemetryReport` instances, making it suitable for error
/// reporting, logging, analytics, and observability.
///
/// This class also supports pluggable `TelemetryIntegration`s to hook into system-level events like app
/// lifecycle changes, connectivity status, memory warnings, and more.
///
/// ## Responsibilities
/// - Captures structured events and exceptions
/// - Manages a breadcrumb buffer to include historical context for critical events
/// - Provides contextual system and device data via a `ContextProvider`
/// - Dispatches telemetry reports to registered `TelemetryManagerSubscriber`s
/// - Installs telemetry integrations for passive event collection
///
/// ## Example
/// ```swift
/// TelemetryManager.shared.capture("User signed in", name: "auth.success", source: "auth.screen")
/// ```
open class TelemetryManager: @unchecked Sendable {
    // MARK: - Private Properties

    private let dataInterceptor: [DataInterceptor]
    private let eventFlushInterval: TimeInterval = 180
    private var eventsBuffer: EventDiskBuffer
    private let lock = NSLock()
    private var previousFlushDate: Date?
    private var session: Session?
    private var subscribers: [ObjectIdentifier: any TelemetryManagerSubscriber] = [:]

    // MARK: - Dependencies

    @Dependency(\.contextProvider)
    private var contextProvider: ContextProvider

    @Dependency(\.installation)
    private var installation: TelemetryInstallation

    @Dependency(\.storage)
    private var storage: Storage

    // MARK: - Properties

    /// A list of telemetry integrations that automatically install when the manager is initialized.
    let integrations: [any TelemetryIntegration]

    // MARK: - Static Properties

    /// The shared singleton instance of `TelemetryManager` used across the app or SDK.
    public static let shared = TelemetryManager()

    // MARK: - Task-Local Telemetry Context

    /// A task-local container that holds the currently active `TelemetryScope`.
    ///
    /// This property uses Swift Concurrency’s `@TaskLocal` to associate a `TelemetryScope`
    /// with the lifetime of the current task and its child tasks. It provides an
    /// ambient execution context for telemetry data such as breadcrumbs, tags,
    /// and metadata without requiring the scope to be passed explicitly through
    /// the call stack.
    ///
    /// ### Behavior
    /// - The value is only available within the dynamic extent of a
    ///   `TaskLocal.withValue` closure.
    /// - The scope is automatically propagated to child tasks created with `Task {}`.
    /// - The scope is **not** propagated to detached tasks (`Task.detached`) or
    ///   legacy concurrency mechanisms (e.g. GCD, delegates, callbacks).
    /// - When the task-local context ends, the previous scope is automatically restored.
    ///
    /// ### Usage
    /// ```swift
    /// let scoped = TelemetryScopeContext.scope.copy()
    ///
    /// TelemetryScopeContext.$scope.withValue(scoped) {
    ///     TelemetryScopeContext.scope.addBreadcrumb(...)
    /// }
    /// ```
    ///
    /// This design enables safe, structured telemetry scoping while preserving
    /// isolation between concurrent tasks.
    ///
    /// - Important: The task-local scope must not be stored or accessed outside
    ///   the lifetime of its task-local context.
    @TaskLocal static var scope = TelemetryScope()

    // MARK: - Types

    /// A key used for storing session information for telemetry or analytics purposes.
    struct SessionStorageKey: StorageKey {
        /// The associated value type that will be stored and retrieved using this key.
        typealias Value = Session
    }

    // MARK: - Initializer

    /// Initializes a new instance of `TelemetryManager` with custom dependencies.
    ///
    /// This initializer allows you to configure the telemetry manager with a custom
    /// breadcrumb buffer, runtime context provider, installation identifier provider,
    /// and any number of telemetry integrations. These components work together to collect,
    /// enrich, and forward telemetry data such as errors, events, and system changes.
    ///
    /// - Parameters:
    ///   - dataInterceptor: An instance of `DataInterceptor` responsible for redacting
    ///   or sanitizing PII before the data is sent.
    ///   - eventsBuffer: An instane of `EventDiskBuffer` used to collect recent events.
    ///   - integrations: A list of telemetry integrations conforming to `TelemetryIntegration`, responsible for hooking
    /// into various system events.
    init(
        dataInterceptor: [DataInterceptor] = [SensitiveDataInterceptor()],
        eventsBuffer: EventDiskBuffer,
        integrations: [any TelemetryIntegration] = [AutoSessionTrackerIntegration(), SystemEventTrackerIntegration()]
    ) {
        self.dataInterceptor = dataInterceptor
        self.eventsBuffer = eventsBuffer
        self.integrations = integrations

        integrations.forEach { $0.install(on: self) }
    }

    /// Initializes a default instance using the standard breadcrumb buffer and runtime context provider.
    public convenience init() {
        self.init(eventsBuffer: EventDiskBuffer())
    }

    // MARK: - Instance methods

    /// Finalizes and reports any previously stored session that differs from the currently active session.
    ///
    /// This method checks whether a previously stored session exists in `sessionStorage` and ensures it is
    /// not the same as the currently active `session`. If such a session exists, it marks the session as ended
    /// at the given date, emits a `TelemetryReport.Event` indicating that the session ended, and sends
    /// the completed session report to the telemetry manager.
    ///
    /// This is typically useful for recovery scenarios where the app may have been terminated or suspended
    /// before a session could be properly closed.
    ///
    /// - Parameter date: The date to mark as the session's end time.
    func flushPreviousSession(endedAt date: Date) {
        lock.lock()
        defer { lock.unlock() }

        if var storedSession = try? storage.readValue(for: SessionStorageKey.self), storedSession != session {
            let event = TelemetryReport.Event(
                name: "session_ended",
                severity: .info,
                source: "Telemetry",
                message: "Discarded stale session from previous app run."
            )

            storedSession.endSession(at: date)
            eventsBuffer.add(event)

            deleteStoredSession()
            flushSession(storedSession, force: true)
        }
    }

    /// Ends the current telemetry session at the specified date.
    ///
    /// This method locks the session state to ensure thread safety. It attempts to retrieve the current session
    /// from storage and update its `endedAt` timestamp. If an in-memory session exists, it also ends and clears it.
    /// Additionally, it sends a `"session_ended"` telemetry event to subscribers and deletes the session from storage.
    ///
    /// - Parameter date: The timestamp at which the session is considered ended.
    func endSession(at date: Date) {
        lock.lock()
        defer { lock.unlock() }

        guard var currentSession = session else { return }

        currentSession.endSession(at: date)

        let event = TelemetryReport.Event(name: "session_ended", severity: .info, source: "Telemetry")

        TelemetryManager.scope.removeBreadcrumbs()
        eventsBuffer.add(event)
        flushSession(currentSession, force: true)

        session = nil
        do {
            try storage.deleteValue(for: SessionStorageKey.self)
        } catch {
            // Consider logging or surfacing the error for observability.
        }
    }

    /// Starts a new telemetry session.
    ///
    /// This method initializes a new `Session` with a unique installation identifier
    /// and stores it both in memory and persistent storage. It ensures thread safety and
    /// avoids overwriting an existing active session.
    func startSession() {
        lock.lock()
        defer { lock.unlock() }

        if var storedSession = try? storage.readValue(for: SessionStorageKey.self), storedSession != session {
            storedSession.endSession(status: .exited)

            flushSession(storedSession, force: true)
            deleteStoredSession()
        }

        guard session == nil else { return }

        let newSession = Session(installationId: installation.uniqueIdentifier())
        let event = TelemetryReport.Event(name: "session_started", severity: .info, source: "Telemetry")

        sendEvent(event)
        session = newSession

        do {
            try storage.write(newSession, forKey: SessionStorageKey.self)
        } catch {
            // Consider logging or surfacing the error for observability.
        }
    }

    // MARK: - Public methods

    /// Registers a telemetry subscriber to receive `TelemetryReport` events.
    ///
    /// - Parameter subscriber: An object conforming to `TelemetryManagerSubscriber`.
    public func add(_ subscriber: any TelemetryManagerSubscriber) {
        subscribers[ObjectIdentifier(subscriber)] = subscriber
    }

    /// Captures a breadcrumb and appends it to the internal buffer asynchronously.
    ///
    /// - Parameter breadcrumb: A `Breadcrumb` representing a contextual event.
    open func capture(_ breadcrumb: Breadcrumb) {
        TelemetryManager.scope.addBreadcrumb(breadcrumb)
    }

    /// Captures a basic informational event without an exception.
    ///
    /// - Parameters:
    ///   - name: The name of the event.
    ///   - source: The logical source of the event (e.g., module or component name).
    ///   - metadata: Optional structured metadata.
    open func captureEvent(name: String, source: String, metadata: Metadata? = nil) {
        let event = TelemetryReport.Event(
            name: name,
            severity: .info,
            source: source,
            breadcrumbs: TelemetryManager.scope.snapshotBreadcrumbs(),
            metadata: TelemetryManager.scope.merge(metadata)
        )

        sendEvent(event)
    }

    /// Captures a basic informational event without an exception.
    ///
    /// - Parameters:
    ///   - message: A descriptive message for the event.
    ///   - name: The name of the event.
    ///   - source: The logical source of the event (e.g., module or component name).
    ///   - metadata: Optional structured metadata.
    open func capture(_ message: String, name: String, source: String, metadata: Metadata? = nil) {
        let event = TelemetryReport.Event(
            name: name,
            severity: .info,
            source: source,
            message: message,
            breadcrumbs: TelemetryManager.scope.snapshotBreadcrumbs(),
            metadata: TelemetryManager.scope.merge(metadata)
        )

        sendEvent(event)
    }

    /// Captures an error event with an associated exception and optional stack trace.
    ///
    /// - Parameters:
    ///   - error: The error object to capture.
    ///   - name: A unique event identifier.
    ///   - source: The logical source of the error.
    ///   - metadata: Optional structured metadata.
    ///   - stackFrame: Optional stack frame information.
    open func capture(
        _ error: Error,
        name: String,
        source: String,
        metadata: Metadata? = nil,
        stackFrame: StackFrame = StackFrame()
    ) {
        let event = TelemetryReport.Event(
            name: name,
            severity: .error,
            source: source,
            breadcrumbs: TelemetryManager.scope.snapshotBreadcrumbs(),
            exception: TelemetryReport.Event.Exception(message: error.localizedDescription, stackFrame: stackFrame),
            metadata: TelemetryManager.scope.merge(metadata)
        )

        sendEvent(event)
    }

    /// Captures an error event with an associated exception and optional stack trace.
    ///
    /// - Parameters:
    ///   - error: The error object to capture.
    ///   - name: A unique event identifier.
    ///   - source: The logical source of the error.
    ///   - metadata: Optional structured metadata.
    ///   - stackFrame: Optional stack frame information.
    open func capture(
        _ error: some Error & CustomDebugStringConvertible,
        name: String,
        source: String,
        metadata: Metadata? = nil,
        stackFrame: StackFrame = StackFrame()
    ) {
        let event = TelemetryReport.Event(
            name: name,
            severity: .error,
            source: source,
            breadcrumbs: TelemetryManager.scope.snapshotBreadcrumbs(),
            exception: TelemetryReport.Event.Exception(message: error.debugDescription, stackFrame: stackFrame),
            metadata: TelemetryManager.scope.merge(metadata)
        )

        sendEvent(event)
    }

    /// Creates a temporary scope for the duration of the provided operation.
    ///
    /// The current scope is copied and pushed as the active scope. Any breadcrumbs, tags,
    /// or metadata added within the closure will apply only to that scope and will be
    /// discarded once the operation completes.
    ///
    /// - Parameter operation: A closure to execute within the new scope.
    public func withScope(operation: () -> Void) {
        let scope = TelemetryScope(scope: TelemetryManager.scope)

        TelemetryManager.$scope.withValue(scope) {
            operation()
        }
    }

    /// Creates a temporary scope for the duration of the provided asynchronous operation.
    ///
    /// The current scope is copied and pushed as the active scope. Any breadcrumbs, tags,
    /// or metadata added within the closure will apply only to that scope and will be
    /// discarded once the operation completes.
    ///
    /// - Parameter operation: An async closure to execute within the new scope.
    /// - Returns: The result of the operation.
    public func withScope<T>(operation: () async throws -> T) async rethrows -> T {
        let scope = TelemetryScope(scope: TelemetryManager.scope)

        return try await TelemetryManager.$scope.withValue(scope) {
            try await operation()
        }
    }

    /// Sets a tag in the current active scope.
    ///
    /// Tags are key-value pairs used for indexing and filtering events.
    /// If a scope is currently active (via `withScope`), the tag is added to that scope.
    /// Otherwise, it is added to the global scope.
    ///
    /// - Parameters:
    ///   - value: The value of the tag.
    ///   - key: The key of the tag.
    public func setTag(_ value: String, for key: String) {
        TelemetryManager.scope.setTag(value, for: key)
    }

    /// Sets metadata in the current active scope.
    ///
    /// Metadata provides additional structured context for events.
    /// If a scope is currently active, the metadata is added to that scope.
    /// Otherwise, it is added to the global scope.
    ///
    /// - Parameters:
    ///   - value: The metadata value.
    ///   - key: The key for the metadata.
    public func setMetadata(_ value: MetadataValue, for key: String) {
        TelemetryManager.scope.setMetadata(value, for: key)
    }

    /// Adds a breadcrumb to the current active scope.
    ///
    /// Breadcrumbs track the history of events leading up to an error or report.
    ///
    /// - Parameter breadcrumb: The breadcrumb to add.
    public func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        TelemetryManager.scope.addBreadcrumb(breadcrumb)
    }

    /// Removes a previously registered subscriber.
    ///
    /// - Parameter subscriber: The subscriber instance to remove.
    public func remove(_ subscriber: any TelemetryManagerSubscriber) {
        let identifier = ObjectIdentifier(subscriber)

        subscribers.removeValue(forKey: identifier)
    }

    // MARK: - Private methods

    private func deleteStoredSession() {
        do {
            try storage.deleteValue(for: SessionStorageKey.self)
        } catch {
            // Consider logging or surfacing the error for observability.
        }
    }

    private func flushSession(_ session: Session, force: Bool = false) {
        let lastFlushDate = previousFlushDate ?? Date()
        let needsFlush = Date().timeIntervalSince(lastFlushDate) > eventFlushInterval

        if eventsBuffer.isFull || force || needsFlush {
            var session = session
            let events = eventsBuffer.snapshot()

            session.errors = events.count { [.critical, .error].contains($0.severity) }

            var report = TelemetryReport(events: events, context: contextProvider.makeContext(), session: session)

            for interceptor in dataInterceptor {
                report = interceptor.intercept(report)
            }

            subscribers.values.forEach { $0.didReceive(report) }

            eventsBuffer.flush()
            previousFlushDate = Date()
        }
    }

    private func sendEvent(_ event: TelemetryReport.Event) {
        eventsBuffer.add(event)

        if let session {
            flushSession(session)
        }
    }
}

/// A disk-backed buffer for storing telemetry events using a ring buffer structure.
///
/// The `EventDiskBuffer` maintains a fixed-size in-memory ring buffer to hold recent telemetry events,
/// and persists each event to disk in newline-delimited JSON format. This allows recovery of events
/// after app restarts or crashes.
///
/// Events are written to a file (`events.json`) located in the telemetry directory. Upon initialization,
/// any existing events in that file are loaded back into memory.
///
/// This buffer is useful for scenarios where event loss is undesirable and recovery of telemetry data is needed
/// between sessions or application restarts.
final class EventDiskBuffer {
    // MARK: - Private Properties

    private var buffer = RingBuffer<TelemetryReport.Event>(maxCapacity: 100)
    private let decoder = JSONDecoder()
    private let storageURL: URL

    // MARK: - Dependencies

    @Dependency(\.fileWriter)
    private var fileWriter: FileWriter

    // MARK: - Computed Properties

    /// A boolean indicating if the ring is full.
    var isFull: Bool {
        buffer.isFull
    }

    // MARK: - Initializer

    /// Creates a new disk-backed telemetry buffer.
    ///
    /// - Parameter storageURL: The root directory for storing events. Defaults to the app's telemetry directory.
    init(storageURL: URL = FileManager.default.telemetryDirectory) {
        self.storageURL = storageURL.appendingPathComponent("events.json")

        rehydrate()
    }

    // MARK: - Instance methods

    /// Adds a telemetry event to the in-memory buffer and persists it to disk.
    ///
    /// - Parameter event: The telemetry event to store.
    func add(_ event: TelemetryReport.Event) {
        buffer.add(event)

        do {
            try fileWriter.write(event, to: storageURL)
        } catch {
            // Logging could be added here to capture the failure reason.
        }
    }

    /// Clears all telemetry events from memory and removes the backing file from disk.
    func flush() {
        buffer.removeAll()

        do {
            try FileManager.default.removeItem(at: storageURL)
            FileManager.default.createFile(atPath: storageURL.path, contents: nil)
        } catch {
            // Logging could be added here to capture the failure reason.
        }
    }

    /// Returns a snapshot of the current buffered events, excluding nil entries.
    ///
    /// - Returns: An array containing all stored telemetry events.
    func snapshot() -> [TelemetryReport.Event] {
        buffer.snapshot()
    }

    // MARK: - Private methods

    private func rehydrate() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }

        do {
            let data = try Data(contentsOf: storageURL)
            let lines = data.split(separator: UInt8(ascii: "\n"))

            for line in lines {
                do {
                    let event = try decoder.decode(TelemetryReport.Event.self, from: Data(line))

                    buffer.add(event)
                } catch {
                    // Logging could be added here to capture the failure reason.
                }
            }
        } catch {
            // Logging could be added here to capture the failure reason.
        }
    }
}

/// A thread-safe container for contextual telemetry data.
///
/// `TelemetryScope` manages the collection of breadcrumbs, metadata, and tags that provide context
/// for telemetry events. It allows for the accumulation of data within a specific execution scope,
/// ensuring that events captured within that scope are enriched with the relevant context.
///
/// This class is thread-safe and can be shared across concurrent tasks. It supports creating copies
/// to branch context for new asynchronous operations (e.g., via `TelemetryScopeContext`).
public final class TelemetryScope: @unchecked Sendable {
    // MARK: - Private Properties

    private var _breadcrumbs: RingBuffer<Breadcrumb>
    private var _metadata: Metadata
    private var _tags: [String: String]
    private let lock = NSLock()

    // MARK: - Computed Properties

    private(set) var breadcrumbs: RingBuffer<Breadcrumb> {
        get { lock.withLock { _breadcrumbs } }
        set { lock.withLock { _breadcrumbs = newValue } }
    }

    private(set) var metadata: Metadata {
        get { lock.withLock { _metadata } }
        set { lock.withLock { _metadata = newValue } }
    }

    private(set) var tags: [String: String] {
        get { lock.withLock { _tags } }
        set { lock.withLock { _tags = newValue } }
    }

    // MARK: - Initializer

    /// Initializes a new telemetry scope with optional initial data.
    ///
    /// - Parameters:
    ///   - breadcrumbs: A buffer of existing breadcrumbs. Defaults to an empty buffer.
    ///   - metadata: Initial metadata dictionary. Defaults to empty.
    ///   - tags: Initial tags dictionary. Defaults to empty.
    init(
        breadcrumbs: RingBuffer<Breadcrumb> = RingBuffer(),
        metadata: Metadata = [:],
        tags: [String: String] = [:]
    ) {
        self._breadcrumbs = breadcrumbs
        self._metadata = metadata
        self._tags = tags
    }

    init(scope: TelemetryScope) {
        self._breadcrumbs = scope.breadcrumbs
        self._metadata = scope.metadata
        self._tags = scope.tags
    }

    // MARK: - Instance methods

    /// Clear all breadcrumbs from the scope.
    func removeBreadcrumbs() {
        breadcrumbs.removeAll()
    }

    /// Adds a breadcrumb to the scope's history.
    ///
    /// The breadcrumb is stored in a ring buffer, meaning oldest breadcrumbs may be evicted
    /// if the buffer reaches its capacity.
    ///
    /// - Parameter breadcrumb: The breadcrumb to record.
    func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        breadcrumbs.add(breadcrumb)
    }

    /// Sets a tag value for a specific key in the scope.
    ///
    /// Tags are simple string key-value pairs used for indexing and filtering telemetry events.
    ///
    /// - Parameters:
    ///   - value: The string value of the tag.
    ///   - key: The unique key for the tag.
    func setTag(_ value: String, for key: String) {
        tags[key] = value
    }

    /// Sets a metadata value for a specific key in the scope.
    ///
    /// Metadata allows attaching arbitrary structured data to telemetry events for deeper analysis.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key identifying the metadata item.
    func setMetadata(_ value: MetadataValue, for key: String) {
        metadata[key] = value
    }

    /// Returns a snapshot of all recorded breadcrumbs in the current scope.
    ///
    /// - Returns: An array of `Breadcrumb` objects currently in the buffer.
    func snapshotBreadcrumbs() -> [Breadcrumb] {
        breadcrumbs.snapshot()
    }

    /// Merges the scope's current metadata with an additional dictionary.
    ///
    /// Usage:
    /// This is typically used when capturing an event that has its own local metadata,
    /// allowing it to inherit the scope's metadata as a baseline.
    ///
    /// - Parameter other: Additional metadata to merge on top of the scope's metadata.
    ///   If keys collide, the values from `other` take precedence.
    /// - Returns: A new `Metadata` dictionary containing the merged results.
    func merge(_ other: Metadata?) -> Metadata {
        guard let other else { return metadata }

        return metadata.merging(other) { _, new in new }
    }
}
