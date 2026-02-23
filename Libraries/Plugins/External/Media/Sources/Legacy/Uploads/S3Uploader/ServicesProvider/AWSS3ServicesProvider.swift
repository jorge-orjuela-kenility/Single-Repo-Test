//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// An abstraction to decouple from S3
protocol AWSS3ServicesProvider {
    /// Register services if and only if no transfer utility was registered
    func registerServicesIfNeeded()

    /// An abstraction to decouple from S3 transfer utility
    /// - Parameters:
    ///   - uploadData: File information
    ///   - onProgressChange: Progress handler
    ///   - completion: Completion handler
    func uploadedFile(
        uploadData: AWSS3UploadData,
        onProgressChange: @escaping (Double) -> Void,
        onTaskStarted: @escaping (String) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    )

    /// An abstraction to cancel the S3 transfer utility task
    func cancelUpload()

    /// An abstraction to pause the S3 transfer utility task
    func pause()

    /// An abstraction to resume the paused S3 transfer utility
    func resume()
}
