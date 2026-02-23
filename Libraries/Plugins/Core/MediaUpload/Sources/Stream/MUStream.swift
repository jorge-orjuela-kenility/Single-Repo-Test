//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import CoreDataUtilities
import DI
import Foundation
import TruVideoFoundation

// TODO: Track local error so we can return this in the completion handler.
/// A class that manages a multipart stream upload with support for appending data and controlling synchronization.
///
/// `MUStream` provides a high-level interface for uploading media content in parts. It manages the lifecycle
/// of stream parts, coordinates synchronization operations, and exposes state changes through Combine publishers.
/// The stream appends data incrementally, creating parts that are automatically synchronized with the server.
///
/// ## Data Flow
///
/// 1. Data is appended via `append(_:)`, creating parts stored locally
/// 2. Parts are saved to the database and observed by the operation producer
/// 3. The operation producer generates sync operations for pending parts
/// 4. Operations are executed to upload and register parts
/// 5. State changes are published via the `state` property
///
/// ## Lifecycle Management
///
/// The stream supports cancellation, suspension, and resumption:
/// - `cancel()`: Cancels all active operations
/// - `suspend()`: Pauses synchronization operations
/// - `resume()`: Resumes paused operations
/// - `finish()`: Signals completion and finalizes the stream
///
/// ## State Tracking
///
/// The stream subscribes to events emitted by operations and publishes state changes
/// through the `state` property using Combine's `@Published` property wrapper.
open class MUStream: @unchecked Sendable, Identifiable {
    // MARK: - Private Properties

    private var continuations: [UUID: AsyncStream<MUStreamStatus>.Continuation] = [:]
    private let maxNumberOfParts = 120
    private var observationTask: Task<Void, Never>?
    private let state: State
    private let streamsDirectoryURL: URL

    // MARK: - Dependencies

    @Dependency(\.eventEmitter)
    private var eventEmitter: EventEmitter

    // MARK: - Public Properties

    /// The stable identity of the entity associated with this instance.
    public let id: UUID

    /// The date and time when the stream finished uploading, if available.
    ///
    /// This property is `nil` until the stream successfully completes all part uploads and the
    /// multipart session is finalized. Once the stream transitions to the `.completed` state,
    /// this timestamp is set to the moment of completion. It can be used to:
    /// - Display completion information in UI
    /// - Calculate upload durations
    /// - Audit or log completed uploads
    public private(set) var completedAt: Date?

    /// The date and time when the stream was created.
    ///
    /// This timestamp represents when the stream was first instantiated and persisted to the database.
    /// It is used for ordering streams chronologically and tracking stream lifecycle duration.
    public let createdAt: Date

    /// The type of file being uploaded by this stream.
    ///
    /// This property indicates the media format associated with the stream, such as
    /// image, video, audio, or any other supported file category defined by `FileType`.
    public let fileType: FileType

    /// The local file URL associated with this stream, when available.
    public let fileURL: URL

    /// Whether the completed media should be included in reporting or analytics.
    ///
    /// This flag is persisted with the stream and sent when finalizing the upload.
    public private(set) var isIncludedInReport: Bool

    /// Whether the uploaded media belongs to the library collection.
    ///
    /// This flag influences how the backend categorizes the media when the stream completes.
    public private(set) var isLibrary: Bool

    /// The identifier of the media item associated with this stream, if available.
    ///
    /// This property links the stream to the media resource that is being uploaded. The value is
    /// typically assigned when the stream creates or resumes a multipart upload session with the
    /// backend. It remains `nil` until the session is established and the backend responds with the
    /// media identifier. The `requireMediaId()` helper can be used to retrieve the identifier
    /// while enforcing its presence.
    ///
    /// Use this property to:
    /// - Correlate stream uploads with media metadata
    /// - Fetch media details (e.g., preview, status) from APIs
    /// - Track media lifecycle events tied to this stream
    public private(set) var mediaId: UUID?

    /// Arbitrary key–value metadata attached to the stream.
    ///
    /// The metadata is persisted locally and included when the stream is finalized.
    public private(set) var metadata: Metadata

    /// The current state of the stream, published for observation.
    ///
    /// Updated automatically based on events emitted by operations. Subscribers can observe
    /// this property to track stream state changes.
    public private(set) var status = MUStreamStatus.ready

    /// Key–value tags associated with the stream.
    ///
    /// Tags are persisted locally and sent when completing the upload.
    public private(set) var tags: [String: String]

    /// Human-readable title for the media, if provided.
    ///
    /// The title is sent when the stream is finished to label the resulting media.
    public private(set) var title: String

    // MARK: - Types

    /// Options applied when finishing a stream and completing the upload on the server.
    ///
    /// Use this type to pass title, tags, metadata, and reporting flags into ``finish(with:)``. The
    /// values are sent with the completion request so the backend can classify the media, include
    /// it in reports, or mark it as library content.
    public struct Options {
        /// Whether the completed media should be included in reporting or analytics.
        public let isIncludedInReport: Bool

        /// Whether the media belongs to a shared or library collection.
        public let isLibrary: Bool

        /// Arbitrary key–value metadata associated with the media.
        public let metadata: Metadata

        /// Key–value tags attached to the media for categorization or filtering.
        public let tags: [String: String]

        /// Human-readable title or name of the media.
        public let title: String

        // MARK: - Initializer

        /// Creates options for stream completion.
        ///
        /// - Parameters:
        ///   - isIncludedInReport: Whether the media should be included in reporting. Defaults to `true`.
        ///   - isLibrary: Whether the media belongs to a library collection. Defaults to `false`.
        ///   - metadata: Metadata dictionary. Defaults to an empty dictionary.
        ///   - tags: Tags dictionary. Defaults to an empty dictionary.
        ///   - title: Human-readable title or name of the media. Defaults to an empty string.
        public init(
            isIncludedInReport: Bool = true,
            isLibrary: Bool = false,
            metadata: Metadata = [:],
            tags: [String: String] = [:],
            title: String = ""
        ) {
            self.isIncludedInReport = isIncludedInReport
            self.isLibrary = isLibrary
            self.metadata = metadata
            self.tags = tags
            self.title = title
        }
    }

    /// Errors specific to stream operations.
    ///
    /// This enum defines errors that can occur when performing operations on a stream,
    /// such as appending data. These errors are thrown when the stream is in an invalid
    /// state for the requested operation.
    public enum StreamError: Error {
        /// Indicates that the stream has been cancelled and cannot accept new data.
        ///
        /// This error is thrown when attempting to append data to a stream that has
        /// been cancelled. Once cancelled, a stream cannot accept new data or perform
        /// further operations.
        case streamCancelled

        /// Indicates that the stream is closed and cannot accept new data.
        ///
        /// This error is thrown when attempting to append data to a stream that has
        /// already completed or is finishing. Closed streams have finished processing
        /// and cannot accept additional data.
        case streamClosed

        /// Indicates that the stream has failed and cannot accept new data.
        ///
        /// This error is thrown when attempting to append data to a stream that has
        /// encountered a failure during processing. Failed streams cannot accept new
        /// data and may require manual intervention or retry logic to recover.
        case streamFailed
    }

    // MARK: - Initializer

    /// Creates a new stream instance with the specified dependencies.
    ///
    /// This initializer sets up a stream with its database, operation producer, part registry,
    /// and file system directory. It automatically subscribes to status changes from the state
    /// actor and updates the published `status` property on the main thread.
    ///
    /// The stream begins listening for operation events immediately upon initialization, allowing
    /// it to respond to state changes and coordinate upload operations.
    ///
    /// - Parameters:
    ///   - stream: The stream model containing the stream's metadata and state.
    ///   - database: The database instance used for persisting stream and part data.
    ///   - operationProducer: The producer responsible for generating upload operations.
    ///   - partRegistry: The registry that manages part handles for this stream.
    ///   - streamsDirectoryURL: The file system directory where stream part data files are stored.
    init(
        stream: StreamModel,
        database: any Database,
        operationProducer: OperationProducer,
        partRegistry: PartRegistry,
        streamsDirectoryURL: URL
    ) {
        self.id = stream.id
        self.completedAt = stream.completedAt
        self.createdAt = stream.createdAt
        self.fileType = stream.fileType
        self.fileURL = stream.fileURL
        self.isIncludedInReport = stream.isIncludedInReport
        self.isLibrary = stream.isLibrary
        self.mediaId = stream.mediaId
        self.metadata = stream.metadata
        self.status = .from(stream.status)
        self.streamsDirectoryURL = streamsDirectoryURL
        self.tags = stream.tags
        self.title = stream.title
        self.state = State(
            stream: stream,
            database: database,
            operationProducer: operationProducer,
            partRegistry: partRegistry
        )

        observationTask = Task {
            let predicate: NSPredicate = \StreamModel.id == stream.id

            for await streams in await database.observeChanges(of: StreamModel.self, where: predicate) {
                if let stream = streams.last {
                    update(with: stream)
                }
            }
        }
    }

    // MARK: - Deinitializer

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Instance methods

    /// Creates and registers a `PartHandle` for an existing `StreamPartModel`.
    ///
    /// Given a previously created and persisted `StreamPartModel`, this method
    /// instantiates a `PartHandle` bound to the provided part and registers it
    /// in the `partRegistry` so that its operations can be produced, tracked,
    /// and coordinated by the system.
    ///
    /// Use this when the part ya fue creado/persistido (por ejemplo, tras
    /// reconstrucción desde la base de datos al reabrir la app), y solo
    /// necesitas “engancharlo” al ciclo de operaciones.
    ///
    /// - Parameter part: The existing `StreamPartModel` to register.
    func registerPart(_ part: StreamPartModel) async {
        await state.registerPart(part)
    }

    // MARK: - Open methods

    /// Appends the contents of the file at the specified URL in fixed-size chunks.
    ///
    /// This method opens a read-only file handle for the given `url` and iteratively reads
    /// the file in blocks of up to `chunkSize` bytes. Each chunk is appended using the
    /// internal `_append(_:)` API, and the resulting `PartHandle` values are collected and
    /// returned in the order they were uploaded.
    ///
    /// The file is processed sequentially from offset `0` to the end of the file:
    /// - If the file is empty or its size cannot be determined, the method returns an empty array.
    /// - All intermediate chunks will have a maximum size of `chunkSize` bytes; the final
    ///   chunk may be smaller if there are not enough remaining bytes.
    /// - The underlying `FileHandle` is automatically closed when the operation completes,
    ///   regardless of success or failure.
    ///
    /// This is typically used for multipart or streaming uploads where the backend expects
    /// data to be sent in discrete parts (for example, S3 multipart uploads). It is the
    /// caller’s responsibility to choose a `chunkSize` that satisfies any backend-specific
    /// minimum part size requirements.
    ///
    /// - Parameters:
    ///   - url: The URL of the file whose contents should be appended in chunks.
    ///   - chunkSize: The maximum number of bytes to read and append per chunk. All
    ///                chunks except the last will have this size, assuming the file is
    ///                large enough.
    /// - Returns: An array of `PartHandle` values representing each successfully appended
    ///            chunk, in upload order. Returns an empty array if the file is empty or
    ///            its size is zero.
    /// - Throws: Any error thrown while fetching file attributes, opening or reading from
    ///           the file handle, or appending a chunk via `_append(_:)`.
    @discardableResult
    open func append(contentsOf url: URL, chunkSize: Int = 5 * 1_024 * 1_024) async throws -> [MUPartHandle] {
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int

            guard let fileSize, fileSize > 0 else {
                return []
            }

            let fileHandle = try FileHandle(forReadingFrom: url)

            defer { try? fileHandle.close() }

            var handles: [MUPartHandle] = []
            let numberOfParts = (fileSize + chunkSize - 1) / chunkSize

            let proposedChunkSize = (fileSize + maxNumberOfParts - 1) / maxNumberOfParts
            let optimalChunkSize = numberOfParts <= maxNumberOfParts ? chunkSize : max(proposedChunkSize, chunkSize)
            var offset = 0

            while offset < fileSize {
                let remaining = fileSize - offset
                let bytesToRead = min(optimalChunkSize, remaining)

                guard bytesToRead > 0, let data = try fileHandle.read(upToCount: bytesToRead) else {
                    break
                }

                let handle = try await _append(data)

                handles.append(handle)
                offset += data.count
            }

            return handles
        } catch {
            throw UtilityError(kind: .StreamErrorReason.failedToAppendContentsOfURL, underlyingError: error)
        }
    }

    /// Cancels all active operations and stops the stream.
    ///
    /// If the stream is not already cancelled, this method cancels all active operations
    /// and emits an event to signal cancellation. After cancellation, no further data
    /// can be appended and operations will not continue.
    open func cancel() async throws {
        try await state.cancel()
    }

    /// Deletes this stream from persistent storage.
    ///
    /// - Throws: `UtilityError` with kind `.StreamErrorReason.failedToDeleteStream`
    ///   if deletion fails, preserving the original failure in `underlyingError`.
    open func delete() async throws {
        try await state.delete()
    }

    /// Finishes the stream and signals completion to the operation producer.
    ///
    /// Call this when all data has been appended and the stream is ready to complete. The
    /// provided `options` supply tags, metadata, and flags (such as ``Options/isIncludedInReport``
    /// and ``Options/isLibrary``) that are sent with the completion request to the server.
    ///
    /// If the stream is already in a terminal state (completed, failed, or finishing), this
    /// method has no effect. Otherwise it transitions the stream to finishing, persists the
    /// options on the stream, and triggers the finalization process.
    ///
    /// - Parameter options: Completion options (tags, metadata, isLibrary, includeInReport).
    ///   Defaults to ``Options()`` with standard defaults when omitted.
    /// - Throws: `UtilityError` with kind `.StreamErrorReason.failedToFinishStream`
    ///   if deletion fails, preserving the original failure in `underlyingError`.
    open func finish(with options: Options = Options()) async throws {
        try await state.finish(with: options)
    }

    /// Registers a completion handler to be invoked when the stream finishes or fails.
    ///
    /// The handler is called once when the stream reaches a terminal state: on success it
    /// receives the server-assigned media UUID; on failure it receives the error that caused
    /// the stream to fail. Multiple handlers can be registered; each is invoked exactly once.
    ///
    /// The handler is dispatched asynchronously via a `Task`, so registration returns
    /// immediately. Use this for one-off callbacks (e.g. UI updates or cleanup) when the
    /// stream completes. For ongoing status changes, use ``statusUpdates()`` instead.
    ///
    /// - Parameter completionHandler: A closure that receives a `Result`: `.success(mediaId)`
    ///   when the stream completes successfully (with the server-assigned media UUID), or
    ///   `.failure(error)` when the stream fails or is left in an invalid state.
    /// - Returns: The receiver, for method chaining.
    @discardableResult
    open func onCompletion(_ completionHandler: @escaping (Result<UUID, Error>) -> Void) -> Self {
        Task {
            await state.onCompletion(completionHandler)
        }

        return self
    }

    /// Resumes all suspended operations.
    ///
    /// If the stream is suspended, this method resumes all active operations and emits
    /// an event to signal resumption. Operations will continue processing from where they
    /// were paused.
    open func resume() async throws {
        try await state.resume()
    }

    /// Retries the stream when it is cancelled or failed.
    ///
    /// If the stream is in `.cancelled` or `.failed` status, transitions it to `.running`,
    /// persists the change, and retries each registered part so operations can be re-enqueued.
    /// Has no effect when the stream is in any other status. The work is performed asynchronously
    /// in a `Task`; the method returns once the task is scheduled.
    open func retry() async throws {
        try await state.retry()
    }

    /// Observes changes to the stream’s status over time.
    ///
    /// This method returns an `AsyncStream` that yields ``MUStreamStatus`` values whenever the
    /// stream’s status changes. The stream yields the current status immediately upon
    /// subscription, then continues emitting updates as the underlying stream transitions
    /// through its lifecycle (for example, running, suspended, finishing, completed, failed).
    ///
    /// The observation is automatically cleaned up when the consumer cancels iteration or the
    /// returned `AsyncStream` terminates. Internally, `MUStream` keeps a token-based registry
    /// of active observers to avoid retaining terminated continuations.
    ///
    /// - Returns: An `AsyncStream` that yields status snapshots for this stream, beginning with
    ///   the current value at the time of subscription.
    open func statusUpdates() -> AsyncStream<MUStreamStatus> {
        AsyncStream { continuation in
            Task {
                let handle = UUID()

                continuations[handle] = continuation
                continuation.yield(status)

                continuation.onTermination = { [weak self] _ in
                    Task {
                        self?.continuations.removeValue(forKey: handle)
                    }
                }
            }
        }
    }

    /// Suspends all active operations.
    ///
    /// If the stream is running, this method suspends all active operations and emits
    /// an event to signal suspension. Operations will pause execution but can be resumed
    /// later using `resume()`.
    open func suspend() async throws {
        try await state.suspend()
    }

    // MARK: - Private methods

    private func _append(_ data: Data) async throws -> MUPartHandle {
        guard status != .failed else {
            throw StreamError.streamFailed
        }

        guard status != .cancelled else {
            throw StreamError.streamCancelled
        }

        guard await ![.completed, .finishing].contains(state.stream.status) else {
            throw StreamError.streamClosed
        }

        let partId = UUID()
        let fileURL = streamsDirectoryURL.appendingPathComponent("\(partId).dat", isDirectory: false)

        try data.write(to: fileURL, options: .atomic)

        return try await state.nextPart(for: fileURL)
    }

    private func update(with stream: StreamModel) {
        let newStatus = MUStreamStatus.from(stream.status)

        completedAt = stream.completedAt
        isIncludedInReport = stream.isIncludedInReport
        isLibrary = stream.isLibrary
        mediaId = stream.mediaId
        metadata = stream.metadata
        tags = stream.tags
        title = stream.title

        if status != newStatus {
            status = newStatus
            continuations.values.forEach { $0.yield(status) }

            if [.cancelled, .completed].contains(status) {
                continuations.values.forEach { $0.finish() }
                observationTask?.cancel()
            }
        }
    }
}

extension MUStream {
    // MARK: - Types

    /// An actor that provides thread-safe access to stream state and part management.
    ///
    /// This actor serializes access to the stream's internal state, including the part registry,
    /// status tracking, and database operations. It coordinates state transitions based on events
    /// emitted by upload operations and manages the lifecycle of stream parts.
    ///
    /// The actor isolation guarantees that concurrent access to stream state is safe, preventing
    /// data races when multiple threads interact with the stream simultaneously. All state
    /// modifications are performed within the actor's isolated context.
    private actor State {
        // MARK: - Private Properties

        private var completionHandlers: [(Result<UUID, Error>) -> Void] = []
        private let database: any Database
        private var observations: [Task<Void, Error>] = []
        private let operationProducer: OperationProducer
        private let partRegistry: PartRegistry

        // MARK: - Dependencies

        @Dependency(\.eventEmitter)
        private var eventEmitter: EventEmitter

        // MARK: - Properties

        /// A model representing a multipart media upload stream.
        let stream: StreamModel

        // MARK: - Static Properties

        /// The maximum number of retry attempts allowed for a single stream part.
        static let maxNumberOfAttempts = 5

        // MARK: - Initializer

        /// Creates a new stream state coordinator.
        ///
        /// Begins listening for `StreamOperationEvent` values emitted by the event emitter and
        /// applies the appropriate state transitions as events arrive.
        ///
        /// - Parameters:
        ///   - stream: The stream model whose state will be mutated.
        ///   - database: The database used to persist stream and part changes.
        ///   - operationProducer: A type that defines the contract for producing asynchronous operations in batches.
        ///   - partRegistry: Registry that stores handles for all stream parts.
        init(
            stream: StreamModel,
            database: any Database,
            operationProducer: OperationProducer,
            partRegistry: PartRegistry
        ) {
            self.database = database
            self.operationProducer = operationProducer
            self.partRegistry = partRegistry
            self.stream = stream

            Task {
                await startObservations()
            }
        }

        // MARK: - Instance methods

        /// Cancels the stream and all registered parts.
        ///
        /// Sets the stream status to `cancelled`, persists the change, and requests that all
        /// registered part handles cancel their work. If persistence fails, the stream status
        /// is restored to its previous value.
        func cancel() async throws {
            let currentStatus = stream.status

            if ![.cancelled, .completed, .failed].contains(currentStatus) {
                do {
                    stream.status = .cancelled

                    try await database.save(stream)

                    for partHandle in partRegistry.registeredParts() {
                        partHandle.cancel()
                    }

                    cancelObservations()
                } catch {
                    stream.status = currentStatus
                    throw UtilityError(kind: .StreamErrorReason.failedToCancelStream, underlyingError: error)
                }
            }
        }

        // TODO: Deletion should be handled by the container
        /// Deletes this stream from persistent storage.
        ///
        /// This delegates to `database.delete(_:)` for the current `stream`.
        ///
        /// - Throws: `UtilityError` with kind `.StreamErrorReason.failedToDeleteStream`
        ///   if deletion fails, preserving the original failure in `underlyingError`.
        func delete() async throws {
            do {
                try await database.delete(stream)
                try await operationProducer.finish()

                partRegistry.registeredParts().forEach { $0.cancel() }
                cancelObservations()
            } catch {
                throw UtilityError(kind: .StreamErrorReason.failedToDeleteStream, underlyingError: error)
            }
        }

        /// Transitions the stream into the finishing state and applies completion options.
        ///
        /// If the stream is not already completed, failed, or finishing, this method applies
        /// the given `options` (tags, metadata, isLibrary, isIncludedInReport) to the stream,
        /// sets the stream status to `finishing`, persists the stream, and finishes all
        /// part-observation continuations. The previous status is restored if persistence fails.
        ///
        /// - Parameter options: The completion options to persist on the stream and send with
        ///   the completion request. Values are written to the stream model before saving.
        /// - Throws: `UtilityError` with kind `.StreamErrorReason.failedToFinishStream`
        ///   if deletion fails, preserving the original failure in `underlyingError`.
        func finish(with options: Options) async throws {
            if ![.completed, .failed, .finishing].contains(stream.status) {
                let currentStatus = stream.status

                do {
                    stream.isIncludedInReport = options.isIncludedInReport
                    stream.isLibrary = options.isLibrary
                    stream.metadata = options.metadata
                    stream.status = .finishing
                    stream.tags = options.tags
                    stream.title = options.title

                    try await database.save(stream)
                    try await operationProducer.finish()

                    // TODO: Validate connectivity
                    if stream.status == .suspended {
                        try? await resume()
                    }
                } catch {
                    stream.status = currentStatus
                    throw UtilityError(kind: .StreamErrorReason.failedToFinishStream, underlyingError: error)
                }
            }
        }

        /// Creates and registers the next stream part for the given file URL.
        ///
        /// Increments the stream's part count, persists the new stream value, creates a
        /// `StreamPartModel`, saves it, and registers a new `PartHandle` in the registry.
        ///
        /// - Parameter fileURL: The temporary file location containing the part data.
        /// - Returns: A `PartHandle` that manages the new part's operations.
        /// - Throws: Any error thrown while saving the stream or part models.
        func nextPart(for fileURL: URL) async throws -> MUPartHandle {
            stream.numberOfParts += 1

            let part = StreamPartModel(
                localFileUrl: fileURL,
                number: stream.numberOfParts,
                sessionId: stream.sessionId,
                streamId: stream.id
            )

            let handle = MUPartHandle(part: part, database: database)

            partRegistry.register(handle, for: part.id)

            do {
                // TODO: create transaction
                try await database.save(part)
                try await database.save(stream)

                return handle
            } catch {
                partRegistry.removeValue(for: part.id)
                throw error
            }
        }

        /// Registers a completion handler to be invoked when the stream reaches a terminal state.
        ///
        /// The handler is stored and later invoked from `didComplete(with:)` with a `Result`:
        /// success with the stream's media UUID, or failure with the error that caused completion to fail.
        ///
        /// - Parameter completionHandler: Closure to invoke once when the stream completes or fails.
        func onCompletion(_ completionHandler: @escaping (Result<UUID, Error>) -> Void) {
            completionHandlers.append(completionHandler)
        }

        /// Creates and registers a `PartHandle` for an existing `StreamPartModel`.
        ///
        /// Given a previously created and persisted `StreamPartModel`, this method
        /// instantiates a `PartHandle` bound to the provided part and registers it
        /// in the `partRegistry` so that its operations can be produced, tracked,
        /// and coordinated by the system.
        ///
        /// Use this when the part ya fue creado/persistido (por ejemplo, tras
        /// reconstrucción desde la base de datos al reabrir la app), y solo
        /// necesitas “engancharlo” al ciclo de operaciones.
        ///
        /// - Parameter part: The existing `StreamPartModel` to register.
        func registerPart(_ part: StreamPartModel) {
            let handle = MUPartHandle(part: part, database: database)

            partRegistry.register(handle, for: part.id)
        }

        /// Resumes all part operations when the stream is suspended.
        ///
        /// Sets the stream status to `running`, persists the change, and calls `resume()` on each
        /// registered part handle. Restores the original status if persistence fails.
        func resume() async throws {
            try await _resume(resumingParts: true)
        }

        /// Retries the stream when it is cancelled or failed.
        ///
        /// If the stream is in `.cancelled` or `.failed` status, transitions it to `.running`,
        /// persists the change, and invokes `retry()` on each registered part so operations
        /// can be re-enqueued. If persistence fails, the stream status is restored to its
        /// previous value. Has no effect when the stream is in any other status.
        func retry() async throws {
            let currentStatus = stream.status

            if [.cancelled, .failed].contains(currentStatus) {
                do {
                    stream.status = .running

                    try await database.save(stream)

                    for part in partRegistry.registeredParts() {
                        part.retry()
                    }
                } catch {
                    stream.status = currentStatus
                    throw UtilityError(kind: .StreamErrorReason.failedToRetryStream, underlyingError: error)
                }
            }
        }

        /// Suspends all part operations while the stream is running.
        ///
        /// Sets the stream status to `suspended`, persists the change, and calls `suspend()` on
        /// each registered part handle. Restores the previous status if persistence fails.
        func suspend() async throws {
            let currentStatus = stream.status

            do {
                if [.running, .finishing].contains(currentStatus) {
                    stream.status = .suspended

                    try await database.save(stream)

                    for partHandle in partRegistry.registeredParts() {
                        partHandle.suspend()
                    }
                }
            } catch {
                stream.status = currentStatus
                throw UtilityError(kind: .StreamErrorReason.failedToSuspendStream, underlyingError: error)
            }
        }

        // MARK: - Private methods

        private func cancelObservations() {
            observations.forEach { $0.cancel() }
            observations.removeAll()
        }

        private func didComplete(with error: Error?) async {
            let result = Result<UUID, Error> {
                if let error {
                    throw error
                }

                guard let mediaId = stream.mediaId else {
                    throw UtilityError(kind: .StreamErrorReason.missingMediaId, underlyingError: error)
                }

                guard stream.status == .completed else {
                    throw UtilityError(kind: .unknown, failureReason: "Invalid stream status")
                }

                return mediaId
            }

            if error == nil {
                stream.completedAt = Date()
                stream.status = .completed
            } else {
                stream.status = .failed
                partRegistry.registeredParts().forEach { $0.cancel() }
            }

            do {
                try await database.save(stream)
            } catch {
                print(error)
            }

            cancelObservations()
            completionHandlers.forEach { $0(result) }
        }

        private func _resume(resumingParts: Bool = false) async throws {
            let currentStatus = stream.status

            do {
                if currentStatus == .suspended {
                    stream.status = .running

                    try await database.save(stream)

                    if resumingParts {
                        for partHandle in partRegistry.registeredParts() {
                            partHandle.resume()
                        }
                    }
                }
            } catch {
                stream.status = currentStatus
                throw UtilityError(kind: .StreamErrorReason.failedToRetryStream, underlyingError: error)
            }
        }

        private func didReceive(_ event: StreamOperationEvent) async {
            do {
                switch event.eventType {
                case .completed where stream.status != .completed:
                    await didComplete(with: nil)

                case .creatingSession where stream.status != .running:
                    stream.status = .running

                    try await database.save(stream)

                case let .failed(error):
                    await didComplete(with: error)

                case let .sessionCreated(sessionId, mediaId):
                    stream.mediaId = mediaId
                    stream.sessionId = sessionId

                    try await database.save(stream)

                default:
                    break
                }
            } catch {
                print("")
            }
        }

        private func didReceive(parts: [StreamPartModel]) async throws {
            let failedParts = parts.count(where: \.status == .failed && \.attempts >= Self.maxNumberOfAttempts)
            let activeParts = parts.filter(\.status != .completed)

            if stream.status != .failed, failedParts > 0 {
                let error = UtilityError(kind: .unknown, failureReason: "Failed due to Parts \(failedParts)")

                await didComplete(with: error)
                return
            }

            // TODO: JO: Do catch should be handled by each case so we can log the issue for the right one
            if parts.count(where: \.status == .cancelled) > 0, stream.status != .cancelled {
                try await cancel()
                return
            }

            if parts.count(where: \.status == .retrying || \.status == .uploading) > 0, stream.status == .suspended {
                try await _resume()
                return
            }

            if !activeParts.isEmpty, activeParts.allSatisfy(\.status == .suspended), stream.status != .suspended {
                try await suspend()
                return
            }

            if parts.allSatisfy(\.status == .completed), stream.status == .finishing {
                try await operationProducer.finish()
                return
            }
        }

        private func startObservations() {
            let eventsTask = Task {
                let asyncStream = eventEmitter.events(of: StreamOperationEvent.self)

                for try await event in asyncStream where event.streamId == stream.id && !Task.isCancelled {
                    await didReceive(event)
                }
            }

            let partUpdatesTask = Task {
                let predicate: NSPredicate = \StreamPartModel.streamId == stream.id
                let parts = await database.observeChanges(of: StreamPartModel.self, where: predicate)

                for await parts in parts where !Task.isCancelled {
                    try await didReceive(parts: parts)
                }
            }

            observations = [eventsTask, partUpdatesTask]
        }
    }
}
