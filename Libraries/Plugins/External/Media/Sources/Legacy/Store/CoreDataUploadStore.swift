//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import CoreData
internal import DI
import Foundation
internal import TruVideoMediaUpload

final class CoreDataUploadStore: UploadStore {
    // MARK: Private Properties

    private let container: NSPersistentContainer

    private let context: NSManagedObjectContext

    private static let modelName = "UploadsStore"

    private static let model = NSManagedObjectModel.with(name: modelName, in: Bundle(for: CoreDataUploadStore.self))

    enum Error: Equatable, Swift.Error {
        case modelNotFound
        case failedToLoadPersistentContainer
        case generic
        case uploadNotFound
    }

    // MARK: Initializer

    /// Creates a new instance of `CoreDataUploadStore`.
    ///
    /// - Parameter storeURL: The URL of the persistent store to load.
    /// - Throws: `Error.modelNotFound` if the Core Data model cannot be found.
    ///           `Error.failedToLoadPersistentContainer` if the persistent container fails to load.
    init() {
        container = DependencyValues.current.persistentContainer
        context = container.newBackgroundContext()
    }

    // MARK: Instance Methods

    /// Resets the status of pending uploads to `cancelled`.
    func resetPendingUploadsStatus() {
        _ = performSync { context in
            let pendingStatuses: [TruvideoSdkMediaUploadRequest.Status] = [.paused, .processing, .synchronizing]
            let pendingRequests = try? ManagedUpload.findAll(in: context, withStatuses: pendingStatuses)
            for pendingRequest in pendingRequests ?? [] {
                pendingRequest.status = Int16(TruvideoSdkMediaUploadRequest.Status.cancelled.rawValue)
            }
            try context.save()
        }
    }

    /// Inserts a new upload into the store.
    ///
    /// - Parameter input: The input data required to insert an upload.
    /// - Returns: An `OperationResult` indicating the success or failure of the operation.
    func insertUpload(input: InsertUploadInput) -> OperationResult {
        performSync(id: input.id) { uuid, context in
            ManagedUpload.insertUpload(
                context: context,
                id: uuid,
                filePath: input.path,
                metadata: input.metadata,
                tags: input.tags,
                includeInReport: input.includeInReport,
                isLibrary: input.isLibrary
            )

            try context.save()
        }
    }

    /// Deletes an upload from the store with the specified ID.
    ///
    /// - Parameter id: The ID of the upload to be deleted.
    /// - Returns: An `OperationResult` indicating the success or failure of the operation.
    func deleteUpload(withId id: String) -> OperationResult {
        performSync(id: id) { uuid, context in
            try context.performAndWait {
                try ManagedUpload.findBy(id: uuid, in: context)
                    .map(context.delete)
                    .map(context.save)
            }
        }
    }

    /// Updates an existing upload with new data.
    ///
    /// - Parameters:
    ///   - id: The ID of the upload to be updated.
    ///   - data: The new data to update the upload with.
    /// - Returns: An `OperationResult` indicating the success or failure of the operation.
    func updateUpload(withId id: String, data: UpdateUploadData) -> OperationResult {
        performSync(id: id) { uuid, context in
            guard let result = try ManagedUpload.findBy(id: uuid, in: context) else {
                throw Error.uploadNotFound
            }

            if let status = data.status {
                result.status = Int16(status.rawValue)
            }

            if let progress = data.progress {
                result.progress = progress
            }

            if let cloudServiceId = data.cloudServiceId {
                result.cloudServiceId = cloudServiceId
            }

            if let retryCount = data.retryCount {
                result.retryCount = Int16(retryCount)
            }

            if let remoteURL = data.remoteURL {
                result.remoteURL = remoteURL
            }

            if let errorMessage = data.errorMessage {
                result.errorMessage = errorMessage
            }

            if let createdDate = data.createdDate {
                result.remoteCreationDate = createdDate
            }

            if let metadata = try? JSONEncoder().encode(data.metadata), !data.metadata.isEmpty {
                result.metadata = metadata
            }

            if let tags = try? JSONEncoder().encode(data.tags), !data.tags.isEmpty {
                result.tags = tags
            }

            if let remoteId = data.remoteId {
                result.remoteId = remoteId
            }

            if let transcriptURL = data.transcriptionURL {
                result.transcriptURL = transcriptURL
            }

            if let transcriptionLength = data.transcriptionLength {
                result.transcriptLength = transcriptionLength
            }

            result.updatedAt = Date().timeIntervalSince1970
            try context.save()
        }
    }

    /// Retrieves an upload with the specified ID.
    ///
    /// - Parameter id: The ID of the upload to be retrieved.
    /// - Returns: A `RetrieveUploadResult` containing the local upload request or an error if not found.
    func retrieveUpload(withId id: String) -> RetrieveUploadResult {
        performSync(id: id) { uuid, context in
            guard
                let result = try ManagedUpload.findBy(id: uuid, in: context),
                let localUploadRequest = result.localUploadRequest
            else {
                throw Error.uploadNotFound
            }

            return localUploadRequest
        }
    }

    /// Retrieves all uploads stored in the database.
    ///
    /// - Returns: A `RetrieveUploadsResult` containing an array of local upload requests.
    func retrieveUploads() -> RetrieveUploadsResult {
        performSync { context in
            let uploads = (try? ManagedUpload.findAll(in: context)) ?? []
            return uploads.map(\.localUploadRequest).compactMap { $0 }
        }
    }

    /// Retrieves all uploads with a specified status.
    ///
    /// - Parameter status: The status of uploads to be retrieved.
    /// - Returns: A `RetrieveUploadsResult` containing an array of local upload requests.
    func retrieveUploads(withStatus status: TruvideoSdkMediaUploadRequest.Status) -> RetrieveUploadsResult {
        performSync { context in
            let result = (try? ManagedUpload.findBy(status: status, in: context)) ?? []
            return result.map(\.localUploadRequest).compactMap { $0 }
        }
    }

    /// Streams the uploads stored in the database.
    ///
    /// - Returns: A `StreamUploadsResult` containing a publisher that emits updates to the list of uploads.
    func streamUploads() -> StreamUploadsResult {
        let previouslyCreatedUploads = (try? retrieveUploads().get()) ?? []
        let previouslyCreatedRequestsSubject = CombineHelpers.existingUploadsPublisher(
            uploads: previouslyCreatedUploads
        )
        var previouslyStreamedValue = previouslyCreatedUploads

        let coreDataPublisher = CombineHelpers.coreDataSaveActionPublisher(
            context: context
        ) { [weak self] in
            let currentValue = (try? self?.retrieveUploads().get()) ?? []
            if currentValue != previouslyStreamedValue {
                previouslyStreamedValue = currentValue
                return currentValue
            } else {
                return nil
            }
        }

        return previouslyCreatedUploads.isEmpty ?
            coreDataPublisher :
            Publishers.Merge(coreDataPublisher, previouslyCreatedRequestsSubject)
            .eraseToAnyPublisher()
    }

    /// Streams uploads with the specified ID.
    ///
    /// - Parameter id: The ID of the upload to be streamed.
    /// - Throws: An error if the upload is not found.
    /// - Returns: A `StreamUploadResult` containing a publisher that emits updates for the specified upload.
    func streamUploads(byId id: String) throws -> StreamUploadResult {
        let context = self.context
        let uploadRequest = try fetchManagedUpload(byId: id).get()
        let previouslyCreatedRequestSubject = CombineHelpers.existingUploadPublisher(upload: uploadRequest)

        let coreDataPublisher = CombineHelpers.coreDataSaveActionPublisher(
            forUpload: uploadRequest,
            context: context
        )

        return Publishers.Merge(previouslyCreatedRequestSubject, coreDataPublisher)
            .map(\.localUploadRequest)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Streams uploads with a specified status.
    ///
    /// - Parameter status: The status of uploads to be streamed.
    /// - Returns: A `StreamUploadsResult` containing a publisher that emits updates for uploads with the specified
    /// status.
    func streamUploads(withStatus status: TruvideoSdkMediaUploadRequest.Status) -> StreamUploadsResult {
        let previouslyCreatedUploads = (try? retrieveUploads(withStatus: status).get()) ?? []
        let previouslyCreatedRequestsSubject = CombineHelpers.existingUploadsPublisher(
            uploads: previouslyCreatedUploads
        )
        var previouslyStreamedValue = previouslyCreatedUploads

        let coreDataPublisher = CombineHelpers.coreDataSaveActionPublisher(
            context: context
        ) { [weak self] in
            let currentValue = (try? self?.retrieveUploads(withStatus: status).get()) ?? []
            if currentValue != previouslyStreamedValue {
                previouslyStreamedValue = currentValue
                return currentValue
            } else {
                return nil
            }
        }

        return previouslyCreatedUploads.isEmpty ?
            coreDataPublisher :
            Publishers.Merge(coreDataPublisher, previouslyCreatedRequestsSubject)
            .eraseToAnyPublisher()
    }

    // MARK: Private Methods

    private func performSync<R>(
        id: String,
        action: @escaping (UUID, NSManagedObjectContext) throws -> R
    ) -> Result<R, Swift.Error> {
        Result {
            try context.performAndWait {
                let uuid = try generateUUID(from: id)
                return try action(uuid, context)
            }
        }
    }

    private func performSync<R>(
        action: @escaping (NSManagedObjectContext) throws -> R
    ) -> Result<R, Swift.Error> {
        Result {
            try context.performAndWait {
                try action(context)
            }
        }
    }

    private func generateUUID(from id: String) throws -> UUID {
        guard let uuid = UUID(uuidString: id) else {
            throw Error.generic
        }

        return uuid
    }

    private func fetchManagedUpload(byId id: String) -> Result<ManagedUpload, Swift.Error> {
        performSync(id: id) { uuid, context in
            guard
                let managedUpload = try? ManagedUpload.findBy(id: uuid, in: context)
            else {
                throw Error.uploadNotFound
            }

            return managedUpload
        }
    }
}
