//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import UIKit
internal import Utilities

extension CameraViewModel {
    // MARK: - Configuration

    /// Initializes the camera system by configuring devices and starting the capture session.
    ///
    /// This method performs the initial setup of the camera system, including device
    /// configuration, authorization checks, and capture session startup. The initialization
    /// is performed asynchronously with user-initiated priority to ensure responsive UI
    /// during the setup process.
    ///
    /// ## Telemetry
    ///
    /// Records a `camera_lifecycle` breadcrumb when initialization starts and when it
    /// completes successfully, including device position and available zoom factors.
    func initialize() {
        Task(priority: .userInitiated) { @MainActor in
            do {
                monitor.cameraWillInitialize()

                try await configureDevices()

                orientationDidUpdate(to: deviceOrientation)
                captureSession.beginUpdates()

                if captureSession.canSetSessionPreset(selectedPreset) {
                    captureSession.sessionPreset = selectedPreset
                }

                captureSession.endUpdates()

                Task.detached { [weak self] in
                    guard let self else { return }

                    self.captureSession.startRunning()
                }

                // videoZoomFactor is applied after startRunning() because starting the session
                // reconfigures the capture pipeline and resets any zoom set beforehand.
                try await videoDevice.setZoomFactor(zoomFactor, rate: 0)

                Task.delayed(milliseconds: 1_200) {
                    allowsHitTesting = true
                }

                zoomFactors = videoDevice.displayVideoZoomFactors
                monitor.cameraDidInitialize(configuration: configuration, context: makeContextSnapshot())
            } catch {
                allowsHitTesting = true

                didReceiveError(error.localizedDescription)
                monitor.cameraDidFailToInitialize(error: error, context: makeContextSnapshot())
            }
        }
    }

    // MARK: - Private methods

    @DeviceActor
    private func configureDevices() async throws {
        if audioDevice.authorizationStatus == .notDetermined, videoDevice.authorizationStatus == .notDetermined {
            await requestDeviceAccess()
        }

        guard audioDevice.authorizationStatus == .authorized, videoDevice.authorizationStatus == .authorized else {
            await MainActor.run { isAuthorized = false }
            return
        }

        try videoDevice.configure(in: captureSession)

        if audioDevice.isAvailable {
            try audioDevice.configure(in: captureSession)
        }

        audioDevice.add(movieOutputProcessor)
        videoDevice.add(movieOutputProcessor)

        let position = configuration.lensFacing == .front ? AVCaptureDevice.Position.front : .back
        try videoDevice.setPosition(position)

        isTorchAvailable = videoDevice.isTorchAvailable || videoDevice.isFlashAvailable

        let torchEnabled = configuration.flashMode == .on && isTorchAvailable
        let torchMode = configuration.flashMode == .on ? AVCaptureDevice.TorchMode.on : .off

        videoDevice.configuration.isHighResolutionEnabled = configuration.isHighResolutionPhotoEnabled
        videoDevice.configuration.imageFormat = configuration.imageFormat.value

        if videoDevice.isFlashAvailable {
            videoDevice.flashMode = configuration.flashMode.value
        }

        try videoDevice.setTorchMode(torchMode)

        let presets = position == .back ? configuration.backResolutions : configuration.frontResolutions
        let selectedPreset = defaultPreset

        await MainActor.run {
            self.presets = presets.map(\.preset)
            self.selectedPreset = selectedPreset
            self.isTorchEnabled = torchEnabled
        }
    }

    private func requestDeviceAccess() async {
        monitor.cameraWillRequestPermission(for: .audio)
        await audioDevice.requestAccess()

        monitor.cameraWillRequestPermission(for: .video)
        await videoDevice.requestAccess()

        monitor.cameraDidResolvePermission(
            for: .audio,
            granted: audioDevice.authorizationStatus == .authorized,
            context: makeContextSnapshot()
        )

        monitor.cameraDidResolvePermission(
            for: .video,
            granted: videoDevice.authorizationStatus == .authorized,
            context: makeContextSnapshot()
        )
    }
}
