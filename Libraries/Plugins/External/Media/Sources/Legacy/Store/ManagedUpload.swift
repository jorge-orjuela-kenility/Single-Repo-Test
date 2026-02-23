//
// Copyright © 2026 TruVideo. All rights reserved.
//

import CoreData
import Foundation
internal import TruVideoFoundation
internal import TruVideoMediaUpload

extension ManagedUpload {
    // MARK: Properties

    var localUploadRequest: LocalUploadRequest? {
        guard let status = TruvideoSdkMediaUploadRequest.Status(rawValue: Int(status)) else {
            return nil
        }

        let fileURL = getBookmarkedURL() ?? filePath

        var includeInReport: Bool?
        if let value = self.includeInReport {
            includeInReport = value == "T"
        }

        var isLibrary: Bool?
        if let value = self.isLibrary {
            isLibrary = value == "T"
        }

        return .init(
            id: id.uuidString,
            cloudServiceId: cloudServiceId,
            createdAt: createdAt,
            errorMessage: errorMessage,
            filePath: fileURL.path,
            includeInReport: includeInReport,
            isLibrary: isLibrary,
            metadata: try? JSONDecoder().decode(Metadata.self, from: metadata ?? Data()),
            progress: progress,
            remoteCreationDate: remoteCreationDate,
            remoteId: remoteId,
            remoteURL: remoteURL,
            retryCount: Int(retryCount),
            status: status,
            tags: try? JSONDecoder().decode([String: String].self, from: tags ?? Data()),
            transcriptLength: transcriptLength,
            transcriptURL: transcriptURL,
            updatedAt: updatedAt
        )
    }

    // MARK: Static Methods

    /// Inserts a new `ManagedUpload` object into the given Core Data context.
    ///
    /// - Parameters:
    ///   - context: The `NSManagedObjectContext` to insert the upload.
    ///   - id: The unique identifier for the upload.
    ///   - filePath: The file path for the upload.
    ///   - metadata: Metadata related to the upload.
    ///   - tags: Tags related to the upload.
    ///   - includeInReport: A flag indicating if the upload should be included in the report.
    static func insertUpload(
        context: NSManagedObjectContext,
        id: UUID,
        filePath: URL,
        metadata: Metadata,
        tags: [String: String],
        includeInReport: Bool?,
        isLibrary: Bool?
    ) {
        let creationTimeStamp = Date().timeIntervalSince1970
        let localUpload = ManagedUpload(context: context)
        localUpload.id = id
        localUpload.filePath = filePath
        localUpload.retryCount = 0
        localUpload.createdAt = creationTimeStamp
        localUpload.updatedAt = creationTimeStamp
        localUpload.progress = 0
        localUpload.status = Int16(TruvideoSdkMediaUploadRequest.Status.idle.rawValue)
        localUpload.metadata = try? JSONEncoder().encode(metadata)
        localUpload.tags = try? JSONEncoder().encode(tags)
        if let includeInReport {
            localUpload.includeInReport = includeInReport ? "T" : "F"
        }
        if let isLibrary {
            localUpload.isLibrary = isLibrary ? "T" : "F"
        }
        /*
         Bookmarked URLs will help us to deal with the sandboxed environments (building and
         launching the app from Xcode).In sandboxed environments the file system structure changes
         on every launch, this means that the URL.documentsDirectory will have a different value on
         every launch.
         Having a different value for each folder on every launch will lead to a file not found error
         in the retry task for an specific upload, therefore storing the bookmark data for an URL will
         help us to find the files regardless of the sandboxed URLs changes.
         */
        localUpload.bookmarkData = try? filePath.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    // swiftlint:disable force_unwrapping

    /// Finds a `ManagedUpload` object by its `id` in the given Core Data context.
    ///
    /// - Parameters:
    ///   - id: The UUID of the upload.
    ///   - context: The `NSManagedObjectContext` to search.
    /// - Returns: The matching `ManagedUpload` object, or `nil` if not found.
    static func findBy(id: UUID, in context: NSManagedObjectContext) throws -> ManagedUpload? {
        let request = NSFetchRequest<ManagedUpload>(entityName: entity().name!)
        request.predicate = .init(format: "%K = %@", argumentArray: [#keyPath(ManagedUpload.id), id])
        return try context.fetch(request).first
    }

    // swiftlint:disable force_unwrapping

    /// Finds all `ManagedUpload` objects with optional filtering by statuses.
    ///
    /// - Parameters:
    ///   - context: The `NSManagedObjectContext` to search.
    ///   - statuses: Optional array of statuses to filter uploads.
    /// - Returns: An array of `ManagedUpload` objects.
    static func findAll(
        in context: NSManagedObjectContext,
        withStatuses statuses: [TruvideoSdkMediaUploadRequest.Status]? = nil
    ) throws -> [ManagedUpload] {
        let request = NSFetchRequest<ManagedUpload>(entityName: entity().name!)
        if let statuses {
            request.predicate = .init(
                format: "%K IN %@",
                argumentArray: [#keyPath(ManagedUpload.status), statuses.map(\.rawValue)]
            )
        }
        return try context.fetch(request)
    }

    /// Finds all `ManagedUpload` objects with a specific status.
    ///
    /// - Parameters:
    ///   - status: The upload status to filter by.
    ///   - context: The `NSManagedObjectContext` to search.
    /// - Returns: An array of `ManagedUpload` objects matching the status.
    static func findBy(
        status: TruvideoSdkMediaUploadRequest.Status,
        in context: NSManagedObjectContext
    ) throws -> [ManagedUpload] {
        let request = NSFetchRequest<ManagedUpload>(entityName: entity().name!)
        request.predicate = .init(
            format: "%K = %@",
            argumentArray: [#keyPath(ManagedUpload.status), status.rawValue]
        )
        return try context.fetch(request)
    }

    // MARK: Private Methods

    private func getBookmarkedURL() -> URL? {
        guard let bookmarkData else { return nil }
        var isStale = false
        // Recover the file URL from its URL bookmark data
        return try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
    }
}
