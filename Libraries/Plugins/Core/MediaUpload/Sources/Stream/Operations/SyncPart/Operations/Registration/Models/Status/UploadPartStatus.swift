//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// Status of a single part within a multipart upload session.
struct UploadPartStatus: Codable, Sendable {
    /// Remote multipart upload session ID.
    let uploadId: String

    /// 1-based sequence number of the part.
    let partNumber: Int

    /// Current status of the part.
    let status: String
}
