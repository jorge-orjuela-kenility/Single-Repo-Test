//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

/// The `TruvideoFileUploadTask` implementation to decouple from AWS
final class AWSS3FileUploaderTask: TruvideoFileUploadTask {
    // MARK: - Task properties

    /// Task status
    private var status: Status

    /// A variable used to know wether the upload was previously completed or not
    private var storedResult: TruvideoFileUploadTaskResult?

    /// Task id
    private(set) var id: UUID

    /// Notify cancellation
    var notifyCancelation = true

    // MARK: - Dependencies

    /// Credentials provider
    private let mediaStorageCredentialsProvider: AWSCredentialProvider

    /// Media gateway to send requests to the media endpoint
    private let mediaGateway: MediaGateway

    /// The AWSS3 Services provider to decouple from AWS
    private let s3ServicesProvider: AWSS3ServicesProvider

    /// Uploads store
    private let store: UploadStore

    // MARK: - Upload information

    /// The destination bucket
    private let bucket: String

    /// The upload information
    let uploadInformation: AWSS3UploadData

    /// The continuation to handle asynchronous calls
    private var s3UploadContinuation: CheckedContinuation<URL, Error>?

    // MARK: - Types

    /// Represents the status of the upload task.
    enum Status {
        case initiated
        case inProgress
        case completed
        case failed
        case canceled
    }

    // MARK: Initializer

    /// Creates a new instance of `TruvideoFileUploadTask`
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the upload task.
    ///   - fileURL: The URL of the file to be uploaded.
    ///   - metadata: Metadata associated with the upload.
    ///   - tags: Tags associated with the upload.
    ///   - includeInReport: A boolean indicating if the upload should be included in a report.
    ///   - credentialsProvider: The credentials provider for media storage.
    ///   - mediaGateway: The media gateway for sending requests.
    ///   - s3ServicesProvider: The AWS S3 services provider.
    ///   - store: The store for managing upload data.
    init(
        id: UUID,
        fileURL: URL,
        metadata: Metadata,
        tags: [String: String],
        includeInReport: Bool?,
        duration: Int?,
        isLibrary: Bool?,
        credentialProvider: AWSCredentialProvider,
        mediaGateway: MediaGateway,
        s3ServicesProvider: AWSS3ServicesProvider,
        store: UploadStore
    ) {
        mediaStorageCredentialsProvider = credentialProvider
        self.id = id
        self.mediaGateway = mediaGateway
        self.s3ServicesProvider = s3ServicesProvider
        self.store = store

        let credential = credentialProvider.awsCredential()

        bucket = credential.bucket
        uploadInformation = .init(
            fileURL: fileURL,
            fileId: id,
            folder: credential.folder,
            metadata: metadata,
            tags: tags,
            includeInReport: includeInReport,
            duration: duration,
            isLibrary: isLibrary
        )

        status = .initiated
        registerS3ServicesIfAuthenticated()
    }

    // MARK: - TruvideoFileUploadTask

    /// The result of the upload task.
    var result: TruvideoFileUploadTaskResult {
        get async throws {
            try await uploadIfNeeded()
        }
    }

    /// Cancels the upload task.
    func cancel() {
        guard status == .inProgress else {
            return
        }
        status = .canceled
        s3ServicesProvider.cancelUpload()
        s3UploadContinuation?.resume(throwing: TruvideoSdkMediaError.taskCancelledByTheUser)
        s3UploadContinuation = nil
    }

    /// Pauses the upload task.
    func pause() {
        s3ServicesProvider.pause()
    }

    /// Resumes the paused upload task.
    func resume() {
        s3ServicesProvider.resume()
    }

    /// A stream that emits progress updates for the upload task.
    var progress: AsyncStream<TruvideoFileUploadTaskProgress> {
        progressStreamer.stream
    }

    private var progressStreamer = TruvideoFileUploadTaskProgressStream()

    // MARK: - Private methods

    private func registerS3ServicesIfAuthenticated() {
        let credential = mediaStorageCredentialsProvider.awsCredential()
        guard credential.isUserAuthenticated else {
            return
        }

        s3ServicesProvider.registerServicesIfNeeded()
    }

    private func uploadIfNeeded() async throws -> TruvideoFileUploadTaskResult {
        guard status != .completed else {
            if let storedResult {
                return storedResult
            } else {
                throw TruvideoSdkMediaError.generic
            }
        }
        guard uploadInformation.isValid else {
            throw TruvideoSdkMediaError.invalidFile(url: uploadInformation.fileURL)
        }

        let uploadedFileURL = try await uploadFileToS3(data: uploadInformation)
        store.updateUpload(withId: id.uuidString, data: .init(status: .synchronizing))
        let media = try await createMedia(withURL: uploadedFileURL)

        storedResult = media

        store.updateUpload(
            withId: id.uuidString,
            data: .init(
                includeInReport: media.includeInReport,
                isLibrary: media.isLibrary
            )
        )

        return media
    }

    @discardableResult
    private func createMedia(withURL url: URL) async throws -> MediaDTO {
        do {
            return try await mediaGateway.create(
                media: .init(
                    title: uploadInformation.fileName,
                    type: uploadInformation.fileType,
                    url: url,
                    size: uploadInformation.fileSize,
                    resolution: "LOW",
                    metadata: uploadInformation.metadata,
                    tags: uploadInformation.tags,
                    includeInReport: uploadInformation.includeInReport,
                    duration: uploadInformation.duration,
                    isLibrary: uploadInformation.isLibrary
                )
            )
        } catch {
            // Lets not expose underlying errors to end clients...
            throw TruvideoSdkMediaError.generic
        }
    }

    private func uploadFileToS3(data: AWSS3UploadData) async throws -> URL {
        status = .inProgress
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            self.s3UploadContinuation = continuation

            self.s3ServicesProvider.uploadedFile(
                uploadData: data,
                onProgressChange: { progress in
                    self.progressStreamer.update(progress: .init(percentage: progress))
                },
                onTaskStarted: { taskIdentifier in
                    self.store.updateUpload(
                        withId: self.id.uuidString,
                        data: .init(
                            cloudServiceId: String(taskIdentifier),
                            status: .processing,
                            includeInReport: self.uploadInformation.includeInReport,
                            isLibrary: self.uploadInformation.isLibrary
                        )
                    )
                },
                completion: { result in
                    guard self.status == .inProgress else { return }
                    switch result {
                    case let .success(url):
                        self.status = .completed
                        continuation.resume(returning: url)

                    case let .failure(error):
                        self.status = .failed
                        continuation
                            .resume(throwing: TruvideoSdkMediaError.uploadError(message: error.localizedDescription))
                    }
                }
            )
        }
    }
}
