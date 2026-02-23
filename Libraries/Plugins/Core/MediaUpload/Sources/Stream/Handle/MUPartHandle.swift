//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Combine
import DI
import Foundation

/// A handle that manages the lifecycle and operations of a single stream part.
///
/// `MUPartHandle` provides a high-level interface for managing individual parts within a multipart
/// stream upload. It coordinates upload operations, tracks part status, and exposes state changes
/// through Combine publishers. Each part handle represents a discrete chunk of data that will be
/// uploaded and registered as part of the complete stream.
///
/// ## Part Lifecycle
///
/// Parts progress through various states during the upload process:
/// - `.pending`: Part is created but not yet being processed
/// - `.uploading`: Part data is being uploaded
/// - `.suspended`: Upload is paused
/// - `.completed`: Part has been successfully uploaded and registered
/// - `.failed`: Upload failed and may be retried
/// - `.retrying`: Part is being retried after a failure
/// - `.cancelled`: Part upload was cancelled
///
/// ## Operation Management
///
/// The handle manages `SyncPartOperation` instances that perform the actual upload work. Operations
/// can be registered, cancelled, suspended, and resumed. The handle automatically tracks operation
/// state and updates the part status accordingly.
///
/// ## State Tracking
///
/// The handle subscribes to events emitted by operations and publishes status changes through the
/// `status` property using Combine's `@Published` property wrapper. This allows observers to react
/// to part state changes in real-time.
open class MUPartHandle: @unchecked Sendable, Identifiable {
    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let state: State

    // MARK: - Public Properties

    /// The stable identity of the entity associated with this instance.
    public let id: UUID

    // MARK: - Computed Properties

    /// An array of all active operations associated with this part.
    ///
    /// This property provides access to all `AsyncOperation` instances that are currently
    /// registered for this part. Operations are registered when the part begins uploading
    /// and are removed when they complete or are cancelled.
    ///
    /// - Returns: An array of `AsyncOperation` instances currently associated with this part.
    var operations: [AsyncOperation] {
        get async { await Array(state.operations) }
    }

    // MARK: - Initializer

    /// Creates a new part handle with the specified part model and database.
    ///
    /// This initializer sets up a part handle with its associated part model and database
    /// instance. It automatically subscribes to status changes from the state actor and
    /// updates the published `status` property on the main thread.
    ///
    /// The handle begins listening for part operation events immediately upon initialization,
    /// allowing it to respond to state changes and coordinate upload operations.
    ///
    /// - Parameters:
    ///   - part: The stream part model containing the part's metadata and state.
    ///   - database: The database instance used for persisting part data.
    init(part: StreamPartModel, database: any Database) {
        self.id = part.id
        self.state = State(part: part, database: database)
    }

    // MARK: - Instance methods

    /// Registers a synchronization operation for this part.
    ///
    /// This method attempts to register a new `SyncPartOperation` with the part handle.
    /// The operation can only be registered if all existing operations have finished.
    /// Once registered, the operation will be executed to upload and register the part.
    ///
    /// - Parameter operation: The synchronization operation to register.
    /// - Returns: `true` if the operation was successfully registered, `false` if there are
    ///            still active operations that haven't finished.
    func register(_ operation: SyncPartOperation) async -> Bool {
        await state.register(operation)
    }

    // MARK: - Open methods

    /// Cancels all active operations for this part.
    ///
    /// If the part is not already in a terminal state (cancelled, completed, or failed),
    /// this method cancels all active operations. After cancellation, the part cannot
    /// be resumed and no further operations will be executed.
    open func cancel() {
        Task {
            await state.cancel()
        }
    }

    /// Resumes all suspended operations for this part.
    ///
    /// If the part has suspended operations, this method resumes them and transitions
    /// the part status back to `.uploading`. Operations will continue from where they
    /// were paused.
    open func resume() {
        Task {
            await state.resume()
        }
    }

    /// Retries a failed or cancelled part.
    ///
    /// This method transitions the part from `.failed` or `.cancelled` status to `.retrying`,
    /// allowing the part to be processed again. The part's attempt count is preserved,
    /// and a new operation can be registered to retry the upload.
    open func retry() {
        Task {
            await state.retry()
        }
    }

    /// Suspends all active operations for this part.
    ///
    /// If the part is currently uploading, this method suspends all active operations
    /// and transitions the part status to `.suspended`. Operations can be resumed
    /// later using `resume()`.
    open func suspend() {
        Task {
            await state.suspend()
        }
    }
}

extension MUPartHandle {
    // MARK: - Types

    /// An actor that provides thread-safe access to part state and operation management.
    ///
    /// This actor serializes access to the part's internal state, including the operations set,
    /// status tracking, and database operations. It coordinates state transitions based on events
    /// emitted by upload operations and manages the lifecycle of part operations.
    ///
    /// The actor isolation guarantees that concurrent access to part state is safe, preventing
    /// data races when multiple threads interact with the part handle simultaneously. All state
    /// modifications are performed within the actor's isolated context.
    private actor State {
        // MARK: - Private Properties

        private let database: any Database
        private let delayExponential = 2
        private let part: StreamPartModel

        // MARK: - Dependencies

        @Dependency(\.eventEmitter)
        private var eventEmitter: EventEmitter

        // MARK: - Properties

        /// A set of all active operations associated with this part.
        ///
        /// This set maintains references to all `AsyncOperation` instances that are
        /// currently registered for this part. Operations are added when registered
        /// and removed when they complete or are cancelled.
        var operations = Set<AsyncOperation>()

        // MARK: - Initializer

        /// Creates a new part state coordinator.
        ///
        /// This initializer sets up the state actor with the part model and database instance.
        /// It automatically subscribes to part operation events to track state changes and
        /// coordinate upload operations.
        ///
        /// - Parameters:
        ///   - part: The stream part model whose state will be managed.
        ///   - database: The database used to persist part changes.
        init(part: StreamPartModel, database: any Database) {
            self.database = database
            self.part = part

            Task {
                await subscribeToEventUpdates()
            }
        }

        // MARK: - Instance methods

        /// Cancels all active operations for this part.
        ///
        /// If the part is not already in a terminal state (cancelled, completed, or failed),
        /// this method cancels all active operations. Cancelled operations will not continue
        /// execution and the part status will be updated accordingly.
        func cancel() async {
            if ![.cancelled, .failed, .completed].contains(part.status) {
                do {
                    part.status = .cancelled

                    try await database.save(part)

                    for operation in operations where !operation.isCancelled {
                        operation.cancel()
                    }
                } catch {
                    print("Cannot cancel the part")
                }
            }
        }

        /// Registers a synchronization operation for this part.
        ///
        /// This method attempts to register a new `SyncPartOperation` with the part. The operation
        /// can only be registered if all existing operations have finished. Once registered, the
        /// operation will be executed to upload and register the part with the server.
        ///
        /// - Parameter operation: The synchronization operation to register.
        /// - Returns: `true` if the operation was successfully registered, `false` if there are
        ///            still active operations that haven't finished.
        func register(_ operation: SyncPartOperation) async -> Bool {
            guard [.failed, .pending, .retrying, .uploading].contains(part.status) else {
                return false
            }

            guard !operations.contains(where: \.isReady || \.isExecuting || \.isSuspended) else {
                return false
            }

            operations.insert(operation)

            return true
        }

        /// Resumes all suspended operations for this part.
        ///
        /// This method resumes all active operations and transitions the part status to `.uploading`.
        /// Operations will continue from where they were paused.
        func resume() async {
            if part.status == .suspended {
                do {
                    let newStatus = operations.allSatisfy(\.isReady) ? StreamPartStatus.pending : .uploading

                    part.status = newStatus

                    try await database.save(part)

                    for operation in operations {
                        operation.resume()
                    }
                } catch {
                    print("Cannot resume the part")
                }
            }
        }

        /// Retries a failed or cancelled part.
        ///
        /// This method transitions the part from `.failed` or `.cancelled` status to `.retrying`MU
        /// and persists the change to the database. The previous status is restored if persistence
        /// fails. After retrying, a new operation can be registered to attempt the upload again.
        func retry() async {
            let currentStatus = part.status

            if [.cancelled, .failed].contains(currentStatus) {
                do {
                    part.status = .retrying

                    try await database.save(part)
                } catch {
                    part.status = currentStatus
                }
            }
        }

        /// Suspends all active operations for this part.
        ///
        /// If the part is currently uploading, this method suspends all active operations
        /// and transitions the part status to `.suspended`. Operations can be resumed later
        /// using `resume()`.
        func suspend() async {
            if [.pending, .uploading].contains(part.status) {
                do {
                    part.status = .suspended

                    try await database.save(part)

                    for operation in operations {
                        operation.suspend()
                    }
                } catch {
                    print("Cannot suspend the part")
                }
            }
        }

        // MARK: - Private methods

        private func didReceive(_ event: StreamPartOperationEvent) async {
            switch event.eventType {
            case .completed:
                part.completedAt = Date()
                part.status = .completed

            case .failed:
                part.attempts += 1
                part.nextAttemptDate = Date().addingTimeInterval(TimeInterval(part.attempts * delayExponential))
                part.status = .failed

            case .resumed:
                part.status = .pending

            case .suspended:
                part.status = .suspended

            case let .uploaded(eTag):
                part.eTag = eTag

            case .uploading:
                part.nextAttemptDate = nil
                part.status = .uploading

            default:
                break
            }

            do {
                try await database.save(part)
            } catch {
                print("Cannot save the part")
            }
        }

        private func subscribeToEventUpdates() async {
            do {
                let asyncSequence = eventEmitter.events(of: StreamPartOperationEvent.self)

                for try await event in asyncSequence where event.partId == part.id {
                    await didReceive(event)
                }
            } catch {
                print("Cannot subscribe to events")
            }
        }
    }
}
