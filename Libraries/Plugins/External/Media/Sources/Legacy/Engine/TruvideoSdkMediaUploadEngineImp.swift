//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Combine
import Foundation
internal import TruVideoFoundation

final class TruvideoSdkMediaUploadEngineImp<UploadTask: TruvideoFileUploadTask>: TruvideoSdkMediaUploadEngine {
    /// An alias representing the closure definition used to build an UploadTask.
    typealias TaskBuilder = (URL, UUID, Metadata, [String: String], Bool?, Bool?) -> UploadTask

    // MARK: Private Properties

    /// Upload credentials provider
    private let credentialProvider: AWSCredentialProvider

    /// File url validator
    private let fileURLValidator: FileURLValidator

    private let requestMapper: RequestMapper

    /// Map used to get a `TruvideoFileUploadTask` based on a `TruvideoFileUploadRequest` id
    private var runningTasks = [String: TruvideoFileUploadTask]()

    private let store: UploadStore

    /// A closure to build a generic uploader task from given URL
    private let taskBuilder: TaskBuilder

    // MARK: Initializer

    /// Creates a new instance of `TruvideoSdkMediaUploadEngineImp`
    ///
    /// - Parameters:
    ///   - fileURLValidator: A validator to check file URLs.
    ///   - credentialProvider: Provides credentials for uploads.
    ///   - store: The upload store to manage upload requests.
    ///   - requestMapper: Maps requests to and from a data source.
    ///   - taskBuilder: A closure for creating upload tasks.
    init(
        fileURLValidator: FileURLValidator,
        credentialProvider: AWSCredentialProvider,
        store: UploadStore,
        requestMapper: RequestMapper,
        taskBuilder: @escaping TaskBuilder
    ) {
        self.fileURLValidator = fileURLValidator
        self.credentialProvider = credentialProvider
        self.store = store
        self.requestMapper = requestMapper
        self.taskBuilder = taskBuilder
    }

    // MARK: Instance Methods

    /// Initiates the upload process for the given upload request.
    ///
    /// - Parameter request: The upload request containing necessary details for the upload.
    /// - Throws: Errors related to upload initiation such as authentication failures, invalid states, etc.
    func upload(request: TruvideoSdkMediaUploadRequest) throws {
        let localRequest = try getLocalRequest(withId: request.id.uuidString) { error in
            if let mediaError = error as? TruvideoSdkMediaError, mediaError == .userIsNotAuthenticated {
                // Log validate Auth Failed Sdk Not Authenticated.
            } else {
                // Log file Upload Request Not Found.
            }

            request.completionPublisher.send(completion: .failure(error))
        }

        guard !localRequest.isRunning else {
            throw TruvideoSdkMediaError.unableToRetryUpload(message: "Task already processing")
        }

        guard localRequest.status != .completed else {
            throw TruvideoSdkMediaError.unableToRetryUpload(message: "Task already completed")
        }

        let wrappedTask = runningTasks[request.id.uuidString] ?? taskBuilder(
            request.fileURL,
            request.id,
            request.metadata.metadata,
            request.tags.dictionary,
            request.includeInReport,
            request.isLibrary
        )

        if runningTasks[request.id.uuidString] == nil {
            runningTasks[request.id.uuidString] = wrappedTask
        }

        do {
            guard credentialProvider.awsCredential().isUserAuthenticated else {
                throw TruvideoSdkMediaError.userIsNotAuthenticated
            }

            try fileURLValidator.isValid(url: request.fileURL)
        } catch {
            runningTasks.removeValue(forKey: request.id.uuidString)

            store.updateUpload(withId: request.id.uuidString, data: .init(status: .error))
            throw error
        }

        Task {
            do {
                Task {
                    for await progress in wrappedTask.progress {
                        request.progressPublisher.send(.init(percentage: progress.percentage))
                        store.updateUpload(
                            withId: request.id.uuidString, data: .init(progress: progress.percentage)
                        )
                    }
                }
                let result = try await wrappedTask.result

                store.updateUpload(
                    withId: request.id.uuidString,
                    data: .init(
                        status: .completed,
                        remoteId: result.id,
                        remoteURL: result.url,
                        createdDate: result.createdDate,
                        metadata: result.metadata,
                        tags: result.tags,
                        transcriptionURL: result.transcriptionUrl?.path,
                        transcriptionLength: result.transcriptionLength
                    )
                )
                try request.completionPublisher.send(.from(result))
                request.completionPublisher.send(completion: .finished)
                runningTasks.removeValue(forKey: request.id.uuidString)
            } catch {
                if let error = error as? TruvideoSdkMediaError {
                    if error == .uploadNotFound {
                        // Log error Creating Media Entity.
                    }
                } else {
                    // Log file Upload Request Start
                }

                let taskWasCancelled = error as? TruvideoSdkMediaError == .taskCancelledByTheUser

                store.updateUpload(
                    withId: request.id.uuidString,
                    data: .init(
                        status: taskWasCancelled ? .cancelled : .error,
                        errorMessage: taskWasCancelled ? nil : error.localizedDescription
                    )
                )
                let notifyCancellation = taskWasCancelled && wrappedTask.notifyCancelation

                runningTasks.removeValue(forKey: request.id.uuidString)
                if notifyCancellation || !taskWasCancelled {
                    request.completionPublisher.send(completion: .failure(error))
                    request.restorePublishers()
                }
            }
        }
    }

    /// Retries the upload for the given request.
    ///
    /// - Parameter request: The upload request to retry.
    /// - Throws: Errors related to the retry process.
    func retry(request: TruvideoSdkMediaUploadRequest) throws {
        let localRequest = try getLocalRequest(withId: request.id.uuidString)

        guard localRequest.status != .completed else {
            throw TruvideoSdkMediaError.unableToRetryUpload(message: "Task already completed")
        }

        guard !localRequest.isRunning else {
            throw TruvideoSdkMediaError.unableToRetryUpload(message: "Task already processing")
        }

        try upload(request: request)

        store.updateUpload(
            withId: request.id.uuidString,
            data: .init(status: .processing, retryCount: localRequest.retryCount + 1)
        )
    }

    /// Pauses the upload request identified by the given ID.
    ///
    /// - Parameter id: The unique identifier of the upload request to pause.
    /// - Throws: An error if the request is not found or if the request status is not suitable for pausing.
    func pause(id: String) throws {
        let localRequest = try getLocalRequest(withId: id) { _ in
            // Log file Upload Request Not Found By Id.
        }

        guard localRequest.status == .processing else {
            throw TruvideoSdkMediaError.unableToPauseUpload(message: "Task must be processing to be paused")
        }

        store.updateUpload(withId: id, data: .init(status: .paused))
        runningTasks[id]?.pause()
    }

    /// Resumes the upload request identified by the given ID.
    ///
    /// - Parameter id: The unique identifier of the upload request to resume.
    /// - Throws: An error if the request is not found or if the request status is not suitable for resuming.
    func resume(id: String) throws {
        let localRequest = try getLocalRequest(withId: id) { _ in
            // Log file Upload Request Not Found By Id.
        }

        guard localRequest.status == .paused else {
            throw TruvideoSdkMediaError.unableToResumeUpload(message: "Task must be paused to be resumed")
        }

        store.updateUpload(withId: id, data: .init(status: .processing))
        runningTasks[id]?.resume()
    }

    /// Deletes the upload for the given request.
    ///
    /// - Parameter id: The id of the request to delete.
    /// - Throws: Errors related to the deletion process.
    func delete(id: String) throws {
        let localRequest = try getLocalRequest(withId: id)

        if localRequest.isRunning {
            runningTasks[id]?.notifyCancelation = false
            try cancel(id: id)
        }

        if case let .failure(error) = store.deleteUpload(withId: id) {
            throw TruvideoSdkMediaError.unableToDeleteUpload(
                message: "The operation could not be completed"
            )
        }
    }

    /// Cancels the upload for the given request.
    ///
    /// - Parameter request: The id of the request to cancel.
    /// - Throws: Errors related to the cancellation process.
    func cancel(id: String) throws {
        runningTasks[id]?.cancel()
    }

    func updateRequest(request: TruvideoSdkMediaUploadRequest) {
        store.updateUpload(
            withId: request.id.uuidString,
            data: .init(includeInReport: request.includeInReport, isLibrary: request.isLibrary)
        )
    }

    /// Generates a new upload request for the file located at the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to be uploaded.
    ///   - metadata: Metadata associated with the media file.
    ///   - tags: Tags associated with the media file.
    ///   - id: A unique identifier for the upload request.
    ///   - includeInReport: Optional flag indicating whether to include this upload in reports.
    /// - Returns: A new `TruvideoSdkMediaUploadRequest` object representing the upload request.
    func generateUploadRequest(
        forFileAt url: URL,
        metadata: TruvideoSdkMediaMetadata,
        tags: TruvideoSdkMediaTags,
        withId id: UUID,
        includeInReport: Bool? = nil,
        isLibrary: Bool? = nil
    ) -> TruvideoSdkMediaUploadRequest {
        let uploadRequest = TruvideoSdkMediaUploadRequest(
            id: id,
            fileURL: url,
            metadata: metadata,
            tags: tags,
            engine: self,
            status: .idle,
            createdAt: Date(),
            includeInReport: includeInReport,
            isLibrary: isLibrary
        )
        store.insertUpload(
            input: InsertUploadInput(
                id: uploadRequest.id.uuidString,
                path: url,
                metadata: metadata.metadata,
                tags: tags.dictionary,
                includeInReport: includeInReport,
                isLibrary: isLibrary
            )
        )

        return uploadRequest
    }

    /// Retrieves all upload requests filtered by their status.
    ///
    /// - Parameter status: Optional status to filter the requests. If nil, all requests are returned.
    /// - Throws: An error if there is a failure in retrieving upload requests.
    /// - Returns: An array of `TruvideoSdkMediaUploadRequest` objects.
    func getUploads(byStatus status: TruvideoSdkMediaUploadRequest
        .Status? = nil
    ) throws -> [TruvideoSdkMediaUploadRequest] {
        do {
            return try requestMapper.getUploads(byStatus: status, withEngine: self)
        } catch {
            throw error
        }
    }

    /// Retrieves a specific upload request by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the upload request to retrieve.
    /// - Throws: An error if the request cannot be found or there is a failure in retrieval.
    /// - Returns: A `TruvideoSdkMediaUploadRequest` object representing the requested upload.
    func getUpload(withId id: String) throws -> TruvideoSdkMediaUploadRequest {
        do {
            return try requestMapper.getRequest(byID: id, withEngine: self)
        } catch {
            throw error
        }
    }

    /// Streams uploads filtered by their status.
    ///
    /// - Parameter status: Optional status to filter the streams. If nil, streams of all requests are returned.
    /// - Returns: A `TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStreams` object containing the streams.
    func streamUploads(byStatus status: TruvideoSdkMediaUploadRequest.Status?) -> TruvideoSdkMediaInterface
    .TruvideoSdkMediaFileUploadStreams {
        requestMapper.streamUploads(byStatus: status, withEngine: self)
    }

    /// Streams a specific upload by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the upload request to stream.
    /// - Throws: An error if the stream cannot be established or if the request is not found.
    /// - Returns: A `TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStream` object representing the upload stream.
    func streamUpload(withId id: String) throws -> TruvideoSdkMediaInterface.TruvideoSdkMediaFileUploadStream {
        do {
            return try requestMapper.streamUpload(withId: id, withEngine: self)
        } catch {
            throw error
        }
    }

    // MARK: Private Methods

    private func getLocalRequest(withId id: String) throws -> LocalUploadRequest {
        guard credentialProvider.awsCredential().isUserAuthenticated else {
            throw TruvideoSdkMediaError.userIsNotAuthenticated
        }

        let retrieveResult = store.retrieveUpload(withId: id)

        guard let request = try? retrieveResult.get() else {
            throw TruvideoSdkMediaError.uploadNotFound
        }

        return request
    }

    private func getLocalRequest(
        withId id: String, loggingOnError logAction: @escaping (Error) -> Void
    ) throws -> LocalUploadRequest {
        var localRequest: LocalUploadRequest
        do {
            localRequest = try getLocalRequest(withId: id)
        } catch {
            logAction(error)
            throw error
        }
        return localRequest
    }
}
