//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// Represents the possible states of a stream during its upload lifecycle.
///
/// `StreamStatus` defines the complete state machine for stream upload operations, providing
/// a clear and predictable way to track the progress and control stream synchronization.
/// Each state represents a specific phase in the stream lifecycle, from initialization
/// to completion or cancellation.
///
/// ## State Lifecycle
///
/// Streams progress through states in the following general flow:
/// ```
/// ready → running → suspended → running → finishing → completed
///    ↓       ↓         ↓         ↓          ↓
/// cancelled cancelled cancelled cancelled cancelled
/// ```
///
/// ## State Descriptions
///
/// - **ready**: The stream has been created and is ready to begin synchronization
/// - **running**: The stream is actively synchronizing parts with the server
/// - **suspended**: The stream synchronization is paused and can be resumed
/// - **finishing**: The stream is finalizing the upload session
/// - **completed**: The stream upload completed successfully
/// - **failed**: The stream upload encountered an error
/// - **cancelled**: The stream upload was cancelled
enum StreamStatus: String, Sendable, Hashable {
    /// The stream upload was explicitly cancelled and cannot proceed further.
    ///
    /// This is a terminal state that indicates the upload operation has been
    /// permanently stopped. Once cancelled, the stream cannot be resumed or
    /// restarted. Any partial synchronization progress is preserved but the
    /// stream will not continue processing.
    case cancelled

    /// The stream upload has successfully completed.
    ///
    /// This is a terminal state that indicates the upload operation finished
    /// successfully. All parts have been uploaded and registered, and the
    /// multipart upload session has been finalized. The stream is now complete.
    case completed

    /// The stream upload encountered an error and cannot continue.
    ///
    /// This state indicates that a critical error occurred during synchronization,
    /// such as network failures, server errors, or validation failures. The stream
    /// cannot recover from this state automatically and may require manual intervention.
    case failed

    /// The stream is in the process of finalizing the upload session.
    ///
    /// This state represents the final phase where the stream is completing the
    /// multipart upload session after all parts have been uploaded and registered.
    /// The stream is transitioning from active synchronization to completion.
    case finishing

    /// The stream is ready to begin synchronization but has not started yet.
    ///
    /// This is the initial state of a stream. The stream has been created and
    /// configured but synchronization has not begun. The stream is ready to start
    /// uploading parts when synchronization begins.
    case ready

    /// The stream is actively synchronizing parts with the server.
    ///
    /// This state indicates that the stream is actively processing parts, uploading
    /// data, and registering parts with the server. Parts are being synchronized
    /// according to the stream's configuration.
    case running

    /// The stream synchronization is temporarily paused and can be resumed later.
    ///
    /// This state indicates that synchronization has been paused but can be
    /// resumed from where it left off. Partial synchronization progress is preserved,
    /// and resuming will continue processing remaining parts.
    case suspended
}
