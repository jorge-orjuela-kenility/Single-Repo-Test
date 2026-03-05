//
//  TracksManager.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 8/7/24.
//

import Foundation

class TracksManager {
    static let shared = TracksManager()

    let commandExecutor: FFMPEGCommandExecutor
    let commandGenerator: FFMPEGVideoTracksCommandGenerator

    init(
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        commandGenerator: FFMPEGVideoTracksCommandGenerator = FFMPEGVideoTracksCommandGenerator()
    ) {
        self.commandExecutor = commandExecutor
        self.commandGenerator = commandGenerator
    }

    func addVideoTrack(
        inputPath: URL,
        outputPath: URL,
        duration: Int64,
        width: Int,
        height: Int
    ) async throws {
        let tempURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mp4")
        let createVideoCommand = commandGenerator.createVideoTrackCommand(
            tempURL: tempURL,
            duration: duration,
            width: width,
            height: height
        )

        try await commandExecutor.executeFFMPEGCommand(createVideoCommand, onUpdateSessionId: nil)

        let addVideoCommand = commandGenerator.generateAddVideoTrackCommand(
            inputPath: inputPath.path,
            tempPath: tempURL.path,
            outputPath: outputPath.path
        )

        try await commandExecutor.executeFFMPEGCommand(addVideoCommand, onUpdateSessionId: nil)

        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(atPath: tempURL.path)
        }
    }

    func addAudioTrack(
        inputPath: URL,
        outputPath: URL,
        duration: Int64
    ) async throws {
        let tempURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mp4")
        let createAudioCommand = commandGenerator.createAudioTrackCommand(tempURL: tempURL, duration: duration)

        try await commandExecutor.executeFFMPEGCommand(createAudioCommand, onUpdateSessionId: nil)

        let addAudioCommand = commandGenerator.generateAddAudioTrackCommand(
            inputPath: inputPath.path,
            tempPath: tempURL.path,
            outputPath: outputPath.path
        )

        try await commandExecutor.executeFFMPEGCommand(addAudioCommand, onUpdateSessionId: nil)

        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(atPath: tempURL.path)
        }
    }

    func removeVideoTrack(
        inputPath: URL,
        outputPath: URL
    ) async throws {
        let command = commandGenerator.generateRemoveVideoTrackCommand(inputPath: inputPath, outputPath: outputPath)

        try await commandExecutor.executeFFMPEGCommand(command, onUpdateSessionId: nil)
    }

    func removeAudioTrack(
        inputPath: URL,
        outputPath: URL
    ) async throws {
        let command = commandGenerator.generateRemoveAudioTrackCommand(inputPath: inputPath, outputPath: outputPath)

        try await commandExecutor.executeFFMPEGCommand(command, onUpdateSessionId: nil)
    }
}
