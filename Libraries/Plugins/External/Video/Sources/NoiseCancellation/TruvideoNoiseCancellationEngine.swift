//
//  TruvideoNoiseCancellationEngine.swift
//  TruvideoSdkNoiseCancelling
//
//  Created by Luis Francisco Piura Mejia on 17/10/23.
//

import AudioToolbox
import AVFoundation

/// An `TruVideoNoiseCancellationEngine` process the noise cancellation
/// to an audio file returning as a result a new file.
///
///     ### Example
///     let engine = TruVideoNoiseCancellationEngine()
///     engine.process(from: <URL>)
///
///
class TruvideoNoiseCancellationEngine: TruvideoSdkVideoNoiseCancellationEngine {
    /// The current state of the engine.
    private(set) var state: State = .initial

    /// Processor used to perform file operations
    private let fileProcessor: TruvideoFileProcessor

    /// Delegate to generate commands
    private let commandGenerator: FFMPEGCommandGenerator

    /// Delegate to execute commands
    private let commandExecutor: FFMPEGCommandExecutor

    /// Credentials manager used to validate authentication
    private let credentialsManager: TruvideoCredentialsManager

    private let videoValidator: TruvideoSdkVideoFileValidator

    /// Represents the possible states of the
    enum State {
        /// Whether the engine has finished processing.
        case finished

        /// Initial state of the engine.
        case initial

        /// Engine has been initialized.
        case initialized

        /// Whether the engine is processing a file.
        case processing

        /// Unknown state
        case unknown
    }

    // MARK: Constants

    private let FRAME_DURATION: UInt = 10 // ms
    private let SAMPLING_FREQ: UInt = 32_000 // khz
    private let MODEL_NAME = "model_32.kw"

    // MARK: Initializers

    init(
        fileProcessor: TruvideoFileProcessor = .init(),
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp(),
        commandGenerator: FFMPEGCommandGenerator = FFMPEGCommandGenerator(),
        commandExecutor: FFMPEGCommandExecutor = FFMPEGCommandExecutorImplementation(),
        videoValidator: TruvideoSdkVideoFileValidator = .init()
    ) {
        self.fileProcessor = fileProcessor
        self.credentialsManager = credentialsManager
        self.commandGenerator = commandGenerator
        self.commandExecutor = commandExecutor
        self.videoValidator = videoValidator
        initialize()
    }

    // MARK: Instance methods

    /// Loads and process the audio from the given file performing the noise cancellation
    /// process and returns a temporal url for the new generated file.
    ///
    /// - Parameter fileURL: The origin of the audio file to be processed.
    /// - Returns: The destination url of the new generated.
    func clearNoiseForFile(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor
    ) async throws -> TruvideoSdkVideoNoiseCancellationResult {
        let fileURL = input.url
        guard let outputURL = output.url(fileExtension: input.fileExtension) else {
            throw TruvideoSdkVideoError.unableToProcessOutput
        }

        Logger.addLog(event: .clearNoise, eventMessage: .clearNoise(
            videoPath: fileURL,
            resultPath: outputURL
        ))
        guard state != .initial, state != .unknown else {
            throw TruvideoSdkVideoError.configurationError
        }

        guard state != .processing else {
            throw TruvideoSdkVideoError.processingInProgress
        }

        state = .processing

        defer {
            state = .finished
        }
        var processedFiles = [URL]()
        do {
            guard credentialsManager.isUserAuthenticated() else {
                throw TruvideoSdkVideoError.userNotAuthenticated
            }
            try videoValidator.validateFileAt(url: fileURL)
            let originalFileAudioURL = try await extractAudioForFile(at: fileURL)
            processedFiles.append(originalFileAudioURL)
            let cleanAudioFileURL = try await cleanAudio(fileURL: fileURL, audioFileURL: originalFileAudioURL)
            processedFiles.append(cleanAudioFileURL)
            let mergedFileURL = try await fileProcessor.mergeVideoWithAudio(
                videoURL: fileURL,
                audioURL: cleanAudioFileURL,
                outputURL: outputURL
            )
            remove(processedFiles: processedFiles)
            return .init(fileURL: mergedFileURL)
        } catch {
            Logger.logError(event: .clearNoise, eventMessage: .clearNoiseFailed(videoPath: fileURL, error: error))
            endSession()
            remove(processedFiles: processedFiles)
            throw error
        }
    }

    /// Extracts the audio of the video in order to process audio for multiple types of file
    /// - Parameter path: Video path
    /// - Returns: Returns the URL of audio ayer of  the provided video
    func extractAudioForFile(at videoURL: URL) async throws -> URL {
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "wav")
        let command = commandGenerator.generateExtractAudioCommandFor(videoURL: videoURL, outputPath: outputURL)

        do {
            try await commandExecutor.executeFFMPEGCommand(command)
            return outputURL
        } catch {
            throw TruvideoSdkVideoError.unableToProcessInput
        }
    }

    // MARK: Private methods

    private func remove(processedFiles: [URL]) {
        for processedFile in processedFiles {
            fileProcessor.removeFile(at: processedFile)
        }
    }

    private func cleanAudio(fileURL: URL, audioFileURL: URL) async throws -> URL {
        let sourceFile = try AVAudioFile(forReading: audioFileURL)
        let destinationURL = URL.createTemporaryURL()
        let outputFile = try AVAudioFile(forWriting: destinationURL, settings: sourceFile.fileFormat.settings)

        let bufferSize =
            AVAudioFrameCount(Int(FRAME_DURATION * SAMPLING_FREQ /
                    1000)) // according to Krisp Docs this is the frameSize

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: sourceFile.processingFormat,
            frameCapacity: bufferSize
        ) else {
            throw TruvideoSdkVideoError.unableToProcessFile
        }

        let processor = TruVideoNoiseProcessor(
            modelName: MODEL_NAME,
            sampleRate: SAMPLING_FREQ,
            frameDuration: FRAME_DURATION
        )
        try processor.startSession()

        while sourceFile.framePosition < sourceFile.length {
            let framesToRead = min(bufferSize, AVAudioFrameCount(sourceFile.length - sourceFile.framePosition))
            try sourceFile.read(into: buffer, frameCount: framesToRead)

            var processedBuffer = buffer
            processor.process(bufferIn: buffer, bufferOut: &processedBuffer)

            try outputFile.write(from: processedBuffer)
        }

        try processor.endSession()

        return destinationURL
    }

    private func initialize() {
        Bundle.main.resourcePath?.withWideChars { wchar in
            let status = krispAudioGlobalInit(wchar, 0)
            if status == 0 {
                state = .initialized
            } else {
                state = .unknown
            }
        }
    }

    private func endSession() {
        krispAudioGlobalDestroy()
    }
}

private extension AVAudioPlayerNode {
    func scheduleIgnoringCompletion(file: AVAudioFile) {
        scheduleFile(file, at: nil) {}
    }
}

private extension URL {
    static func createTemporaryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString.appending(".wav"))
    }
}
