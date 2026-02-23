//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

/// The file upload information
struct AWSS3UploadData {
    // MARK: Properties

    /// File path
    let fileURL: URL

    /// File id used to avoid overwriting issues
    let fileId: UUID

    /// Additional metadata attached to the uploaded file.
    let metadata: Metadata

    /// Additional tags attached to the uploaded file.
    let tags: [String: String]

    /// Additional tags attached to the uploaded file.
    let includeInReport: Bool?

    /// File duration
    let duration: Int?

    /// Is Library property
    let isLibrary: Bool?

    // MARK: Private Properties

    /// File folder
    private let folder: String

    // MARK: Computed Properties

    /// Final file key in S3
    var fileKey: String {
        folder.isEmpty ? fileName : "\(folder)/\(fileName)"
    }

    /// File mime type
    var mimeType: String {
        fileURL.fileMimeType
    }

    /// File size
    var fileSize: Int {
        fileURL.fileSize
    }

    /// A flag to know wether the file is valid: video, image, audio or pdf
    var isValid: Bool {
        fileURL.isValid
    }

    /// File name including id and extension
    var fileName: String {
        fileURL.makeFileName(with: fileId)
    }

    /// File type
    var fileType: TruvideoSdkMediaType {
        fileURL.getFileType()
    }

    // MARK: Initializer

    /// Creates a new instance of `AWSS3UploadData`
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to be uploaded.
    ///   - fileId: A unique identifier for the file to avoid overwriting.
    ///   - folder: The folder path where the file will be uploaded in S3.
    ///   - metadata: Optional additional metadata associated with the file (default is an empty dictionary).
    ///   - tags: Optional additional tags associated with the file (default is an empty dictionary).
    ///   - includeInReport: An optional flag indicating whether to include the file in the upload report.
    ///   - isLibrary: An optional flag indicating whether is a library file.
    init(
        fileURL: URL,
        fileId: UUID,
        folder: String,
        metadata: Metadata = [:],
        tags: [String: String] = [:],
        includeInReport: Bool?,
        duration: Int?,
        isLibrary: Bool?
    ) {
        self.fileURL = fileURL
        self.fileId = fileId
        self.folder = folder
        self.metadata = metadata
        self.tags = tags
        self.includeInReport = includeInReport
        self.duration = duration
        self.isLibrary = isLibrary
    }
}
