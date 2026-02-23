//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
internal import TruVideoFoundation
import UIKit

extension CameraViewModel {
    // MARK: - Private Computed Properties

    /// Determines whether more video clips can be recorded based on configuration limits.
    ///
    /// This computed property checks the camera configuration mode to determine if
    /// additional video clips can be recorded.
    ///
    /// - Returns: `true` if more video clips can be recorded, `false` if limit is reached
    private var canTakeMoreClips: Bool {
        let mode = configuration.mode

        guard mode.maxPictureCount == 0, mode.maxVideoCount == 0, mode.maxMediaCount > 0 else {
            return medias.lazy.filter(\.isClip).count < mode.maxVideoCount
        }

        return mediasTaken < mode.maxMediaCount
    }

    // MARK: - Recording

    /// Toggles the recording state between pause and record.
    ///
    /// This function manages the recording lifecycle by checking the current state
    /// of the video device and performing the appropriate action. If the device
    /// is currently running, it pauses the recording by pausing the movie processing.
    func togglePause() {
        Task { @MainActor in
            switch movieOutputProcessor.state {
            case .paused:
                do {
                    guard audioDevice.isAvailable else {
                        throw UtilityError(kind: .unknown, failureReason: Localizations.anotherAppIsUsingMicrophone)
                    }

                    try await audioDevice.startCapturing()
                    try await videoDevice.startCapturing()

                    await movieOutputProcessor.startProcessing()

                    state = .running

                    ensureTorchCompatibility()

                    let secondsRecorded = movieOutputProcessor.recordingDuration.seconds

                    monitor.cameraDidResumeRecording(resumeTime: secondsRecorded, context: makeContextSnapshot())

                    UIApplication.shared.isIdleTimerDisabled = true
                } catch {
                    didReceiveError(error.localizedDescription)
                    monitor.cameraDidFailToResumeRecording(error: error, context: makeContextSnapshot())
                }

            case .writing:
                pauseSession()

            default:
                break
            }
        }
    }

    /// Toggles the recording state between start and stop.
    ///
    /// This function manages the recording lifecycle by checking the current state
    /// of the video device and performing the appropriate action. If the device
    /// is currently running, it stops the recording by ending movie processing
    /// and stopping the recorder. If the device is not running, it starts
    /// recording by calling the recorder's record method.
    ///
    /// The function operates on the main actor to ensure UI updates are performed
    /// safely and handles errors by setting the localized error description
    /// for user feedback. It uses async/await for proper coordination between
    /// the video device state and recorder operations.
    func toggleRecord() {
        Task { @MainActor in
            do {
                switch movieOutputProcessor.state {
                case .initialized, .finished, .failed:
                    try await startRecording()

                case .paused where state.canTransition(to: .finished),
                     .writing where state.canTransition(to: .finished):
                    try await endRecording()

                default:
                    break
                }
            } catch {
                mediasTaken -= 1

                didReceiveError(error.localizedDescription)
                monitor.cameraDidFailToStartRecording(error: error, context: makeContextSnapshot())
            }
        }
    }

    // MARK: - Internal methods

    /// Pauses the current recording session and all associated capture devices.
    ///
    /// This function safely pauses an active recording session by stopping the movie
    /// output processor and pausing both audio and video capture devices. It performs
    /// the pause operation asynchronously and handles any errors that occur during
    /// the process by displaying them to the user through the error handling system.
    ///
    /// ## Error Handling
    ///
    /// Any errors that occur during the pause operation are automatically caught
    /// and displayed to the user through the snackbar interface via `didReceiveError(_:)`,
    /// ensuring that users are informed of any issues that prevent proper session pausing.
    @MainActor
    func pauseSession() {
        Task {
            _ = await (movieOutputProcessor.pause(), audioDevice.pause(), videoDevice.pause())

            let secondsRecorded = movieOutputProcessor.recordingDuration.seconds

            state = .paused

            ensureTorchCompatibility()
            monitor.cameraDidPauseRecording(pauseTime: secondsRecorded, context: makeContextSnapshot())

            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Private methods

    @MainActor
    private func endRecording() async throws {
        state = .finished

        let clip = try await movieOutputProcessor.endProcessing()

        ensureTorchCompatibility()

        await videoDevice.pause()
        await audioDevice.pause()

        if configuration.orientation == nil, UIDevice.current.orientation.isSupported {
            orientationDidUpdate(to: UIDevice.current.orientation)
        }

        UIApplication.shared.isIdleTimerDisabled = false

        guard clip.hasValidSize() else {
            throw UtilityError(kind: .unknown, failureReason: Localizations.maxFileSizeExceeded)
        }

        medias.append(.clip(clip))

        startStreamIfNeeded(from: clip.url, of: .mp4)
        monitor.cameraDidFinishRecording(clip: clip, context: makeContextSnapshot())
    }

    private func ensureTorchCompatibility() {
        isTorchAvailable =
            switch state {
            case .running:
                videoDevice.isTorchAvailable

            default:
                videoDevice.isTorchAvailable || videoDevice.isFlashAvailable
            }

        if !isTorchAvailable, isTorchEnabled {
            switchTorch()
        }
    }

    @MainActor
    private func startRecording() async throws {
        guard configuration.mode.maxVideoDuration != 0 else {
            throw UtilityError(kind: .unknown, failureReason: Localizations.videoDurationZero)
        }

        guard canTakeMoreClips else {
            throw UtilityError(kind: .unknown, failureReason: Localizations.maxNumberOfClipsReached)
        }

        guard audioDevice.isAvailable else {
            throw UtilityError(kind: .unknown, failureReason: Localizations.anotherAppIsUsingMicrophone)
        }

        mediasTaken += 1

        try await videoDevice.startCapturing()
        try await audioDevice.startCapturing()

        await movieOutputProcessor.startProcessing()

        state = .running

        ensureTorchCompatibility()
        monitor.cameraDidStartRecording(configuration: configuration, context: makeContextSnapshot())

        UIApplication.shared.isIdleTimerDisabled = true

        guard videoDevice.torchMode == .off, isTorchEnabled, isTorchAvailable else {
            return
        }

        try await videoDevice.setTorchMode(.on)
    }
}

extension VideoClip {
    /// Determines whether the video clip's file size is within the acceptable limit.
    ///
    /// This method checks if the video file associated with this clip meets the size requirements
    /// by reading the file attributes from the file system. The maximum allowed file size is
    /// 600 megabytes (629,145,600 bytes). If the file cannot be accessed or its size cannot be
    /// determined, this method returns false to indicate an invalid or inaccessible file.
    ///
    /// - Returns: `true` if the file size is less than or equal to 600 MB, `false` if the file
    ///   exceeds the limit or if an error occurs while accessing the file.
    fileprivate func hasValidSize() -> Bool {
        do {
            let maxFileSize = 600 * 1_024 * 1_024
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0

            return fileSize <= maxFileSize
        } catch {
            return false
        }
    }
}
