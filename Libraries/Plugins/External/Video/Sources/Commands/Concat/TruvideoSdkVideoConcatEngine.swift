//
//  TruvideoSdkVideoConcatEngine.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 5/3/24.
//

import Foundation

final class TruvideoSdkVideoConcatEngine: TruvideoSdkVideoRequestEngine {
    
    private let commandGenerator: FFMPEGCommandGenerator
    private let commandExecutor: FFMPEGCommandExecutor
    private let credentialsManager: TruvideoCredentialsManager
    private let minimumSupportedResolutionDimension: CGFloat = 128
    private let store: VideoStore
    private let inputValidator: ConcatInputValidator
    private let videosInformationGenerator: VideosInformationGenerator
    private let videosValidator: TruvideoSdkVideoFileValidator
    
    init(
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp(),
        commandGenerator: FFMPEGCommandGenerator = FFMPEGCommandGenerator(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        inputValidator: ConcatInputValidator = .init(),
        videosInformationGenerator: VideosInformationGenerator = .init(),
        videosValidator: TruvideoSdkVideoFileValidator = .init(),
        store: VideoStore
    ) {
        self.credentialsManager = credentialsManager
        self.commandGenerator = commandGenerator
        self.commandExecutor = commandExecutor
        self.inputValidator = inputValidator
        self.videosInformationGenerator = videosInformationGenerator
        self.videosValidator = videosValidator
        self.store = store
    }
    
    func process(request: TruvideoSdkVideoRequest) async throws -> TruvideoSdkVideoRequest.Result {
        try validateAuthentication()
        try validateRequestStatus(request: request)
        guard let concatData = request.concatData else {
            updateRequestRequest(id: request.id, withFields: .status(value: .error))
            throw TruvideoSdkVideoError.concatFailed
        }
        let videos = concatData.videos
        guard let outputURL = request.output.url(
            fileExtension: videos.first?.pathExtension ?? FileExtension.mp4.rawValue
        ) else {
            throw TruvideoSdkVideoError.concatFailed
        }
        try videosValidator.validateVideosExistence(videos: videos, minVideosCount: 2)
        let assetsMetadata = try await videosInformationGenerator.generateAssetsMetadata(videos: videos)
        try await inputValidator.validateVideosForConcat(concatData.videos)
        
        let ffmpegCommand = commandGenerator.generateConcatCommandFor(
            videosInfo: assetsMetadata,
            inputPath: TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "txt"),
            outputPath: outputURL.path
        )
        do {
            updateRequestRequest(id: request.id, withFields: .status(value: .processing))
            try await commandExecutor.executeFFMPEGCommand(ffmpegCommand.script) { [weak self] sessionId in
                self?.updateRequestRequest(id: request.id, withFields: .processId(value: "\(sessionId)"))
            }
            ffmpegCommand.inputFilesListFilePaths.forEach { [weak commandGenerator] in
                commandGenerator?.deleteInputFilesListFile(path: $0)
            }
            updateRequestRequest(id: request.id, withFields: .status(value: .completed), .processId(value: nil))
            return .init(videoURL: outputURL)
        } catch {
            if !isRequestCancelled(request: request) {
                updateRequestRequest(id: request.id, withFields: .status(value: .error), .processId(value: nil))
            }
            throw TruvideoSdkVideoError.concatFailed
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
