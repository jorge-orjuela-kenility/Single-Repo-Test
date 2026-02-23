//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import Foundation

final class RequestMapper {
    // MARK: Private Properties

    private let store: UploadStore

    // MARK: Initializer

    /// Creates a new instance of `RequestMapper`
    ///
    /// - Parameter store: An instance of `UploadStore` to be used for managing uploads.
    init(store: UploadStore) {
        self.store = store
    }

    // MARK: Instance Methods

    /// Retrieves an upload request by its ID and maps it to a `TruvideoSdkMediaUploadRequest`.
    ///
    /// - Parameters:
    ///   - id: The identifier of the upload request.
    ///   - engine: The upload engine used for the request.
    /// - Throws: `TruvideoSdkMediaError.uploadNotFound` if the upload is not found.
    /// - Returns: A mapped `TruvideoSdkMediaUploadRequest` object.
    func getRequest(
        byID id: String,
        withEngine engine: TruvideoSdkMediaUploadEngine
    ) throws -> TruvideoSdkMediaUploadRequest {
        let retrieveResult = store.retrieveUpload(withId: id)
        guard
            let request = try? retrieveResult.get(),
            let taskId = UUID(uuidString: request.id),
            let taskURL = URL(string: request.filePath)
        else {
            throw TruvideoSdkMediaError.uploadNotFound
        }

        return .init(
            id: taskId,
            fileURL: taskURL,
            metadata: TruvideoSdkMediaMetadata(metadata: request.metadata ?? [:]),
            tags: TruvideoSdkMediaTags(dictionary: request.tags ?? [:]),
            engine: engine,
            uploadProgress: request.progress,
            errorMessage: request.errorMessage,
            remoteId: request.remoteId,
            remoteURL: request.remoteURL,
            transcriptionURL: request.transcriptURL,
            transcriptionLength: request.transcriptLength,
            includeInReport: request.includeInReport,
            isLibrary: request.isLibrary
        )
    }

    /// Retrieves a list of upload requests filtered by an optional status.
    ///
    /// - Parameters:
    ///   - status: An optional status to filter the uploads.
    ///   - engine: The upload engine used for the requests.
    /// - Throws: `TruvideoSdkMediaError.uploadNotFound` if no uploads are found and status is provided.
    /// - Returns: An array of mapped `TruvideoSdkMediaUploadRequest` objects.
    func getUploads(
        byStatus status: TruvideoSdkMediaUploadRequest.Status? = nil,
        withEngine engine: TruvideoSdkMediaUploadEngine
    ) throws -> [TruvideoSdkMediaUploadRequest] {
        var requests = [LocalUploadRequest]()
        if let status {
            requests = try store.retrieveUploads(withStatus: status).get()
        } else {
            requests = try store.retrieveUploads().get()
        }
        return requests.map { request in
            map(from: request, with: engine)
        }
    }

    /// Retrieves a single upload request by its ID and maps it to a `TruvideoSdkMediaUploadRequest`.
    ///
    /// - Parameters:
    ///   - id: The identifier of the upload request.
    ///   - engine: The upload engine used for the request.
    /// - Throws: `TruvideoSdkMediaError.uploadNotFound` if the upload is not found.
    /// - Returns: A mapped `TruvideoSdkMediaUploadRequest` object.
    func getUpload(
        withId id: String,
        with engine: TruvideoSdkMediaUploadEngine
    ) throws -> TruvideoSdkMediaUploadRequest {
        guard
            let localRequest = try store.retrieveUpload(withId: id).get()
        else {
            throw TruvideoSdkMediaError.uploadNotFound
        }
        return map(from: localRequest, with: engine)
    }

    /// Streams upload requests filtered by an optional status.
    ///
    /// - Parameters:
    ///   - status: An optional status to filter the uploads.
    ///   - engine: The upload engine used for the requests.
    /// - Returns: A publisher that emits an array of mapped `TruvideoSdkMediaUploadRequest` objects.
    func streamUploads(
        byStatus status: TruvideoSdkMediaUploadRequest.Status?,
        withEngine engine: TruvideoSdkMediaUploadEngine
    ) -> TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStreams {
        var requests: AnyPublisher<[LocalUploadRequest], Never>! = if let status {
            store.streamUploads(withStatus: status)
        } else {
            store.streamUploads()
        }

        return requests.map {
            $0.map { localRequest in
                self.map(from: localRequest, with: engine)
            }
        }
        .eraseToAnyPublisher()
    }

    /// Streams a specific upload request by its ID and maps it to a `TruvideoSdkMediaUploadRequest`.
    /// - Parameters:
    ///   - id: The identifier of the upload request.
    ///   - engine: The upload engine used for the request.
    /// - Throws: `TruvideoSdkMediaError.uploadNotFound` if the upload is not found.
    /// - Returns: A publisher that emits the mapped `TruvideoSdkMediaUploadRequest`.
    func streamUpload(
        withId id: String,
        withEngine engine: TruvideoSdkMediaUploadEngine
    ) throws -> TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStream {
        do {
            let publisher = try store.streamUploads(byId: id)
            return publisher.map { localRequest in
                self.map(from: localRequest, with: engine)
            }.eraseToAnyPublisher()
        } catch {
            if error as? CoreDataUploadStore.Error == .uploadNotFound {
                throw TruvideoSdkMediaError.uploadNotFound
            } else {
                throw error
            }
        }
    }

    // MARK: Private Methods

    // swiftlint:disable force_unwrapping
    private func map(
        from localRequest: LocalUploadRequest,
        with engine: TruvideoSdkMediaUploadEngine
    ) -> TruvideoSdkMediaUploadRequest {
        TruvideoSdkMediaUploadRequest(
            id: UUID(uuidString: localRequest.id)!,
            fileURL: URL(string: localRequest.filePath)!,
            metadata: TruvideoSdkMediaMetadata(metadata: localRequest.metadata ?? [:]),
            tags: TruvideoSdkMediaTags(dictionary: localRequest.tags ?? [:]),
            engine: engine,
            uploadProgress: localRequest.progress,
            errorMessage: localRequest.errorMessage,
            remoteId: localRequest.remoteId,
            remoteURL: localRequest.remoteURL,
            transcriptionURL: localRequest.transcriptURL,
            transcriptionLength: localRequest.transcriptLength,
            status: localRequest.status,
            createdAt: Date(timeIntervalSince1970: localRequest.createdAt),
            updatedAt: Date(timeIntervalSince1970: localRequest.updatedAt),
            includeInReport: localRequest.includeInReport,
            isLibrary: localRequest.isLibrary
        )
    }
}
