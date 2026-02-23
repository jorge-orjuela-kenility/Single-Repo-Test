//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

/// A builder class for constructing a `TruvideoSdkMediaUploadRequest`.
///
/// The `FileUploadRequestBuilder` allows for the progressive configuration of upload requests
/// by adding, modifying, and clearing metadata and tags, and specifying additional upload options.
public final class FileUploadRequestBuilder {
    // MARK: - Private Properties

    private let fileURL: URL
    private let engine: TruvideoSdkMediaUploadEngine
    private let includeInReport: Bool?
    private let isLibrary: Bool?
    private var metadataBuilder: TruvideoSdkMediaMetadataBuilder
    private var tagsBuilder: TruvideoSdkMediaTagsBuilder

    // MARK: Initializer

    /// Initializes a new instance of a media upload object with the provided parameters.
    ///
    /// - Parameters:
    ///   - engine: The engine used to handle the media upload, represented by `TruvideoSdkMediaUploadEngine`.
    ///   - fileURL: The URL of the media file to be uploaded.
    ///   - includeInReport: An optional boolean flag indicating whether the media should be included in the report.
    ///   - metadata: An instance of `TruvideoSdkMediaMetadata` representing the metadata associated with the media
    /// file.
    ///   - tags: An instance of `TruvideoSdkMediaTags` representing the tags associated with the media file.
    init(
        engine: TruvideoSdkMediaUploadEngine,
        fileURL: URL,
        includeInReport: Bool?,
        isLibrary: Bool?,
        metadata: TruvideoSdkMediaMetadata,
        tags: TruvideoSdkMediaTags
    ) {
        self.engine = engine
        self.fileURL = fileURL
        self.includeInReport = includeInReport
        self.isLibrary = isLibrary
        self.metadataBuilder = TruvideoSdkMediaMetadata.builder(dictionary: metadata.dictionary)
        self.tagsBuilder = TruvideoSdkMediaTags.builder(dictionary: tags.dictionary)
    }

    // MARK: Public Methods

    /// Adds or updates a string metadata entry in the upload request.
    ///
    /// - Parameters:
    ///   - key: The key for the metadata entry.
    ///   - value: The string value to associate with the key.
    public func addMetadata(_ key: String, _ value: String) {
        metadataBuilder[key] = .string(value)
    }

    /// Adds or updates an array of string metadata entries in the upload request.
    ///
    /// - Parameters:
    ///   - key: The key for the metadata entry.
    ///   - value: The array of string values to associate with the key.
    public func addMetadata(_ key: String, _ value: [String]) {
        metadataBuilder[key] = .array(value.map { MetadataValue.string($0) })
    }

    /// Adds or updates a `TruvideoSdkMediaMetadata` entry in the upload request.
    ///
    /// - Parameters:
    ///   - key: The key for the metadata entry.
    ///   - value: The `TruvideoSdkMediaMetadata` instance to associate with the key.
    public func addMetadata(_ key: String, _ value: TruvideoSdkMediaMetadata) {
        metadataBuilder[key] = .dictionary(value.metadata)
    }

    /// Adds or updates a tag in the upload request.
    ///
    /// - Parameters:
    ///   - key: The key for the tag.
    ///   - value: The value to associate with the key.
    public func addTag(_ key: String, _ value: String) {
        tagsBuilder[key] = value
    }

    /// Builds and returns a `TruvideoSdkMediaUploadRequest` using the configured properties.
    ///
    /// - Returns: A fully constructed `TruvideoSdkMediaUploadRequest`.
    public func build() throws -> TruvideoSdkMediaUploadRequest {
        guard fileURL.isValid else {
            throw TruvideoSdkMediaError.invalidFile(url: fileURL)
        }

        return engine.generateUploadRequest(
            forFileAt: fileURL,
            metadata: metadataBuilder.build(),
            tags: tagsBuilder.build(),
            withId: UUID(),
            includeInReport: includeInReport,
            isLibrary: isLibrary
        )
    }

    /// Clears all metadata entries from the upload request.
    public func clearMetadata() {
        metadataBuilder.clear()
    }

    /// Clears all tags from the upload request.
    public func clearTags() {
        tagsBuilder.clear()
    }

    /// Removes a metadata entry from the upload request.
    ///
    /// - Parameter key: The key of the metadata entry to be removed.
    public func removeMetadata(_ key: String) {
        metadataBuilder[key] = nil
    }

    /// Removes a tag from the upload request.
    ///
    /// - Parameter key: The key of the tag to be removed.
    public func removeTag(_ key: String) {
        tagsBuilder[key] = nil
    }

    /// Sets a new collection of metadata for the upload request.
    ///
    /// - Parameter metadata: A `TruvideoSdkMediaMetadata` instance containing the new metadata.
    public func setMetadata(_ metadata: TruvideoSdkMediaMetadata) {
        metadataBuilder = TruvideoSdkMediaMetadata.builder(dictionary: metadata.dictionary)
    }

    /// Sets a new collection of tags for the upload request.
    ///
    /// - Parameter tags: A `TruvideoSdkMediaTags` instance containing the new tags.
    public func setTags(_ tags: TruvideoSdkMediaTags) {
        tagsBuilder = TruvideoSdkMediaTags.builder(dictionary: tags.dictionary)
    }
}
