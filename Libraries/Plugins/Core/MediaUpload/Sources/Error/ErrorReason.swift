//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import TruVideoFoundation

extension ErrorReason {
    /// Error reasons specific to `CompleteStreamOperation`.
    enum CompleteStreamOperationErrorReason {
        /// Indicates that the stream failed to complete.
        static let failedToCompleteStream = ErrorReason(rawValue: "FAILED_TO_COMPLETE_STREAM")
    }

    /// Error reasons specific to database operations.
    enum DatabaseError: Sendable {
        /// Error reason indicating a database deletion operation failed.
        static let deletionFailed = ErrorReason(rawValue: "DATABASE_DELETION_FAILED")

        /// Error indicating that a find operation failed.
        ///
        /// This error occurs when the database cannot locate a model instance by its identifier.
        /// The `find` operation searches for a single model instance matching the specified type
        /// and identifier, and this error is raised when the search fails or no matching instance
        /// is found. Common causes include:
        static let findFailed = ErrorReason(rawValue: "DATABASE_FIND_FAILED")

        /// Error indicating that a retrieve operation failed.
        ///
        /// This error occurs when the database cannot fetch model instances matching a predicate.
        /// The `retrieve` operation performs a one-time fetch of all model instances matching the
        /// specified type and predicate, and this error is raised when the fetch operation fails.
        /// Common causes include:
        static let retrieveFailed = ErrorReason(rawValue: "DATABASE_RETRIEVE_FAILED")

        /// Error indicating that a save operation failed.
        ///
        /// This error occurs when the database cannot persist model instances to the persistent store.
        /// The `save` operation creates or updates managed objects in a background context and
        /// saves the changes, and this error is raised when the save operation fails. Common causes include:
        static let saveFailed = ErrorReason(rawValue: "DATABASE_SAVE_FAILED")
    }

    /// Error reasons specific to `OperationProducerErrorReason`.
    enum OperationProducerErrorReason {
        /// Indicates that finishing the producer has failed.
        static let failedToFinish = ErrorReason(rawValue: "FAILED_TO_FINISH_PRODUCER")
    }

    /// Error reasons specific to `RegisterPartOperation`.
    enum RegisterPartOperationErrorReason: Sendable {
        /// Error indicating that the operation failed to register a part with the server.
        ///
        /// This error occurs when `RegisterPartOperation` cannot successfully register an uploaded
        /// part with the server. The operation sends a POST request to `/upload/{sessionId}/part`
        /// with the part's number and `eTag`, and this error is raised when the request fails.
        /// Common causes include:
        ///
        /// - Network connectivity issues preventing the request from reaching the server
        /// - Invalid or expired authentication session
        /// - Server-side validation failures (e.g., invalid part number, mismatched eTag)
        /// - Server errors or unavailability
        /// - Request timeout or cancellation
        /// - Invalid session ID or session not found
        static let failedToRegisterPart = ErrorReason(rawValue: "FAILED_TO_REGISTER_PART")
    }

    /// Error reasons specific to `StartSessionOperation`.
    enum StartSessionOperationErrorReason {
        /// Indicates that the operation failed to start a new multipart upload session with the server.
        static let failedToStartNewStreamSession = ErrorReason(rawValue: "FAILED_TO_START_NEW_STREAM_SESSION")
    }

    /// Error reasons specific to `SyncPartOperation`.
    enum SyncPartOperationErrorReason {
        /// Indicates that the operation failed to synchronize a stream part.
        static let failedToSyncPart = ErrorReason(rawValue: "FAILED_TO_SYNC_PART")
    }

    /// Error reasons specific to `UploadDataOperation`.
    enum UploadDataOperationErrorReason {
        /// Indicates that the operation failed to upload data to cloud storage.
        static let failedToUploadData = ErrorReason(rawValue: "FAILED_TO_UPLOAD_DATA")
    }

    /// A collection of error reasons related to stream operations.
    public enum StreamErrorReason {
        /// Appending data from a URL failed.
        public static let failedToAppendContentsOfURL = ErrorReason(rawValue: "FAILED_TO_APPEND_CONTENTS_OF_URL")

        /// Cancelling an active stream failed.
        ///
        /// This error is used when the stream could not be transitioned and persisted
        /// into the cancelled state.
        public static let failedToCancelStream = ErrorReason(rawValue: "FAILED_TO_CANCEL_STREAM")

        /// Deleting a stream failed.
        public static let failedToDeleteStream = ErrorReason(rawValue: "FAILED_TO_DELETE_STREAM")

        /// Finishing a stream failed.
        public static let failedToFinishStream = ErrorReason(rawValue: "FAILED_TO_FINISH_STREAM")

        /// A stream operation required a media id that was not yet available.
        public static let missingMediaId = ErrorReason(rawValue: "MISSING_MEDIA_ID")

        /// Resuming a suspended stream failed.
        public static let failedToResumeStream = ErrorReason(rawValue: "FAILED_TO_RESUME_STREAM")

        /// Retrying a stream failed.
        public static let failedToRetryStream = ErrorReason(rawValue: "FAILED_TO_RETRY_STREAM")

        /// Suspending a stream failed.
        public static let failedToSuspendStream = ErrorReason(rawValue: "FAILED_TO_SUSPEND_STREAM")
    }

    /// A collection of error reasons related to stream container operations.
    public enum StreamContainerErrorReason {
        /// Creating a new stream failed.
        public static let failedToCreateStream = ErrorReason(rawValue: "FAILED_TO_CREATE_STREAM")

        /// Retrieving streams from storage failed.
        public static let failedToRetrieveStreams = ErrorReason(rawValue: "FAILED_TO_RETRIEVE_STREAMS")
    }
}
