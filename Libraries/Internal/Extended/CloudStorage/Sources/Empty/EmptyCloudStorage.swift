//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import Utilities

/// A concrete implementation of `CloudStorage` that uploads files to Amazon S3.
public final class EmptyCloudStorage: CloudStorage {
    // MARK: - Initializer

    /// Creates a new instance of the `CloudStorageProvider`.
    public init() {}

    // MARK: - CloudStorage

    /// Uploads data to cloud storage and returns an upload task for monitoring and control.
    public func upload(_ data: Data, fileName: String, contentType: ContentType) -> any UploadDataTask {
        let payload = S3DataPayload(bucket: "", contentType: contentType, data: data, path: fileName)

        return S3UploadDataTask(payload: payload, delegate: self, monitor: nil)
    }
}

extension EmptyCloudStorage: S3UploadTaskDelegate {
    // MARK: - S3UploadTaskDelegate

    func taskDidComplete(_ task: S3UploadTask) {}
}
