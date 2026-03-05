//
//  CoreDataTruvideoStore.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 21/2/24.
//

import Combine
import CoreData

final class CoreDataTruvideoStore: VideoStore {
    private static let modelName = "TruvideoSdkVideoStore"
    private static let model = NSManagedObjectModel.with(name: modelName, in: Bundle(for: CoreDataTruvideoStore.self))
    private static let entityName = "ManagedVideoRequest"

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    enum Error: Equatable, Swift.Error {
        case modelNotFound
        case failedToLoadPersistentContainer
        case generic
        case uploadNotFound
    }

    init(storeURL: URL) throws {
        guard let model = Self.model else {
            throw Error.modelNotFound
        }

        do {
            container = try NSPersistentContainer.load(name: Self.modelName, model: model, url: storeURL)
            context = container.newBackgroundContext()
        } catch {
            throw Error.failedToLoadPersistentContainer
        }
    }

    func insert(request: LocalVideoRequest) throws {
        Logger.addLog(event: .insertRequest, eventMessage: .insertRequest(id: request.id))
        try performSync { context in
            ManagedVideoRequest.insertUpload(context: context, request: request)
            try context.save()
        }
    }

    func updateRequest(withId id: UUID, data: UpdateRequestData) throws {
        Logger.addLog(event: .updateRequest, eventMessage: .updateRequest(id: id))
        try performSync { context in
            try ManagedVideoRequest.getRequestBy(id: id, context: context).map { record in
                for field in data.fields {
                    if case let .error(value) = field {
                        record.error = value
                    }
                    if case let .processId(value) = field {
                        record.processId = value
                    }
                    if case let .status(value) = field {
                        record.status = Int16(value.rawValue)
                    }
                }
                record.updatedAt = .init()
                try context.save()
            }
        }
    }

    func deleteRequest(withId id: UUID) throws {
        try performSync { context in
            try ManagedVideoRequest.getRequestBy(id: id, context: context).map {
                context.delete($0)
                try context.save()
            }
        }
    }

    func deleteRequests() throws {
        try performSync { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: CoreDataTruvideoStore
                .entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(batchDeleteRequest)
            try context.save()
        }
    }

    func getRequest(withId id: UUID) throws -> LocalVideoRequest? {
        Logger.addLog(event: .getRequestById, eventMessage: .getRequestBy(id: id))
        return performSync { context in
            ManagedVideoRequest.getRequestBy(id: id, context: context)?.localVideoRequest
        }
    }

    func getRequests(withStatus status: LocalVideoRequest.Status) throws -> [LocalVideoRequest] {
        performSync { context in
            ManagedVideoRequest.getRequestsBy(status: status, context: context)
                .compactMap(\.localVideoRequest)
        }
    }

    func resetPendingRequests() {
        do {
            try performSync { context in
                let processingRequests = ManagedVideoRequest.getRequestsBy(
                    status: .processing, context: context
                )
                for processingRequest in processingRequests {
                    processingRequest.status = Int16(LocalVideoRequest.Status.cancelled.rawValue)
                }
                try context.save()
            }
        } catch {}
    }

    func streamVideos() -> AnyPublisher<[LocalVideoRequest], Never> {
        let previouslyCreatedUploads = retrieveRequests()
        let previouslyCreatedRequestsSubject = CurrentValueSubject<[LocalVideoRequest], Never>(previouslyCreatedUploads)
        var previouslyStreamedValue = previouslyCreatedUploads
        let didSavePublisher = NotificationCenter.default.publisher(
            for: NSManagedObjectContext.didSaveObjectsNotification,
            object: context
        )
        .map { _ in
            let currentValue = self.retrieveRequests()

            if currentValue != previouslyStreamedValue {
                previouslyStreamedValue = currentValue
                return currentValue
            } else {
                return nil
            }
        }
        .compactMap { $0 }

        guard !previouslyCreatedUploads.isEmpty else {
            return didSavePublisher.eraseToAnyPublisher()
        }

        return Publishers.Merge(didSavePublisher, previouslyCreatedRequestsSubject)
            .eraseToAnyPublisher()
    }

    func streamVideos(withStatus status: TruvideoSdkVideoRequest.Status) -> AnyPublisher<[LocalVideoRequest], Never> {
        let previouslyCreatedUploads = (try? retrieveRequests(withStatus: status).get()) ?? []
        let previouslyCreatedRequestsSubject = CurrentValueSubject<[LocalVideoRequest], Never>(previouslyCreatedUploads)
        var previouslyStreamedValue = previouslyCreatedUploads
        let didSavePublisher = NotificationCenter.default.publisher(
            for: NSManagedObjectContext.didSaveObjectsNotification,
            object: context
        )
        .map { _ in
            let currentValue = (try? self.retrieveRequests(withStatus: status).get()) ?? []

            if currentValue != previouslyStreamedValue {
                previouslyStreamedValue = currentValue
                return currentValue
            } else {
                return nil
            }
        }
        .compactMap { $0 }

        guard !previouslyCreatedUploads.isEmpty else {
            return didSavePublisher.eraseToAnyPublisher()
        }

        return Publishers.Merge(didSavePublisher, previouslyCreatedRequestsSubject)
            .eraseToAnyPublisher()
    }

    func streamVideo(with id: UUID) throws -> AnyPublisher<LocalVideoRequest, Never> {
        let videoRequest = try fetchManagedUpload(byId: id).get()
        let previouslyCreatedRequestSubject = CurrentValueSubject<ManagedVideoRequest?, Never>(videoRequest)

        let coreDataPublisher = NotificationCenter.default.publisher(
            for: NSManagedObjectContext.didSaveObjectsNotification,
            object: context
        )
        .map { notification -> ManagedVideoRequest? in
            if
                let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                updatedObjects.contains(where: { $0.objectID == videoRequest.objectID }) {
                self.context.refresh(videoRequest, mergeChanges: true)
                return videoRequest
            }

            return nil
        }

        return Publishers.Merge(previouslyCreatedRequestSubject, coreDataPublisher)
            .map { $0?.localVideoRequest }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    // MARK: Private methods

    private func fetchManagedUpload(byId id: UUID) -> Result<ManagedVideoRequest, Swift.Error> {
        performSync { context in
            Result {
                guard let videoRequest = try? ManagedVideoRequest.findBy(id: id, in: context) else {
                    throw Error.uploadNotFound
                }

                return videoRequest
            }
        }
    }

    private func performSync<T>(
        action: @escaping (NSManagedObjectContext) throws -> T
    ) rethrows -> T {
        let context = self.context
        return try context.performAndWait {
            try action(context)
        }
    }

    func retrieveRequests() -> [LocalVideoRequest] {
        performSync { context in
            let uploads = (try? ManagedVideoRequest.findAll(in: context)) ?? []
            return uploads.map(\.localVideoRequest).compactMap { $0 }
        }
    }

    private func retrieveRequests(withStatus status: TruvideoSdkVideoRequest
        .Status) -> Result<[LocalVideoRequest], Swift.Error> {
        performSync { context in
            let result = (try? ManagedVideoRequest.findBy(status: status, in: context)) ?? []
            return Result {
                result.map(\.localVideoRequest)
                    .compactMap { $0 }
            }
        }
    }
}
