//
//  TruvideoSdkVideoThumbnailGeneratorImplementation.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 12/6/23.
//

import AVFoundation
import Foundation

final class TruvideoSdkVideoThumbnailGeneratorImplementation: TruvideoSdkVideoThumbnailGenerator {
    private let commandGenerator: FFMPEGCommandGenerator
    private let commandExecutor: FFMPEGCommandExecutor

    /// Credentials manager used to validate authentication
    private let credentialsManager: TruvideoCredentialsManager

    init(
        commandGenerator: FFMPEGCommandGenerator = FFMPEGCommandGenerator(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp()
    ) {
        self.commandGenerator = commandGenerator
        self.commandExecutor = commandExecutor
        self.credentialsManager = credentialsManager
    }

    func generateThumbnail(for video: TruvideoSdkVideoThumbnailInputVideo) async throws
    -> TruvideoSdkVideoThumbnailResult {
        let videoURL = video.input.url
        Logger.addLog(event: .createThumbnail, eventMessage: .createThumbnail(videoPath: videoURL))
        guard credentialsManager.isUserAuthenticated() else {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
        if !FileManager.default.fileExists(atPath: videoURL.path) {
            throw TruvideoSdkVideoError.notFoundVideo
        }

        if let width = video.width, width < 0 {
            throw TruvideoSdkVideoError.invalidThumbnailWidth
        }

        if let height = video.height, height < 0 {
            throw TruvideoSdkVideoError.invalidThumbnailHeight
        }

        guard try await isValidPosition(video.position, in: videoURL) else {
            throw TruvideoSdkVideoError.invalidPositionInVideo
        }

        guard let outputURL = video.output.url(fileExtension: FileExtension.jpg.rawValue) else {
            throw TruvideoSdkVideoError.notFoundVideo
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try deleteExistingThumbnail(at: outputURL)
        }

        let command = commandGenerator.generateThumbnailGenerationCommandFor(video: video, outputPath: outputURL)

        do {
            try await commandExecutor.executeFFMPEGCommand(command)

            return TruvideoSdkVideoThumbnailResult(generatedThumbnailURL: outputURL)
        } catch {
            Logger.logError(
                event: .createThumbnail,
                eventMessage: .createThumbnailFailed(videoPath: videoURL, error: error)
            )
            throw TruvideoSdkVideoError.thumbnailGenerationFailed
        }
    }

    private func deleteExistingThumbnail(at url: URL) throws {
        do {
            try FileManager.default.removeItem(atPath: url.path)
        } catch {
            throw TruvideoSdkVideoError.unableToDeleteExistingThumbnail
        }
    }

    private func isValidPosition(_ position: TimeInterval, in url: URL) async throws -> Bool {
        let duration = try await getVideoDuration(fromURL: url)
        return position >= 0 && position < duration
    }

    private func getVideoDuration(fromURL url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        return try await asset.load(.duration).seconds
    }
}
