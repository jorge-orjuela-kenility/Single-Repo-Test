//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// An event that represents a state change or operation result for a stream part.
///
/// `StreamPartOperationEvent` is emitted by part upload operations to signal state transitions
/// and operation results. These events are observed by `MUPartHandle` instances to update their
/// internal state and publish status changes to observers.
///
/// Events are emitted through an `EventEmitter` and can be observed using async sequences
/// or direct observer registration. Each event is associated with a specific part via its
/// `partId`, allowing multiple parts to be tracked simultaneously.
///
/// ## Event Types
///
/// The event type determines what state change or operation result occurred:
/// - Lifecycle events: `cancelled`, `completed`, `failed`
/// - State transitions: `uploading`, `suspended`, `resumed`
/// - Operation results: `uploaded` (includes eTag)
///
/// ## Usage
///
/// Events are typically created using the static factory methods and emitted through an
/// `EventEmitter`:
///
/// ```swift
/// eventEmitter.emit(StreamPartOperationEvent.uploading(partId: part.id, in: part.streamId))
/// eventEmitter.emit(StreamPartOperationEvent.uploaded(partId: part.id, in: part.streamId, with: "etag123"))
/// ```
struct StreamPartOperationEvent: Event {
    // MARK: - Properties

    /// The unique identifier of the stream part associated with this event.
    let partId: UUID

    /// The type of event that occurred, indicating the state change or operation result.
    let eventType: EventType

    // MARK: - Types

    /// Represents the different types of events that can occur during part synchronization.
    ///
    /// Each case represents a specific state transition or operation result in the part's
    /// lifecycle. Some cases include associated values (like `uploaded` with an eTag) to
    /// provide additional context about the event.
    enum EventType: Sendable {
        /// Indicates that the part synchronization was cancelled.
        ///
        /// This event is emitted when the part upload operation is explicitly cancelled.
        /// Once cancelled, the part cannot be resumed and will remain in the cancelled state.
        case cancelled

        /// Indicates that the part synchronization completed successfully.
        ///
        /// This event is emitted when the part has been successfully uploaded and registered
        /// with the server. The part is now complete and ready for stream finalization.
        case completed

        /// Indicates that the part synchronization failed.
        ///
        /// This event is emitted when an error occurs during part upload or registration.
        /// The part may be eligible for retry depending on the number of attempts made.
        case failed

        /// Indicates that the part synchronization has been resumed.
        ///
        /// This event is emitted when a suspended part resumes its synchronization operations.
        /// The part transitions from `.suspended` to `.uploading` state.
        case resumed

        /// Indicates that the part synchronization has been suspended.
        ///
        /// This event is emitted when the part upload is paused. The part transitions to
        /// `.suspended` state and can be resumed later.
        case suspended

        /// Indicates that the part data has been successfully uploaded.
        ///
        /// This event is emitted when the part data upload completes and an ETag is received
        /// from cloud storage. The associated `String` value contains the ETag that will be
        /// used for server registration.
        ///
        /// - Parameter eTag: The ETag received from cloud storage after successful upload.
        case uploaded(String)

        /// Indicates that the part data is actively being uploaded.
        ///
        /// This event is emitted when the part begins uploading its data to cloud storage.
        /// The part transitions to `.uploading` state and will emit an `uploaded` event
        /// when the upload completes.
        case uploading
    }

    // MARK: - Static methods

    /// Creates an event indicating that the part synchronization was cancelled.
    ///
    /// - Parameter partId: The unique identifier of the part that was cancelled.
    /// - Returns: A `StreamPartOperationEvent` with event type `.cancelled`.
    static func cancelled(partId: UUID) -> StreamPartOperationEvent {
        StreamPartOperationEvent(partId: partId, eventType: .cancelled)
    }

    /// Creates an event indicating that the part synchronization completed successfully.
    ///
    /// - Parameter partId: The unique identifier of the part that completed.
    /// - Returns: A `StreamPartOperationEvent` with event type `.completed`.
    static func completed(partId: UUID) -> StreamPartOperationEvent {
        StreamPartOperationEvent(partId: partId, eventType: .completed)
    }

    /// Creates an event indicating that the part synchronization failed.
    ///
    /// - Parameter partId: The unique identifier of the part that failed.
    /// - Returns: A `StreamPartOperationEvent` with event type `.failed`.
    static func failed(partId: UUID) -> StreamPartOperationEvent {
        StreamPartOperationEvent(partId: partId, eventType: .failed)
    }

    /// Creates an event indicating that the part synchronization has been resumed.
    ///
    /// - Parameter partId: The unique identifier of the part that was resumed.
    /// - Returns: A `StreamPartOperationEvent` with event type `.resumed`.
    static func resumed(partId: UUID) -> StreamPartOperationEvent {
        StreamPartOperationEvent(partId: partId, eventType: .resumed)
    }

    /// Creates an event indicating that the part synchronization has been suspended.
    ///
    /// - Parameter partId: The unique identifier of the part that was suspended.
    /// - Returns: A `StreamPartOperationEvent` with event type `.suspended`.
    static func suspended(partId: UUID) -> StreamPartOperationEvent {
        StreamPartOperationEvent(partId: partId, eventType: .suspended)
    }

    /// Creates an event indicating that the part data has been successfully uploaded.
    ///
    /// - Parameters:
    ///   - partId: The unique identifier of the part that was uploaded.
    ///   - eTag: The ETag received from cloud storage after successful upload.
    /// - Returns: A `StreamPartOperationEvent` with event type `.uploaded(eTag)`.
    static func uploaded(partId: UUID, eTag: String) -> StreamPartOperationEvent {
        StreamPartOperationEvent(partId: partId, eventType: .uploaded(eTag))
    }

    /// Creates an event indicating that the part data is actively being uploaded.
    ///
    /// - Parameter partId: The unique identifier of the part that is uploading.
    /// - Returns: A `StreamPartOperationEvent` with event type `.uploading`.
    static func uploading(partId: UUID) -> StreamPartOperationEvent {
        StreamPartOperationEvent(partId: partId, eventType: .uploading)
    }
}
