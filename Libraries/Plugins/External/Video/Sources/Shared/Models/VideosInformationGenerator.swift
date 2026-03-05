//
//  VideosInformationGenerator.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 5/3/24.
//

import Foundation

final class VideosInformationGenerator {
    private let commandExecutor: FFMPEGCommandExecutor
    private let credentialsManager: TruvideoCredentialsManager
    private let videosValidator: TruvideoSdkVideoFileValidator

    init(
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        videosValidator: TruvideoSdkVideoFileValidator = .init()
    ) {
        self.credentialsManager = credentialsManager
        self.commandExecutor = commandExecutor
        self.videosValidator = videosValidator
    }

    func getVideoInformation(video: URL) async throws -> TruvideoSdkVideoInformation {
        try validateAuthentication()
        try videosValidator.validateVideosExistence(videos: [video])
        return try await generateAssetMetadata(video: video)
    }

    func generateAssetsMetadata(
        videos: [URL]
    ) async throws -> [TruvideoSdkVideoInformation] {
        var assetsMetadata = [TruvideoSdkVideoInformation]()
        for videoInput in videos {
            Logger.addLog(event: .getInfo, eventMessage: .getInfo(videoPath: videoInput))
            do {
                try await assetsMetadata.append(
                    commandExecutor.getMediaInformation(videoInput)
                )
            } catch {
                Logger.addLog(event: .getInfo, eventMessage: .getInfoFailed(videoPath: videoInput, error: error))
                throw error
            }
        }
        return assetsMetadata
    }

    func generateAssetMetadata(
        video: URL
    ) async throws -> TruvideoSdkVideoInformation {
        Logger.addLog(event: .getInfo, eventMessage: .getInfo(videoPath: video))
        do {
            return try await commandExecutor.getMediaInformation(video)
        } catch {
            Logger.addLog(event: .getInfo, eventMessage: .getInfoFailed(videoPath: video, error: error))
            throw error
        }
    }

    private func validateAuthentication() throws {
        if !credentialsManager.isUserAuthenticated() {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
    }
}
