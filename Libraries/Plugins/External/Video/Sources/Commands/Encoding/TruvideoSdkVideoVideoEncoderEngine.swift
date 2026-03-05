//
//  TruvideoSdkVideoVideoEncoderEngine.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 16/2/24.
//

import Foundation

final class TruvideoSdkVideoVideoEncoderEngine: TruvideoSdkVideoRequestEngine {
    private let credentialsManager: TruvideoCredentialsManager
    private let videoValidator: TruvideoSdkVideoFileValidator
    private let commandExecutor: FFMPEGCommandExecutor
    private let commandGenerator: FFMPEGMergeCommandGenerator
    private let store: VideoStore

    init(
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp(),
        videoValidator: TruvideoSdkVideoFileValidator = .init(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        commandGenerator: FFMPEGMergeCommandGenerator = .init(),
        store: VideoStore
    ) {
        self.credentialsManager = credentialsManager
        self.videoValidator = videoValidator
        self.commandExecutor = commandExecutor
        self.commandGenerator = commandGenerator
        self.store = store
    }

    func process(request: TruvideoSdkVideoRequest) async throws -> TruvideoSdkVideoRequest.Result {
        try validateAuthentication()
        try validateRequestStatus(request: request)
        guard let encodingData = request.encodingData else {
            updateRequestRequest(id: request.id, withFields: .status(value: .error))
            throw TruvideoSdkVideoError.encodingFailed
        }
        let url = encodingData.inputFileURL
        guard let outputURL = request.output.url(fileExtension: FileExtension.mp4.rawValue) else {
            throw TruvideoSdkVideoError.unableToProcessOutput
        }
        try videoValidator.validateFileAt(url: url)
        try videoValidator.validateResolution(component: encodingData.width)
        try videoValidator.validateResolution(component: encodingData.height)
        do {
            let videoInfo = try await commandExecutor.getMediaInformation(url)
            let command = commandGenerator.generateCommand(
                videosInfo: [videoInfo],
                width: encodingData.width,
                height: encodingData.height,
                videoTracks: encodingData.videoTracks.map { entry in
                    .init(
                        tracks: [.init(fileIndex: 0, entryIndex: entry.entryIndex)],
                        width: entry.width,
                        height: entry.height
                    )
                },
                audioTracks: encodingData.audioTracks.map { entry in
                    .init(
                        tracks: [.init(fileIndex: 0, entryIndex: entry)]
                    )
                },
                framesRate: encodingData.framesRate,
                outputPath: outputURL.path
            )
            updateRequestRequest(id: request.id, withFields: .status(value: .processing))
            TruvideoSdkVideoUtils.deleteFileIfExists(atURL: outputURL)
            try await commandExecutor.executeFFMPEGCommand(command.script) { [weak self] sessionId in
                self?.updateRequestRequest(id: request.id, withFields: .processId(value: "\(sessionId)"))
            }
            updateRequestRequest(id: request.id, withFields: .status(value: .completed), .processId(value: nil))
            return .init(videoURL: outputURL)
        } catch {
            Logger.logError(event: .processRequest, eventMessage: .processRequestFailed(error: error))
            if !isRequestCancelled(request: request) {
                updateRequestRequest(id: request.id, withFields: .status(value: .error), .processId(value: nil))
            }
            throw TruvideoSdkVideoError.encodingFailed
        }
    }

    func cancel(request: TruvideoSdkVideoRequest) throws {
        guard
            let retrievedRequest = try? store.getRequest(withId: request.id),
            let retrievedRequestExternalId = retrievedRequest.processId,
            let externalId = Int(retrievedRequestExternalId)
        else {
            throw TruvideoSdkVideoError.operationNotFound
        }
        guard retrievedRequest.status == .processing else {
            throw TruvideoSdkVideoError.operationMustBeProcessingToBeCancelled
        }
        commandExecutor.cancelCommandExecution(sessionId: externalId)
        updateRequestRequest(id: request.id, withFields: .status(value: .cancelled), .processId(value: nil))
    }

    // MARK: - Private methods

    private func isRequestCancelled(request: TruvideoSdkVideoRequest) -> Bool {
        let retrievedRequest = try? store.getRequest(withId: request.id)
        return retrievedRequest?.status == .cancelled
    }

    private func updateRequestRequest(id: UUID, withFields fields: UpdateRequestData.Field...) {
        do {
            try store.updateRequest(withId: id, data: .init(fields: .init(fields)))
        } catch {
            print("Request update failed with error \(error)")
        }
    }

    private func validateAuthentication() throws {
        if !credentialsManager.isUserAuthenticated() {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
    }

    private func validateRequestStatus(request: TruvideoSdkVideoRequest) throws {
        guard
            let fetchedRequest = try? store.getRequest(withId: request.id)
        else {
            throw TruvideoSdkVideoError.operationNotFound
        }
        if fetchedRequest.status == .processing {
            throw TruvideoSdkVideoError.operationStillsInProgress
        }
        if fetchedRequest.status == .completed {
            throw TruvideoSdkVideoError.operationAlreadyCompleted
        }
    }
}
