//
// Created by TruVideo on 9/29/23.
// Copyright © 2024 TruVideo. All rights reserved.
//

import Foundation

/// Upload error
public enum TruvideoSdkMediaError: Equatable, Error, LocalizedError {
    /// Error that occurs if the tries to start an upload without authenticating first
    case userIsNotAuthenticated

    /// Error that occurs if the provided path to upload does not exist
    case fileNotFound(url: URL)

    /// Error that occurs if the provided path does not contain either an image nor a video
    case invalidFile(url: URL)

    /// Error that may occur during the upload process
    case uploadError(message: String)

    /// Error that occurs when the user cancels the upload request
    case taskCancelledByTheUser

    /// Generic error
    case generic

    /// Upload entity not found
    case uploadNotFound

    /// Unable to create a stream upload request.
    case createStreamRequestFailed

    /// Failed to retrieve stream upload requests.
    case retrieveStreamRequestsFailed

    /// Failed to retrieve a stream upload request.
    case retrieveStreamRequestFailed

    /// Failed to stream stream upload requests.
    case streamRequestsFailed

    /// Failed to stream a specific stream upload request.
    case streamRequestFailed

    /// Unable to retry upload
    case unableToRetryUpload(message: String)

    /// Unable to retry upload
    case unableToPauseUpload(message: String)

    /// Unable to resume upload
    case unableToResumeUpload(message: String)

    /// Unable to delete upload
    case unableToDeleteUpload(message: String)

    /// Error localized description
    public var errorDescription: String? {
        switch self {
        case .userIsNotAuthenticated:
            NSLocalizedString(
                "Authentication is required before uploading a file",
                comment: "User is not authenticated"
            )
        case let .fileNotFound(url):
            NSLocalizedString(
                "File not found at \(url.absoluteString)",
                comment: "File not found"
            )
        case let .invalidFile(url):
            NSLocalizedString(
                "The file at \(url.absoluteString) is neither an image nor a video file",
                comment: "Invalid file"
            )
        case let .uploadError(message):
            NSLocalizedString(
                "There was an error during the upload, the upload can be retried: \(message)",
                comment: "Upload error"
            )
        case .uploadNotFound:
            NSLocalizedString(
                "The requested upload was not found",
                comment: "Upload not found"
            )
        case .taskCancelledByTheUser:
            NSLocalizedString(
                "The task was cancelled, the upload can be retried",
                comment: "Task cancelled error"
            )
        case .generic:
            NSLocalizedString(
                "There was an error getting the file URL, the upload can be retried",
                comment: "Generic error"
            )
        case let .unableToRetryUpload(message):
            NSLocalizedString(
                "The upload could not be retried: \(message)",
                comment: "Unable to retry error"
            )
        case let .unableToPauseUpload(message):
            NSLocalizedString(
                "The upload could not be paused: \(message)",
                comment: "Unable to pause error"
            )
        case let .unableToResumeUpload(message):
            NSLocalizedString(
                "The upload could not be resumed: \(message)",
                comment: "Unable to resume error"
            )
        case let .unableToDeleteUpload(message):
            NSLocalizedString(
                "The upload could not be deleted: \(message)",
                comment: "Unable to delete error"
            )
        case .createStreamRequestFailed:
            NSLocalizedString(
                "The stream upload request could not be created",
                comment: "Unable to create stream upload request"
            )
        case .retrieveStreamRequestsFailed:
            NSLocalizedString(
                "Stream upload requests could not be retrieved",
                comment: "Failed to retrieve stream upload requests"
            )
        case .retrieveStreamRequestFailed:
            NSLocalizedString(
                "The stream upload request could not be retrieved",
                comment: "Failed to retrieve stream upload request"
            )
        case .streamRequestsFailed:
            NSLocalizedString(
                "Stream upload requests could not be streamed",
                comment: "Failed to stream stream upload requests"
            )
        case .streamRequestFailed:
            NSLocalizedString(
                "The stream upload request could not be streamed",
                comment: "Failed to stream stream upload request"
            )
        }
    }
}
