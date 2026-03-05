//
//  TruvideoSdkVideoMergeEngine.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 1/12/23.
//

import AVKit
import Foundation

final class TruvideoSdkVideoMergeEngine: TruvideoSdkVideoRequestEngine {
    private let commandGenerator: FFMPEGMergeCommandGenerator
    private let commandExecutor: FFMPEGCommandExecutor
    private let credentialsManager: TruvideoCredentialsManager
    private let minimumSupportedResolutionDimension: CGFloat = 128
    private let store: VideoStore
    private let videosInformationGenerator: VideosInformationGenerator
    private let videosValidator: TruvideoSdkVideoFileValidator

    init(
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp(),
        commandGenerator: FFMPEGMergeCommandGenerator = FFMPEGMergeCommandGenerator(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        videosInformationGenerator: VideosInformationGenerator = .init(),
        videosValidator: TruvideoSdkVideoFileValidator = .init(),
        store: VideoStore
    ) {
        self.credentialsManager = credentialsManager
        self.commandGenerator = commandGenerator
        self.commandExecutor = commandExecutor
        self.videosInformationGenerator = videosInformationGenerator
        self.videosValidator = videosValidator
        self.store = store
    }

    func process(request: TruvideoSdkVideoRequest) async throws -> TruvideoSdkVideoRequest.Result {
        try validateAuthentication()
        try validateRequestStatus(request: request)
        guard let mergeData = request.mergeData else {
            updateRequestRequest(id: request.id, withFields: .status(value: .error))
            throw TruvideoSdkVideoError.mergeFailed
        }
        let videos = mergeData.videos

        try videosValidator.validateVideosExistence(videos: videos, minVideosCount: 2)
        try validateResolution(component: mergeData.width)
        try validateResolution(component: mergeData.height)

        let videosInfo = try await videosInformationGenerator.generateAssetsMetadata(videos: mergeData.videos)
        guard let outputURL = request.output.url(fileExtension: FileExtension.mp4.rawValue) else {
            throw TruvideoSdkVideoError.unableToProcessOutput
        }

        let ffmpegCommand = commandGenerator.generateCommand(
            videosInfo: videosInfo,
            width: mergeData.width,
            height: mergeData.height,
            videoTracks: mergeData.videoTracks,
            audioTracks: mergeData.audioTracks,
            framesRate: mergeData.framesRate,
            outputPath: outputURL.path
        )
        do {
            updateRequestRequest(id: request.id, withFields: .status(value: .processing))
            try await commandExecutor.executeFFMPEGCommand(ffmpegCommand.script) { [weak self] sessionId in
                self?.updateRequestRequest(id: request.id, withFields: .processId(value: "\(sessionId)"))
            }
            updateRequestRequest(id: request.id, withFields: .status(value: .completed), .processId(value: nil))
            return .init(videoURL: outputURL)
        } catch {
            Logger.logError(event: .mergeRequest, eventMessage: .mergeRequestFailed(error: error))
            if !isRequestCancelled(request: request) {
                updateRequestRequest(id: request.id, withFields: .status(value: .error), .processId(value: nil))
            }
            throw TruvideoSdkVideoError.mergeFailed
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

    private func validateAuthentication() throws {
        if !credentialsManager.isUserAuthenticated() {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
    }

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

    private func validateResolution(component: CGFloat?) throws {
        guard let component else {
            return
        }

        guard component >= minimumSupportedResolutionDimension else {
            throw TruvideoSdkVideoError.invalidResolution
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
