//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
internal import TruVideoFoundation
internal import TruVideoMediaUpload
import UIKit

extension CameraViewModel {
    // MARK: - Private Computed Properties

    /// Determines whether more photos can be captured based on configuration limits.
    ///
    /// This computed property checks the camera configuration mode to determine if
    /// additional photos can be taken. It respects different limit configurations:
    /// - Individual photo count limits (`maxPictureCount`)
    /// - Combined media count limits (`maxMediaCount`)
    ///
    /// - Returns: `true` if more photos can be captured, `false` if limit is reached
    private var canTakeMorePhotos: Bool {
        let mode = configuration.mode

        guard mode.maxPictureCount == 0, mode.maxVideoCount == 0, mode.maxMediaCount > 0 else {
            return photosTaken < mode.maxPictureCount
        }

        return mediasTaken < mode.maxMediaCount
    }

    /// The time interval to wait between photo captures to prevent rapid successive captures.
    ///
    /// This computed property returns a debounce window based on the flash mode configuration.
    /// When flash is enabled, a longer debounce window (0.45 seconds) is applied to allow
    /// the flash hardware to reset and the preview to stabilize. When flash is disabled,
    /// no debounce is applied (0 seconds).
    ///
    /// - Returns: Time interval in seconds to wait between photo captures
    private var debounceWindow: TimeInterval {
        configuration.flashMode != .off ? 0.45 : 0
    }

    // MARK: - Actions

    /// Captures a photo using the photo device and adds it to the photos collection.
    ///
    /// This function initiates an asynchronous photo capture operation on the main actor.
    /// If the capture is successful, the captured photo is appended to the photos array.
    /// If an error occurs during capture, the error's localized description is stored
    /// in the localizedError property for user feedback.
    func capturePhoto() {
        Task { @MainActor in
            guard canTakeMorePhotos else {
                let error = UtilityError(kind: .unknown, failureReason: Localizations.maxNumberOfPicturesReached)

                didReceiveError(Localizations.maxNumberOfPicturesReached)
                monitor.cameraDidFailToCapturePhoto(error: error, context: makeContextSnapshot())

                return
            }

            let debounceWindow = configuration.flashMode != .off ? 0.45 : 0
            let systemUptime = ProcessInfo.processInfo.systemUptime

            if systemUptime - lastPhotoCaptureUptime < debounceWindow || isTorchEnabled, isCaptureInFlight {
                return
            }

            isCaptureInFlight = true
            lastPhotoCaptureUptime = systemUptime

            mediasTaken += 1
            photosTaken += 1

            defer { isCaptureInFlight = false }

            do {
                allowsHitTesting = false

                monitor.cameraWillCapturePhoto(context: makeContextSnapshot())
                Task.delayed(milliseconds: 600) { allowsHitTesting = true }

                let photo = try await videoDevice.capturePhoto()
                let fileType = FileType(fileFormat: photo.format)

                medias.append(.photo(photo))
                startStreamIfNeeded(from: photo.url, of: fileType)

                monitor.cameraDidCapturePhoto(photo, context: makeContextSnapshot())
            } catch {
                mediasTaken -= 1
                photosTaken -= 1

                didReceiveError(Localizations.weCouldNotTakeThePhoto)
                monitor.cameraDidFailToCapturePhoto(error: error, context: makeContextSnapshot())
            }
        }
    }

    /// Adjusts the current zoom level based on a magnification value.
    ///
    /// This method applies a magnification factor to the last known zoom factor
    /// and clamps the result to the valid range of `zoomFactors`.
    ///
    /// - The zoom factor is always kept within the minimum and maximum supported values.
    /// - If the calculated factor is below the minimum, the minimum zoom is applied.
    /// - If the factor is between the first two levels, the raw factor is used.
    /// - If the factor exceeds the second level, it is clamped to the maximum zoom.
    ///
    /// - Parameter value: The magnification multiplier from a gesture
    func magnify(by value: CGFloat) {
        if zoomFactors.count > 1 {
            monitor.cameraWillMagnifyZoom(by: value, context: makeContextSnapshot())

            let rawFactor = max(lastZoomFactor * value, zoomFactors[0])

            guard rawFactor <= zoomFactors[1] else {
                let zoomFactor = min(rawFactor, zoomFactors[zoomFactors.count - 1])
                rampZoomFactor(to: zoomFactor, rate: 0)

                return
            }

            rampZoomFactor(to: rawFactor)
            monitor.cameraDidMagnifyZoom(by: value, newZoomFactor: rawFactor, context: makeContextSnapshot())
        }
    }

    /// Smoothly animates the camera to a target zoom factor.
    ///
    /// This method updates the published `zoomFactor` and requests the underlying
    /// `VideoDevice` to ramp the zoom to the specified level. The zoom transition
    /// can be performed at a configurable rate, or using the device's default rate
    /// if none is provided. Execution is dispatched to the main actor for UI safety,
    /// and any errors encountered are forwarded through `didReceiveError(_:)`.
    ///
    /// - Parameters:
    ///   - zoomFactor: The target zoom factor to apply to the camera.
    ///   - rate: The optional speed of the zoom ramp, in device-specific units.
    func rampZoomFactor(to newZoomFactor: CGFloat, rate: Float = 10) {
        Task { @MainActor in
            do {
                zoomFactor = newZoomFactor

                try await videoDevice.setZoomFactor(zoomFactor, rate: rate)

                monitor.cameraDidChangeZoom(newZoomFactor, context: makeContextSnapshot())
            } catch {
                monitor.cameraDidFailToChangeZoom(error: error, context: makeContextSnapshot())
                didReceiveError(error.localizedDescription)
            }
        }
    }

    /// Sets the camera focus point to the specified location asynchronously.
    ///
    /// This method sets the focus point of the video device to the provided coordinates
    /// and handles any errors that may occur during the operation. The focus point
    /// change is performed on the main actor to ensure thread safety for UI updates.
    /// If an error occurs during the focus point setting, the localized error is
    /// cleared to prevent displaying stale error messages.
    ///
    /// - Parameter point: The normalized point (0.0 to 1.0) where focus should be set
    func setFocusPoint(at point: CGPoint) {
        Task { @MainActor in
            let focusPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)

            do {
                try await videoDevice.setFocusPoint(at: focusPoint)

                monitor.cameraDidChangeFocusPoint(to: focusPoint, context: makeContextSnapshot())
            } catch {
                didReceiveError(error.localizedDescription)
                monitor.cameraDidFailToSetFocusPoint(focusPoint, error: error, context: makeContextSnapshot())
            }
        }
    }

    /// Sets the capture session resolution to the specified preset.
    ///
    /// This method attempts to update the `AVCaptureSession` resolution.
    /// If the session supports the given preset, the configuration is applied
    /// within a begin/commit configuration block to ensure consistency.
    ///
    /// - Parameter preset: The `AVCaptureSession.Preset` to apply (e.g., `.hd720`, `.hd1080`).
    func setPreset(_ preset: AVCaptureSession.Preset) {
        Task { @MainActor in
            guard captureSession.canSetSessionPreset(preset) else {
                throw UtilityError(kind: .unknown, failureReason: Localizations.presetNotSupported)
            }

            captureSession.beginUpdates()
            defer { captureSession.endUpdates() }

            captureSession.sessionPreset = preset

            do {
                try await videoDevice.setZoomFactor(zoomFactor, rate: 0)

                videoDevice.configuration.preset = preset

                selectedPreset = preset
                monitor.cameraDidChangePreset(context: makeContextSnapshot())
            } catch {
                captureSession.sessionPreset = selectedPreset

                didReceiveError(Localizations.failedToSetPreset)
                monitor.cameraDidFailToChangePreset(preset, error: error, context: makeContextSnapshot())
            }
        }
    }

    /// Switches between the front and back camera positions.
    ///
    /// This function toggles the camera position between the front-facing camera (selfie camera)
    /// and the back-facing camera (main camera). It attempts to change the camera position
    /// and updates the error state if the operation fails.
    func switchCamera() {
        Task { @MainActor in
            let previousPosition = videoDevice.position
            let position = videoDevice.position == .back ? AVCaptureDevice.Position.front : .back
            let defaultZoomFactor: CGFloat = 1

            allowsHitTesting = false

            do {
                try await videoDevice.setTorchMode(.off)
                try await videoDevice.setPosition(position)

                let resolutions = position == .back ? configuration.backResolutions : configuration.frontResolutions

                isTorchAvailable = videoDevice.isTorchAvailable || videoDevice.isFlashAvailable

                presets = resolutions.map(\.preset)
                selectedPreset = defaultPreset

                if !isTorchAvailable, isTorchEnabled {
                    switchTorch()
                }

                zoomFactors = videoDevice.displayVideoZoomFactors.sorted()
                lastZoomFactor = defaultZoomFactor
                zoomFactor = defaultZoomFactor

                try await videoDevice.setZoomFactor(defaultZoomFactor, rate: 0)

                monitor.cameraDidChangePosition(from: previousPosition, to: position, context: makeContextSnapshot())
                Task.delayed(milliseconds: 600) { allowsHitTesting = true }
            } catch {
                allowsHitTesting = true

                monitor.cameraDidFailToChangePosition(to: position, error: error, context: makeContextSnapshot())
                didReceiveError(error.localizedDescription)
            }
        }
    }

    /// Toggles the camera's torch on or off with error handling.
    ///
    /// This function switches the torch state between enabled and disabled modes.
    /// It optimistically updates the UI state first, then attempts to change the
    /// actual torch mode. If the torch operation fails, it reverts the UI state
    /// to maintain consistency between the visual state and the actual hardware state.
    func switchTorch() {
        Task { @DeviceActor in
            await MainActor.run { isTorchEnabled.toggle() }

            guard videoDevice.isTorchAvailable || videoDevice.isFlashAvailable else {
                let error = UtilityError(kind: .unknown, failureReason: "Torch is not available on this device")

                try videoDevice.setTorchMode(.off)
                videoDevice.flashMode = .off

                monitor.cameraDidFailToChangeTorch(error: error, context: makeContextSnapshot())
                await didReceiveError(Localizations.torchNotAvailable)

                return
            }

            let torchMode = isTorchEnabled ? AVCaptureDevice.TorchMode.on : .off

            do {
                try videoDevice.setTorchMode(torchMode)

                if videoDevice.isFlashAvailable {
                    videoDevice.flashMode = isTorchEnabled ? .on : .off
                }

                monitor.cameraDidChangeTorch(context: makeContextSnapshot())
            } catch {
                monitor.cameraDidFailToChangeTorch(error: error, context: makeContextSnapshot())
                await MainActor.run {
                    isTorchEnabled.toggle()
                    didReceiveError(error.localizedDescription)
                }
            }
        }
    }
}

extension FileType {
    /// Creates a `FileType` instance from a `FileFormat` value.
    ///
    /// This initializer converts a `FileFormat` (used for photo capture configuration) to a
    /// `FileType` (used for media upload and storage). The conversion maps photo formats
    /// to their corresponding file type representations.
    ///
    /// ## Format Mapping
    ///
    /// - **`.png`**: Maps directly to `FileType.png` for PNG image files
    /// - **`.jpeg`**: Maps to `FileType.jpg` (JPEG format is represented as JPG)
    /// - **`.heic`**: Maps to `FileType.jpg` (HEIC format is converted to JPG for compatibility)
    ///
    /// ## Usage
    ///
    /// This initializer is used when creating streams for media upload, where the stream
    /// needs a `FileType` but the configuration provides a `FileFormat`. It ensures that
    /// photo formats are correctly represented in the upload system.
    ///
    /// ```swift
    /// let fileFormat: FileFormat = .jpeg
    /// let fileType = FileType(fileFormat: fileFormat) // Returns .jpg
    /// ```
    ///
    /// - Parameter fileFormat: The `FileFormat` value to convert to a `FileType`.
    fileprivate init(fileFormat: FileFormat) {
        self = switch fileFormat {
        case .png:
            .png

        default:
            .jpg
        }
    }
}
