//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AWSS3
import TruVideoFoundation

@testable import CloudStorageKit

/// A mock implementation of `S3TaskMonitor` used for unit testing.
///
/// This mock tracks how many times each upload event is invoked and allows
/// custom callbacks to be injected for asserting expected behavior during tests.
/// It is especially useful to verify event handling in components that rely on
/// `S3TaskMonitor` without performing real S3 uploads.
public final class S3TaskMonitorMock: S3TaskMonitor, @unchecked Sendable {
    // MARK: - Properties

    /// Closure executed when `didFailToCreateUploadTask` is called.
    public var didFailToCreateUploadTaskCallback: ((S3UploadDataTask, UtilityError) -> Void)?

    /// Number of times `uploadDataTask` was called.
    public private(set) var didFailToCreateUploadTaskCallCount = 0

    /// Closure executed when `didFinishUploadTask` is called.
    public var didFinishUploadTaskCallback: ((S3UploadDataTask, URL?, UtilityError?) -> Void)?

    /// Number of times `uploadDataTask` was called.
    public private(set) var didFinishUploadTaskCallCount = 0

    /// Closure executed when `taskDidCancel` is called.
    public var taskDidCancelCallback: ((S3UploadTask) -> Void)?

    /// Number of times `uploadDidCancel` was called.
    public private(set) var taskDidCancelCallCount = 0

    /// Closure executed when `taskDidFinish` is called.
    public var taskDidFinishCallback: ((S3UploadTask) -> Void)?

    /// Number of times `uploadDidFinish` was called.
    public private(set) var taskDidFinishCallCount = 0

    /// Closure executed when `taskDidResume` is called.
    public var taskDidResumeCallback: ((S3UploadTask) -> Void)?

    /// Number of times `taskDidResume` was called.
    public private(set) var taskDidResumeCallCount = 0

    /// Closure executed when `taskDidSuspend` is called.
    public var taskDidSuspendCallback: ((S3UploadTask) -> Void)?

    /// Number of times `taskDidSuspend` was called.
    public private(set) var taskDidSuspendCallCount = 0

    /// Closure executed when `taskIsFinishing` is called.
    public var taskIsFinishingCallback: ((S3UploadTask) -> Void)?

    /// Number of times `taskIsFinishing` was called.
    public private(set) var taskIsFinishingCallCount = 0

    /// Creates a new instance of the `S3TaskMonitor` .
    public init() {}

    // MARK: - UploadTask monitoring

    /// Notifies that the upload process was canceled.
    ///
    /// - Parameter upload: The `S3UploadTask` instance representing the canceled upload.
    public func taskDidCancel(_ upload: S3UploadTask) {
        taskDidCancelCallCount += 1
        taskDidCancelCallback?(upload)
    }

    /// Notifies that the upload process finished successfully.
    ///
    /// - Parameter upload: The `S3UploadTask` instance representing the completed upload.
    public func taskDidFinish(_ upload: S3UploadTask) {
        taskDidFinishCallCount += 1
        taskDidFinishCallback?(upload)
    }

    /// Notifies that the upload process was resumed after being paused.
    ///
    /// - Parameter upload: The `S3UploadTask` instance representing the resumed upload.
    public func taskDidResume(_ upload: S3UploadTask) {
        taskDidResumeCallCount += 1
        taskDidResumeCallback?(upload)
    }

    /// Notifies that the upload process was suspended (paused).
    ///
    /// - Parameter upload: The `S3UploadTask` instance representing the suspended upload.
    public func taskDidSuspend(_ upload: S3UploadTask) {
        taskDidSuspendCallCount += 1
        taskDidSuspendCallback?(upload)
    }

    /// Notifies that the upload process is in its finishing stage.
    ///
    /// - Parameter upload: The `S3UploadTask` instance that is finishing.
    public func taskIsFinishing(_ upload: S3UploadTask) {
        taskIsFinishingCallCount += 1
        taskIsFinishingCallback?(upload)
    }

    // MARK: - UploadDataTask monitoring

    /// Notifies that the upload data task failed to create the underlying AWS upload task.
    ///
    /// - Parameters:
    ///   - task: The `S3UploadDataTask` instance representing the attempted upload.
    ///   - didFailToCreateUploadTaskWith: The `UtilityError` that caused the failure.
    public func uploadDataTask(_ task: S3UploadDataTask, didFailToCreateUploadTaskWith: UtilityError) {
        didFailToCreateUploadTaskCallCount += 1
        didFailToCreateUploadTaskCallback?(task, didFailToCreateUploadTaskWith)
    }

    /// Notifies that the upload data task finished, either successfully or with an error.
    ///
    /// - Parameters:
    ///   - task: The `S3UploadDataTask` instance representing the upload.
    ///   - url: The `URL` of the uploaded file if successful, otherwise `nil`.
    ///   - error: A `UtilityError` describing the failure, otherwise `nil`.
    public func uploadDataTask(_ task: S3UploadDataTask, didFinishWithURL url: URL?, error: UtilityError?) {
        didFinishUploadTaskCallCount += 1
        didFinishUploadTaskCallback?(task, url, error)
    }
}
