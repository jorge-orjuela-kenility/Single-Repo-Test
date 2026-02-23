//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// An event that represents a state change or operation result for a stream.
///
/// `StreamOperationEvent` is emitted by stream-level operations (such as `StartSessionOperation`
/// and `CompleteStreamOperation`) to signal state transitions and operation results. These events
/// are observed by `MUStream` instances and the `MUContainer` to update stream state and coordinate
/// stream lifecycle management.
///
/// Events are emitted through an `EventEmitter` and can be observed using async sequences
/// or direct observer registration. Each event is associated with a specific stream via its
/// `streamId`, allowing multiple streams to be tracked simultaneously.
///
/// ## Event Types
///
/// The event type determines what state change or operation result occurred:
/// - Lifecycle events: `cancelled`, `completed`, `failed`
/// - Session management: `creatingSession`, `sessionCreated` (includes sessionId)
/// - Stream finalization: `finishingStream`
/// - State transitions: `suspended`, `resumed`
///
/// ## Usage
///
/// Events are typically created using the static factory methods and emitted through an
/// `EventEmitter`:
///
/// ```swift
/// eventEmitter.emit(StreamOperationEvent.creatingSession(for: stream.id))
/// eventEmitter.emit(StreamOperationEvent.sessionCreated(for: stream.id, sessionId: "session123"))
/// eventEmitter.emit(StreamOperationEvent.completed(streamId: stream.id))
/// ```
struct StreamOperationEvent: Event {
    // MARK: - Properties

    /// The unique identifier of the stream associated with this event.
    let streamId: UUID

    /// The type of event that occurred, indicating the state change or operation result.
    let eventType: EventType

    // MARK: - Types

    /// Represents the different types of events that can occur during stream operations.
    ///
    /// Each case represents a specific state transition or operation result in the stream's
    /// lifecycle. Some cases include associated values (like `failed` with an Error or
    /// `sessionCreated` with a sessionId) to provide additional context about the event.
    enum EventType: Sendable {
        /// Indicates that the stream operation was cancelled.
        ///
        /// This event is emitted when a stream operation (e.g., session creation or stream
        /// completion) is explicitly cancelled. Once cancelled, the operation cannot be resumed
        /// and the stream may remain in an incomplete state.
        case cancelled

        /// Indicates that the stream operation completed successfully.
        ///
        /// This event is emitted when the stream has been successfully finalized and all parts
        /// have been uploaded and registered. The stream is now complete and ready for use.
        case completed

        /// Indicates that a multipart upload session is being created.
        ///
        /// This event is emitted when the system begins the process of creating a new multipart
        /// upload session with the server. The stream transitions to an active state and is
        /// preparing to accept part uploads.
        case creatingSession

        /// Indicates that the stream operation failed.
        ///
        /// This event is emitted when an error occurs during stream operations (e.g., session
        /// creation, stream completion). The associated `Error` value provides details about
        /// the failure. The stream may be eligible for retry depending on the error type.
        ///
        /// - Parameter error: The error that caused the operation to fail.
        case failed(Error)

        /// Indicates that the stream is being finalized.
        ///
        /// This event is emitted when the stream begins the finalization process, which includes
        /// completing the multipart upload and registering all parts with the server. This is
        /// the final step before the stream transitions to `.completed`.
        case finishingStream

        /// Indicates that the stream operation has been resumed.
        ///
        /// This event is emitted when a suspended stream operation resumes its execution.
        /// The stream transitions from `.suspended` back to an active state.
        case resumed

        /// Indicates that a multipart upload session was successfully created.
        ///
        /// This event is emitted when a new multipart upload session has been created with the
        /// server. The associated `String` value contains the session ID that will be used for
        /// all subsequent part uploads and stream finalization.
        ///
        /// - Parameters:
        ///    - sessionId: The unique identifier of the created upload session.
        ///    - mediaId: The unique identifier of the associated media for the stream.
        case sessionCreated(String, UUID)

        /// Indicates that the stream operation has been suspended.
        ///
        /// This event is emitted when the stream operation is paused. The stream transitions to
        /// `.suspended` state and can be resumed later to continue processing.
        case suspended
    }

    // MARK: - Static methods

    /// Creates an event indicating that the stream operation was cancelled.
    ///
    /// - Parameter streamId: The unique identifier of the stream that was cancelled.
    /// - Returns: A `StreamOperationEvent` with event type `.cancelled`.
    static func cancelled(streamId: UUID) -> StreamOperationEvent {
        StreamOperationEvent(streamId: streamId, eventType: .cancelled)
    }

    /// Creates an event indicating that the stream operation completed successfully.
    ///
    /// - Parameter streamId: The unique identifier of the stream that completed.
    /// - Returns: A `StreamOperationEvent` with event type `.completed`.
    static func completed(streamId: UUID) -> StreamOperationEvent {
        StreamOperationEvent(streamId: streamId, eventType: .completed)
    }

    /// Creates an event indicating that a multipart upload session is being created.
    ///
    /// - Parameter streamId: The unique identifier of the stream for which a session is being created.
    /// - Returns: A `StreamOperationEvent` with event type `.creatingSession`.
    static func creatingSession(for streamId: UUID) -> StreamOperationEvent {
        StreamOperationEvent(streamId: streamId, eventType: .creatingSession)
    }

    /// Creates an event indicating that the stream operation failed.
    ///
    /// - Parameters:
    ///   - streamId: The unique identifier of the stream that failed.
    ///   - error: The error that caused the operation to fail.
    /// - Returns: A `StreamOperationEvent` with event type `.failed(error)`.
    static func failed(streamId: UUID, error: Error) -> StreamOperationEvent {
        StreamOperationEvent(streamId: streamId, eventType: .failed(error))
    }

    /// Creates an event indicating that the stream operation has been resumed.
    ///
    /// - Parameter streamId: The unique identifier of the stream that was resumed.
    /// - Returns: A `StreamOperationEvent` with event type `.resumed`.
    static func resumed(streamId: UUID) -> StreamOperationEvent {
        StreamOperationEvent(streamId: streamId, eventType: .resumed)
    }

    /// Creates an event indicating that a multipart upload session was successfully created.
    ///
    /// - Parameters:
    ///   - streamId: The unique identifier of the stream for which the session was created.
    ///   - sessionId: The unique identifier of the created upload session.
    ///   - mediaId: The unique identifier of the associated media for the stream.
    /// - Returns: A `StreamOperationEvent` with event type `.sessionCreated(sessionId, mediaId)`.
    static func sessionCreated(for streamId: UUID, sessionId: String, mediaId: UUID) -> StreamOperationEvent {
        StreamOperationEvent(streamId: streamId, eventType: .sessionCreated(sessionId, mediaId))
    }

    /// Creates an event indicating that the stream operation has been suspended.
    ///
    /// - Parameter streamId: The unique identifier of the stream that was suspended.
    /// - Returns: A `StreamOperationEvent` with event type `.suspended`.
    static func suspended(streamId: UUID) -> StreamOperationEvent {
        StreamOperationEvent(streamId: streamId, eventType: .suspended)
    }
}
