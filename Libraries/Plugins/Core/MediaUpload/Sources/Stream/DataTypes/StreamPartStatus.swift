//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// Represents the possible states of a stream part during its synchronization lifecycle.
///
/// `StreamPartStatus` defines the complete state machine for stream part synchronization,
/// providing a clear and predictable way to track the progress and control part uploads.
/// Each state represents a specific phase in the part lifecycle, from creation to completion
/// or cancellation.
///
/// ## State Lifecycle
///
/// Stream parts progress through states in the following general flow:
/// ```
/// pending → uploading → completed
///    ↓         ↓
/// cancelled cancelled
/// ```
///
/// Parts may also transition to `failed` from any active state if an error occurs.
/// Parts can be `suspended` during `uploading` and then resumed.
///
/// ## State Descriptions
///
/// - **pending**: The part has been created and is waiting to be synchronized
/// - **uploading**: The part data is actively being uploaded to cloud storage
/// - **suspended**: The part synchronization is paused and can be resumed
/// - **retrying**: The part is being retried after a previous failure or cancellation
/// - **completed**: The part has been successfully uploaded and registered
/// - **failed**: The part synchronization encountered an error
/// - **cancelled**: The part synchronization was cancelled
@frozen
public enum StreamPartStatus: String, Sendable {
    /// The part synchronization was explicitly cancelled and cannot proceed further.
    ///
    /// This is a terminal state that indicates the synchronization operation has been
    /// permanently stopped. Once cancelled, the part cannot be resumed or restarted.
    /// Any partial upload progress is preserved but the part will not continue processing.
    case cancelled

    /// The part has been successfully synchronized with the server.
    ///
    /// This is a terminal state that indicates the synchronization operation finished
    /// successfully. The part has been uploaded to cloud storage, an ETag has been
    /// received, and the part has been registered with the server. The part is now
    /// complete and ready for stream finalization.
    case completed

    /// The part synchronization encountered an error and cannot continue.
    ///
    /// This state indicates that an error occurred during synchronization, such as
    /// network failures, storage errors, or registration failures. The part may be
    /// eligible for retry depending on the number of attempts made. Operation producers
    /// filter parts with fewer than 5 attempts for retry operations.
    case failed

    /// The part has been created and is waiting to be synchronized.
    ///
    /// This is the initial state of a stream part. The part has been created and
    /// configured but synchronization has not begun. The part is ready to be processed
    /// by operation producers when appropriate conditions are met (e.g., session ID
    /// is available, status matches stream status).
    case pending

    /// The part is being retried after a previous failure or cancellation.
    ///
    /// This state indicates that a part that previously failed or was cancelled is now
    /// being retried. The part transitions to this state when `retry()` is called on the
    /// part handle, allowing it to be processed again by operation producers. The part
    /// will then transition back to an active state (typically `pending` or `uploading`)
    /// as a new synchronization operation begins.
    ///
    /// Parts in this state are eligible for operation production, allowing them to be
    /// picked up by operation producers and retried with a new upload attempt.
    case retrying

    /// The part synchronization is temporarily paused and can be resumed later.
    ///
    /// This state indicates that synchronization has been paused but can be resumed
    /// from where it left off. Partial upload progress is preserved, and resuming
    /// will continue processing the part (uploading data if needed, or registering
    /// if already uploaded).
    case suspended

    /// The part data is actively being uploaded to cloud storage.
    ///
    /// This state indicates that the part data is being transferred to cloud storage
    /// using a presigned URL. Once the upload completes successfully, the part receives
    /// an ETag from storage and transitions to the `registering` state to complete
    /// the synchronization process.
    case uploading
}
