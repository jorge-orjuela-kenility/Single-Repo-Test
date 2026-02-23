//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// Represents the lifecycle status of a media upload.
///
/// Use this enum to understand the current state of an upload request and
/// decide what actions are available (e.g., retry, cancel, pause/resume) or
/// what to display in the UI (e.g., progress, error state).
public enum MediaUploadStatus: String, Sendable, Hashable {
    /// The upload was cancelled by the user or the system.
    /// No further processing will occur unless a new upload request is created.
    case cancelled

    /// The upload finished successfully and the media is available remotely.
    case completed

    /// The upload failed due to an unrecoverable error.
    /// Typically used when the request cannot continue without user action (e.g., retry).
    case error

    /// The upload is created and waiting to start.
    /// No network work is being performed yet.
    case idle

    /// The upload is temporarily paused.
    /// It may be resumed later if supported by the implementation.
    case paused

    /// The media is being prepared locally before uploading
    /// (e.g., encoding/transcoding, compression, checksum generation).
    case processing

    /// The media is currently being transferred to the remote server.
    case synchronizing
}
