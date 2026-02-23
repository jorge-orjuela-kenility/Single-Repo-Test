//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// Represents the result of a  file task upload.
///
/// This type alias maps `TruvideoFileUploadTaskResult` to `MediaDTO`,
/// allowing the use of a more descriptive name when working with the result of file task uploads.
typealias TruvideoFileUploadTaskResult = MediaDTO

/// Protocol used in the `TruvideoFileUploaderImplementation` in order to build generic uploaders
protocol TruvideoFileUploadTask {
    typealias ProgressStream = AsyncStream<TruvideoFileUploadTaskProgress>

    /// The result of the upload task.
    var result: TruvideoFileUploadTaskResult { get async throws }

    /// Progress stream
    var progress: ProgressStream { get }

    /// Task id
    var id: UUID { get }

    /// Notifies cancellation error
    var notifyCancelation: Bool { get set }

    /// Cancelation method
    func cancel()

    /// Pause method
    func pause()

    /// Resume method
    func resume()
}

/// `TruvideoFileUploadTask` streamed type
struct TruvideoFileUploadTaskProgress {
    /// Uploaded file percentage
    let percentage: Double
}
