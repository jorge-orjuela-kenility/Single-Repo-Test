//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// Monitor used to update the progress streaming
private final class ProgressMonitor {
    typealias ProgressHandler = (TruvideoFileUploadTaskProgress) -> Void

    /// Progress handler
    var progressHandler: ProgressHandler?
}

/// `TruvideoFileUploadTask` progress stream
final class TruvideoFileUploadTaskProgressStream {
    /// The stream used to read the upload progress
    var stream: AsyncStream<TruvideoFileUploadTaskProgress>

    /// A monitor used to update the stream
    private var monitor: ProgressMonitor

    // MARK: Initializer

    /// Creates a new instance of `TruvideoFileUploadTaskProgressStream`
    ///
    /// This initializer sets up the `ProgressMonitor` and creates an `AsyncStream`
    /// that yields progress updates as they are reported.
    init() {
        let monitor = ProgressMonitor()
        stream = AsyncStream(TruvideoFileUploadTaskProgress.self) { continuation in
            monitor.progressHandler = { progress in
                continuation.yield(progress)
                if progress.percentage == 1 {
                    continuation.finish()
                }
            }
        }
        self.monitor = monitor
    }

    // MARK: Instance Methods

    /// Updates the progress of the upload.
    ///
    /// - Parameter progress: The current progress of the upload as a `TruvideoFileUploadTaskProgress` instance.
    /// This method is called to notify the stream of progress updates, which will be sent to any subscribers.
    func update(progress: TruvideoFileUploadTaskProgress) {
        monitor.progressHandler?(progress)
    }
}
