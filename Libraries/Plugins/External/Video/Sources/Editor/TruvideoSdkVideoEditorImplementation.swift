//
//  TruvideoSdkVideoEditorImplementation.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 14/12/23.
//

import AVKit
import Foundation

final class TruvideoSdkVideoEditorImplementation: TruvideoSdkVideoEditor {
    private let credentialsManager: TruvideoCredentialsManager
    private let commandExecutor: FFMPEGCommandExecutor
    private let commandGenerator: FFMPEGCommandGenerator
    private let videoValidator: TruvideoSdkVideoFileValidator

    init(
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        commandGenerator: FFMPEGCommandGenerator = FFMPEGCommandGenerator(),
        videoValidator: TruvideoSdkVideoFileValidator = .init()
    ) {
        self.credentialsManager = credentialsManager
        self.commandExecutor = commandExecutor
        self.commandGenerator = commandGenerator
        self.videoValidator = videoValidator
    }

    func edit(video: TruvideoSdkVideoEditorInput) async throws -> TruvideoSdkVideoEditorResult {
        Logger.addLog(event: .editVideo, eventMessage: .editVideo(videoPath: video.videoURL))
        guard credentialsManager.isUserAuthenticated() else {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
        try videoValidator.validateFileAt(url: video.videoURL)
        try await validateTrimRange(
            url: video.videoURL,
            trimStart: video.startPosition,
            trimEnd: video.endPosition
        )
        do {
            let command = commandGenerator.generateEditCommand(
                inputFile: video.videoURL,
                trimStart: video.startPosition,
                trimEnd: video.endPosition,
                rotationAngle: video.rotationAngle,
                volumenLevel: video.volumen,
                outputFile: video.outputURL
            )
            try await commandExecutor.executeFFMPEGCommand(command.script)
        } catch {
            Logger.logError(event: .editVideo, eventMessage: .editVideoFailed(error: error))
            throw TruvideoSdkVideoError.trimFailed
        }
        return .init(editedVideoURL: video.outputURL)
    }

    func getThumbnailForVideo(
        at url: URL,
        interval: TimeInterval,
        width: Int? = nil,
        height: Int? = nil
    ) async throws -> URL {
        guard credentialsManager.isUserAuthenticated() else {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
        try videoValidator.validateFileAt(url: url)
        try await validateThumbnailPosition(url: url, interval: interval)
        let outputPath = TruvideoSdkVideoUtils.outputURL(
            for: UUID().uuidString,
            fileExtension: FileExtension.jpg.rawValue
        )
        let command = commandGenerator.generateThumbnailForTrim(
            video: url,
            interval: interval,
            width: width,
            height: height,
            outputPath: outputPath.path
        )
        do {
            try await commandExecutor.executeFFMPEGCommand(command.script)
            return outputPath
        } catch {
            throw TruvideoSdkVideoError.trimFailed
        }
    }

    private func validateTrimRange(
        url: URL,
        trimStart: TimeInterval,
        trimEnd: TimeInterval
    ) async throws {
        let asset = AVAsset(url: url)
        var duration: Double
        do {
            duration = try await asset.load(.duration).seconds
        } catch {
            throw TruvideoSdkVideoError.invalidFile
        }

        guard
            trimEnd >= 0, trimStart >= 0,
            trimEnd > trimStart,
            trimEnd <= duration
        else {
            throw TruvideoSdkVideoError.invalidTrimRange
        }
    }

    private func validateThumbnailPosition(
        url: URL,
        interval: TimeInterval
    ) async throws {
        let asset = AVAsset(url: url)
        var duration: Double
        do {
            duration = try await asset.load(.duration).seconds
        } catch {
            throw TruvideoSdkVideoError.invalidFile
        }

        guard
            interval <= duration
        else {
            throw TruvideoSdkVideoError.invalidTrimRange
        }
    }
}
