//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

extension CameraViewModel {
    // MARK: - Instance methods

    /// Configures observers for application lifecycle events and state changes.
    ///
    /// This function sets up notification observers to monitor key application lifecycle
    /// events including when the app becomes active, enters background, and returns to
    /// foreground. These observers enable the camera system to respond appropriately to
    /// app state changes, ensuring proper resource management and user experience.
    func configureObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveDidBecomeActiveNotification(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveDidEnterBackgroundNotification(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveWillEnterForegroundNotification(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// Configures observers for capture session and audio system events.
    ///
    /// This function sets up notification observers to monitor critical capture session
    /// and audio system events that can affect camera functionality. These observers
    /// enable the camera system to handle interruptions, errors, and system-level
    /// changes that may impact recording or capture operations.
    func configureSessionObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMediaServicesWereResetNotification(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveRouteChangeNotification(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveRuntimeErrorNotification(_:)),
            name: AVCaptureSession.runtimeErrorNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveSessionWasInterruptedNotification(_:)),
            name: AVCaptureSession.wasInterruptedNotification,
            object: nil
        )
    }

    // MARK: - Notification methods

    @objc
    func didReceiveDidBecomeActiveNotification(_ notification: Notification) {
        if !captureSession.isRunning {
            Task.detached { [weak self] in
                guard let self else { return }

                self.captureSession.startRunning()
            }
        }
    }

    @MainActor
    @objc
    func didReceiveDidEnterBackgroundNotification(_ notification: Notification) {
        if state == .running {
            pauseSession()
        }
    }

    @objc
    func didReceiveMediaServicesWereResetNotification(_ notification: Notification) {
        monitor.cameraDidResetServices(context: makeContextSnapshot())

        if !captureSession.isRunning {
            Task.detached { [weak self] in
                guard let self else { return }

                self.captureSession.startRunning()
            }
        }

        if state == .running {
            monitor.cameraWillRecoverFromServiceReset(context: makeContextSnapshot())

            Task { @DeviceActor in
                videoDevice.endCapturing(in: captureSession)
                audioDevice.endCapturing(in: captureSession)

                do {
                    try audioDevice.startCapturing()
                    try videoDevice.startCapturing()

                    monitor.cameraDidRecoverFromServiceReset(context: makeContextSnapshot())
                } catch {
                    await didReceiveError(error.localizedDescription)
                    monitor.cameraDidFailToRecoverFromServiceReset(error: error, context: makeContextSnapshot())
                }
            }
        }
    }

    @MainActor
    @objc
    func didReceiveRouteChangeNotification(_ notification: Notification) {
        let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0

        monitor.cameraDidChangeRoute(reason: reason, context: makeContextSnapshot())

        Task { @DeviceActor in
            guard !audioDevice.isAvailable else {
                guard !audioDevice.isReady else { return }

                do {
                    try audioDevice.configure(in: captureSession)
                } catch {
                    await didReceiveError(error.localizedDescription)
                    monitor.cameraDidFailToChangeRoute(error: error)
                }

                return
            }

            audioDevice.endCapturing(in: captureSession)
        }
    }

    @objc
    func didReceiveRuntimeErrorNotification(_ notification: Notification) {
        if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError, state == .running {
            monitor.cameraDidReceiveRuntimeError(error, context: makeContextSnapshot())

            if [.sessionConfigurationChanged, .sessionNotRunning].contains(error.code) {
                if !captureSession.isRunning {
                    Task.detached { [weak self] in
                        guard let self else { return }

                        self.captureSession.startRunning()
                    }
                }
            }
        }
    }

    @MainActor
    @objc
    func didReceiveSessionWasInterruptedNotification(_ notification: Notification) {
        let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int ?? 0

        monitor.cameraDidReceiveSessionInterruption(reason: reason, context: makeContextSnapshot())

        if state == .running {
            pauseSession()
        }
    }

    @objc
    func didReceiveWillEnterForegroundNotification(_ notification: Notification) {
        if !captureSession.isRunning {
            Task.detached { [weak self] in
                guard let self else { return }

                self.captureSession.startRunning()
            }
        }
    }
}
