//
//  ConcatInputValidator.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 5/3/24.
//

import Foundation

final class ConcatInputValidator {
    private let commandExecutor: FFMPEGCommandExecutor
    private let credentialsManager: TruvideoCredentialsManager
    private let videosInformationGenerator: VideosInformationGenerator
    private let videosValidator: TruvideoSdkVideoFileValidator

    init(
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp(),
        videosInformationGenerator: VideosInformationGenerator = .init(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        videosValidator: TruvideoSdkVideoFileValidator = .init()
    ) {
        self.credentialsManager = credentialsManager
        self.commandExecutor = commandExecutor
        self.videosInformationGenerator = videosInformationGenerator
        self.videosValidator = videosValidator
    }

    func canProcessConcatWith(videos: [URL]) async throws -> Bool {
        try validateAuthentication()
        try videosValidator.validateVideosExistence(videos: videos, minVideosCount: 2)
        do {
            try await validateVideosForConcat(videos)
            return true
        } catch {
            Logger.logError(event: .compareVideo, eventMessage: .compareFailed(error: error))
            return false
        }
    }

    func validateVideosForConcat(_ videos: [URL]) async throws {
        let videosInfo = try await videosInformationGenerator.generateAssetsMetadata(videos: videos)
        let firstVideoInfo = videosInfo[0]

        for videoInfo in videosInfo {
            guard firstVideoInfo.format == videoInfo.format else {
                throw TruvideoSdkVideoError.invalidInputFiles(reason: .differentFormats)
            }
            guard firstVideoInfo.videoTracks == videoInfo.videoTracks else {
                throw TruvideoSdkVideoError.invalidInputFiles(reason: .differentVideoTracks)
            }
            guard firstVideoInfo.audioTracks == videoInfo.audioTracks else {
                throw TruvideoSdkVideoError.invalidInputFiles(reason: .differentAudioTracks)
            }
        }
    }

    private func validateAuthentication() throws {
        if !credentialsManager.isUserAuthenticated() {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
    }
}
