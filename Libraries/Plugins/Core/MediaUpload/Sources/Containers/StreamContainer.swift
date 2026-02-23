//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import DI
import Foundation
import TruVideoFoundation
internal import Utilities

/// A container that manages media upload streams and coordinates their synchronization.
///
/// `StreamContainer` serves as the central manager for creating, retrieving, and managing `MUStream` instances
/// that handle multipart media uploads. It provides a high-level interface for stream lifecycle management,
/// coordinates with a synchronization engine for background uploads, and maintains an in-memory cache of
/// active streams for efficient access.
///
/// The container uses Core Data for persistent storage of stream metadata and parts, ensuring that upload
/// progress is preserved across app launches. It automatically enqueues pending operations on initialization
/// and subscribes to stream completion events to maintain accurate state tracking.
///
/// ## Stream Lifecycle
///
/// Streams are created through `newStream(of:)` and stored in the database. Active streams (those in
/// `.running` or `.ready` status) are kept in memory for fast access, while inactive streams are loaded
/// from the database when needed. The container automatically manages the transition between active and
/// inactive states based on stream status changes.
///
/// ## Synchronization
///
/// The container integrates with a `SyncEngine` that handles background synchronization of stream parts
/// to remote servers. When a stream is created or retrieved, its associated operation producer is
/// automatically registered with the sync engine to enable automatic upload coordination.
///
/// ## Usage
///
/// ```swift
/// // Create a container instance
/// let container = StreamContainer()
///
/// // Create a new stream for video upload
/// let stream = try await container.newStream(of: .video)
///
/// // Append data to the stream
/// try await stream.append(videoData)
///
/// // Retrieve all active streams
/// let activeStreams = try await container.retrieveStreams { stream in
///     stream.status == .running
/// }
/// ```
open class StreamContainer: @unchecked Sendable {
    // MARK: - Private Properties

    private let database: any Database
    private let state = State()
    private let streamsDirectoryURL: URL
    private let syncEngine: SyncEngine

    // MARK: - Dependencies

    @Dependency(\.eventEmitter)
    private var eventEmitter: EventEmitter

    // MARK: - Static Properties

    /// Shared singleton instance of `StreamContainer`.
    ///
    /// Use this instance for app-wide stream management and upload coordination.
    public static let shared = StreamContainer()

    // MARK: - Types

    /// An actor that provides thread-safe access to the container's active streams cache.
    ///
    /// This actor serializes access to the in-memory collection of active streams, ensuring
    /// thread-safe modifications and reads. Active streams are those currently in `.running`
    /// or `.ready` status and are kept in memory for efficient access without requiring
    /// database queries.
    ///
    /// The actor isolation guarantees that concurrent access to the active streams dictionary
    /// is safe, preventing data races when multiple threads access or modify the stream cache
    /// simultaneously.
    private actor State {
        /// A dictionary mapping stream identifiers to their corresponding `MUStream` instances.
        ///
        /// This dictionary maintains an in-memory cache of active streams for fast access.
        /// Streams are automatically added when created or retrieved in an active state, and
        /// removed when they complete or are cancelled.
        var activeStreams: [UUID: MUStream] = [:]
    }

    // MARK: - Initializer

    /// Creates a new container with the specified database, streams directory, and sync engine.
    ///
    /// This initializer sets up the container with its dependencies and automatically starts the
    /// synchronization engine. It also subscribes to stream operation events to track stream lifecycle
    /// changes and enqueues any pending operations that may have been interrupted.
    ///
    /// - Parameters:
    ///   - database: The database instance used for persisting stream metadata and parts.
    ///   - streamsDirectoryURL: The file system directory where stream data files are stored.
    ///   - syncEngine: The synchronization engine responsible for coordinating background uploads.
    init(
        database: any Database,
        streamsDirectoryURL: URL = .streamsDirectory,
        syncEngine: SyncEngine = RemoteSyncEngine()
    ) {
        self.database = database
        self.streamsDirectoryURL = streamsDirectoryURL
        self.syncEngine = syncEngine

        self.syncEngine.start()

        enqueuePendingOperations()
        subscribeToEventUpdates()
    }

    /// Creates a new container with default  persistence.
    ///
    /// The container will automatically create the streams directory if it doesn't exist and
    /// will start the synchronization engine to handle background uploads.
    public convenience init() {
        let database = CoreDataDatabase(persistentContainer: DependencyValues.current.persistentContainer)

        self.init(database: database)
    }

    // MARK: - Open methods

    /// Creates a new stream for uploading media of the specified file type.
    ///
    /// This method creates a new `MUStream` instance and persists its metadata to the database.
    /// The stream is immediately registered with the synchronization engine to enable automatic
    /// background upload coordination. The streams directory is created automatically if it
    /// doesn't exist.
    ///
    /// The created stream starts in the `.ready` status and can immediately accept data via
    /// `append(_:)`. Once data is appended, the stream transitions to `.running` and begins
    /// synchronizing parts to the remote server.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL of the captured media (photo or video) to upload.
    ///   - fileType: The type of media file that will be uploaded through this stream.
    /// - Returns: A new `MUStream` instance ready to accept data.
    /// - Throws: `UtilityError` with kind `.MUContainerErrorReason.newStreamFailed` if stream
    ///   creation or database persistence fails.
    open func newStream(from fileURL: URL, of fileType: FileType) async throws -> MUStream {
        do {
            if !FileManager.default.fileExists(atPath: streamsDirectoryURL.path) {
                try FileManager.default.createDirectory(at: streamsDirectoryURL, withIntermediateDirectories: true)
            }

            let streamModel = StreamModel(fileType: fileType, fileURL: fileURL)

            try await database.save(streamModel)

            let stream = await makeStream(for: streamModel)

            try await stream.append(contentsOf: fileURL)

            return stream
        } catch {
            throw UtilityError(kind: .StreamContainerErrorReason.failedToCreateStream, underlyingError: error)
        }
    }

    /// Retrieves streams from the database, optionally filtered by a predicate.
    ///
    /// This method loads streams from the database and reconstructs `MUStream` instances for each
    /// one. Active streams (those in `.running` or `.ready` status) are retrieved from the
    /// in-memory cache when available, while inactive streams are loaded from the database and
    /// their associated parts are registered.
    ///
    /// The method automatically associates stream parts with their parent streams and filters
    /// results based on the provided predicate. Results are sorted by creation date in ascending
    /// order.
    ///
    /// - Parameter isIncluded: A closure that determines whether a stream should be included in
    ///   the results. Defaults to including all streams.
    /// - Returns: An array of `MUStream` instances matching the filter criteria, sorted by
    ///   creation date.
    /// - Throws: `UtilityError` with kind `.MUContainerErrorReason.retrieveStreamsFailed` if
    ///            database retrieval fails.
    open func retrieveStreams(where isIncluded: (MUStream) -> Bool = { _ in true }) async throws -> [MUStream] {
        do {
            let activeStreams = try await database.retrieveActiveStreams()
            let predicate: NSPredicate = (\StreamModel.id << activeStreams.map(\.id))
            let streams = try await database.retrieve(of: StreamModel.self, where: !predicate)

            let parts = try await database.retrieve(of: StreamPartModel.self)
            let partsByStream = Dictionary(grouping: parts, by: \.streamId)
            let inactiveStreams = streams.filter { !activeStreams.contains($0) }

            var results: [MUStream] = []

            for activeStream in activeStreams {
                if let stream = await state.activeStreams[activeStream.id], isIncluded(stream) {
                    results.append(stream)
                }
            }

            for inactiveStream in inactiveStreams {
                let stream = await makeStream(for: inactiveStream)

                if isIncluded(stream) {
                    let parts = partsByStream[stream.id, default: []]
                    for part in parts {
                        await stream.registerPart(part)
                    }

                    results.append(stream)
                }
            }

            return results.sorted { $0.createdAt < $1.createdAt }
        } catch {
            throw UtilityError(kind: .StreamContainerErrorReason.failedToRetrieveStreams, underlyingError: error)
        }
    }

    /// Streams updates for upload streams, optionally filtered by a predicate.
    ///
    /// The returned `AsyncStream` emits whenever the underlying stream models change
    /// (creation, status updates, completion, or deletion). Each emission maps the
    /// current models into `MUStream` instances and applies the `isIncluded` filter.
    ///
    /// Consumers should iterate the stream inside a `Task` and cancel that task to
    /// stop receiving updates. The stream finishes automatically if the container
    /// is deallocated.
    ///
    /// - Parameter isIncluded: A closure that determines whether a stream should be
    ///   included in each emitted snapshot. Defaults to including all streams.
    /// - Returns: An async stream that yields the current list of streams over time.
    open func streams(where isIncluded: @escaping (MUStream) -> Bool = { _ in true }) -> AsyncStream<[MUStream]> {
        AsyncStream { continuation in
            let task = Task {
                let asyncSequence = await database.observeChanges(of: StreamModel.self)

                for await streams in asyncSequence where !Task.isCancelled {
                    var results: [MUStream] = []

                    for model in streams {
                        let stream = if let activeStream = await state.activeStreams[model.id] {
                            activeStream
                        } else {
                            await makeStream(for: model)
                        }

                        if isIncluded(stream) {
                            results.append(stream)
                        }
                    }

                    continuation.yield(results)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private methods

    private func enqueuePendingOperations() {
        Task {
            do {
                let streams = try await database.retrieveActiveStreams()

                for streamModel in streams {
                    let predicate: NSPredicate = \StreamPartModel.streamId == streamModel.id
                    let parts = try await database.retrieve(of: StreamPartModel.self, where: predicate)
                    let stream = await makeStream(for: streamModel)

                    for part in parts {
                        await stream.registerPart(part)
                    }
                }
            } catch {
                print("Failed to enqueue pending operations")
            }
        }
    }

    private func makeStream(for model: StreamModel) async -> MUStream {
        let registry = PartRegistry()
        let producer = SyncOperationProducer(stream: model, database: database, partRegistry: registry)
        let stream = MUStream(
            stream: model,
            database: database,
            operationProducer: producer,
            partRegistry: registry,
            streamsDirectoryURL: streamsDirectoryURL
        )

        if ![.cancelled, .completed].contains(model.status) {
            syncEngine.add(producer)

            await withActor(state) { state in
                state.activeStreams[stream.id] = stream
            }
        }

        return stream
    }

    private func subscribeToEventUpdates() {
        Task {
            do {
                for try await event in eventEmitter.events(of: StreamOperationEvent.self) {
                    switch event.eventType {
                    case .cancelled, .completed:
                        await withActor(state) { state in
                            state.activeStreams.removeValue(forKey: event.streamId)
                        }

                    default:
                        continue
                    }
                }
            } catch {
                print("Cannot subscribe to event updates")
            }
        }
    }
}

extension Database {
    /// Retrieves all active streams from the database that are eligible for synchronization.
    ///
    /// This method queries the database for streams that meet specific criteria for being
    /// considered "active" and eligible for processing. A stream is considered active if:
    ///
    /// 1. Its status is one of the acceptable statuses: `.failed`, `.finishing`, `.ready`,
    ///    `.running`, or `.suspended`
    /// 2. It has not exceeded the maximum number of synchronization attempts (5 attempts)
    ///
    /// ## Filtering Criteria
    ///
    /// - **Status Filter**: Only streams in specific states are retrieved. Streams that are
    ///   `.completed` or `.cancelled` are excluded as they no longer need processing.
    /// - **Attempt Limit**: Streams that have failed more than 5 times are excluded to prevent
    ///   infinite retry loops and resource exhaustion.
    ///
    /// ## Usage
    ///
    /// This method is used internally by `MUContainer` to:
    /// - Identify streams that need synchronization operations enqueued
    /// - Filter streams when retrieving active vs inactive streams
    /// - Determine which streams should be processed by the sync engine
    ///
    /// - Returns: An array of `StreamModel` instances that are active and eligible for
    ///            synchronization operations.
    /// - Throws: A `UtilityError` if the database retrieval operation fails.
    fileprivate func retrieveActiveStreams() throws -> [StreamModel] {
        let acceptableStatuses = [StreamStatus.failed, .finishing, .ready, .running, .suspended].map(\.rawValue)
        let predicate = StreamModel.statusAttribute << acceptableStatuses

        return try retrieve(of: StreamModel.self, where: predicate)
    }
}
