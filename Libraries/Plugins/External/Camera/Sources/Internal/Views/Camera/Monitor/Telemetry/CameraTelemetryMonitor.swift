//
// Copyright © 2026 TruVideo. All rights reserved.
//

import AVFoundation
internal import DI
internal import Telemetry
internal import TruVideoFoundation
import UIKit

/// A camera monitor that captures telemetry for camera lifecycle, UI interactions,
/// recording events, and permission flows.
///
/// `CameraTelemetryMonitor` translates camera callbacks into telemetry signals
/// such as breadcrumbs and error events. It is intended to provide lightweight,
/// structured observability without altering camera behavior.
struct CameraTelemetryMonitor: CameraMonitor {
    // MARK: - Dependencies

    @Dependency(\.telemetryManager)
    private var telemetryManager: TelemetryManager

    // MARK: - CameraMonitor

    /// Called when a photo has been successfully captured.
    ///
    /// This callback indicates that the photo capture operation completed
    /// successfully and that a finalized photo object is available for
    /// further processing, persistence, or upload.
    ///
    /// - Parameters:
    ///   - photo: The finalized photo produced by the capture operation.
    ///   - context: A snapshot of the camera state at the time the photo
    ///     was captured.
    func cameraDidCapturePhoto(_ photo: Photo, context: CameraContext) {
        let flashMode = context.isTorchEnabled ? AVCaptureDevice.FlashMode.on : .off
        let metadata: Metadata = [
            "devicePosition": .int(context.videoPosition.rawValue),
            "flashMode": .int(flashMode.rawValue),
            "resolution": .string(context.selectedPreset.rawValue)
        ]

        telemetryManager.captureBreadcrumb(
            "Photo captured successfully",
            severity: .info,
            category: .photoCapture,
            metadata: metadata
        )
    }

    /// Called when the camera continues its workflow and produces additional media.
    ///
    /// This callback indicates that the camera has resumed or progressed
    /// after a non-terminal interruption and that one or more media items
    /// have been generated as part of that continuation.
    ///
    /// - Parameters:
    ///   - medias: The media items produced as the camera continues its
    ///     capture or recording workflow. These may include photos or
    ///     video clips depending on the active capture mode.
    ///   - context: A snapshot of the camera state at the time the media
    ///     was produced.
    func cameraDidContinue(medias: [Media], context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraLifecycle,
            message: "Camera operation completed",
            metadata: [
                "clipCount": .int(context.clipCount),
                "photoCount": .int(context.photoCount)
            ]
        )
    }

    /// Called when the camera interface is dismissed.
    ///
    /// This callback indicates that the camera session or UI has been closed,
    /// either as a result of user action (such as tapping a close or cancel
    /// control) or programmatic dismissal by the host application.
    ///
    /// The dismissal does not imply success or failure of a capture operation.
    /// Implementations can use this event to perform cleanup, persist state,
    /// or emit telemetry related to session termination.
    ///
    /// - Parameters:
    ///    - medias: The media items to be discarded.
    ///    - context: A snapshot of the camera state at the moment the
    ///   camera was dismissed.
    func cameraDidDismiss(medias: [Media], context: CameraContext) {
        if !medias.isEmpty {
            telemetryManager.captureBreadcrumb(
                severity: .warning,
                category: .cameraLifecycle,
                message: "Camera dismissed with unsaved media",
                metadata: [
                    "clipCount": .int(context.clipCount),
                    "photoCount": .int(context.photoCount)
                ]
            )
        }
    }

    /// Called when the camera focus point changes.
    ///
    /// - Parameters:
    ///   - point: The new focus point, expressed in normalized device coordinates.
    ///   - context: A snapshot of the camera state after the focus update.
    func cameraDidChangeFocusPoint(to point: CGPoint, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Focus changed",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "focusPoint": .string("(\(point.x), \(point.y))")
            ]
        )
    }

    /// Called when the active camera position changes.
    ///
    /// - Parameters:
    ///   - oldPosition: The previous physical camera position.
    ///   - newPosition: The new active camera position.
    ///   - context: A snapshot of the camera state after the position change.
    func cameraDidChangePosition(
        from oldPosition: AVCaptureDevice.Position,
        to newPosition: AVCaptureDevice.Position,
        context: CameraContext
    ) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Camera switched",
            metadata: [
                "previousDevicePosition": .int(oldPosition.rawValue),
                "newDevicePosition": .int(newPosition.rawValue)
            ]
        )
    }

    /// Called when the capture session preset changes.
    ///
    /// This event reflects changes in capture quality, resolution,
    /// or performance characteristics.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangePreset(context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Camera did change capture preset",
            metadata: [
                "preset": .string(context.selectedPreset.rawValue)
            ]
        )
    }

    /// Called when the camera capture route changes.
    ///
    /// This callback indicates that the underlying capture route has changed,
    /// such as a transition between different audio or video input/output
    /// configurations. Route changes may occur due to system interruptions,
    /// hardware connections, or configuration updates.
    ///
    /// - Parameters:
    ///   - reason: An integer value describing the reason for the route change.
    ///   - context: A snapshot of the camera state at the time the route
    ///     change occurred.
    func cameraDidChangeRoute(reason: UInt, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraSystem,
            message: "Audio route changed",
            metadata: [
                "reason": .int(Int(reason)),
                "state": .string("\(context.state)")
            ]
        )
    }

    /// Called when the torch state changes.
    ///
    /// This event indicates that the torch has been enabled or disabled.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangeTorch(context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Torch toggled",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "isTorchEnabled": .bool(context.isTorchEnabled)
            ]
        )
    }

    /// Called when camera initialization fails.
    ///
    /// This callback indicates that the camera was unable to complete its
    /// initialization process and is not ready to perform capture
    /// operations.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the camera from initializing.
    ///   - context: A snapshot of the camera state at the time the
    ///     initialization failure occurred.
    func cameraDidFailToInitialize(error: Error, context: CameraContext) {
        telemetryManager.captureError(
            error,
            name: .cameraInitializationFailed,
            metadata: [
                "audioAuthorizationStatus": .int(AVCaptureDevice.authorizationStatus(for: .audio).rawValue),
                "videoAuthorizationStatus": .int(AVCaptureDevice.authorizationStatus(for: .video).rawValue)
            ]
        )
    }

    /// Called when the camera zoom factor changes.
    ///
    /// This callback indicates that the camera has applied a new zoom level,
    /// either in response to a user interaction or a programmatic update.
    ///
    /// - Parameters:
    ///   - zoomFactor: The updated zoom factor applied to the active camera.
    ///     A value of `1.0` represents no zoom. Values greater than `1.0`
    ///     indicate optical or digital zoom depending on device capabilities.
    ///   - context: A snapshot of the camera state after the zoom change
    ///     was applied.
    func cameraDidChangeZoom(_ zoomFactor: CGFloat, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Zoom changed",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "zoomFactor": .double(zoomFactor)
            ]
        )
    }

    /// Called when a photo capture operation fails.
    ///
    /// This callback indicates that the photo capture lifecycle could not
    /// be completed and no usable photo was produced.
    ///
    /// - Parameters:
    ///   - error: The error that caused the capture to fail.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToCapturePhoto(error: Error, context: CameraContext) {
        let flashMode = context.isTorchEnabled ? AVCaptureDevice.FlashMode.on : .off

        telemetryManager.captureError(
            error,
            name: .photoCaptureFailed,
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "flashMode": .int(flashMode.rawValue),
                "resolution": .string(context.selectedPreset.rawValue)
            ]
        )
    }

    /// Called when changing the camera position fails.
    ///
    /// - Parameters:
    ///   - newPosition: The intended target camera position.
    ///   - error: The error that prevented the position change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangePosition(to newPosition: AVCaptureDevice.Position, error: Error, context: CameraContext) {
        telemetryManager.captureError(
            error,
            name: .cameraSwitchFailed,
            metadata: [
                "previousDevicePosition": .int(context.videoPosition.rawValue),
                "newDevicePosition": .int(newPosition.rawValue)
            ]
        )
    }

    /// Called when changing the capture session preset fails.
    ///
    /// This callback indicates that an attempt to switch the camera to the
    /// specified capture session preset did not succeed and the preset
    /// remains unchanged.
    ///
    /// - Parameters:
    ///   - preset: The capture session preset that was requested but could
    ///     not be applied.
    ///   - error: The error that prevented the preset change.
    ///   - context: A snapshot of the camera state at the time the preset change failed.
    func cameraDidFailToChangePreset(_ preset: AVCaptureSession.Preset, error: Error, context: CameraContext) {
        telemetryManager.captureError(
            error,
            name: .presetChangeFailed,
            metadata: [
                "newPreset": .string(preset.rawValue),
                "preset": .string(context.selectedPreset.rawValue)
            ]
        )
    }

    /// Called when a camera route change attempt fails.
    ///
    /// This callback indicates that the camera was unable to complete a requested
    /// route change, such as switching audio or video input/output paths. Failures
    /// may occur due to unsupported configurations, hardware limitations, or
    /// system-level interruptions.
    ///
    /// Implementations typically use this event to capture diagnostics and error
    /// telemetry related to routing and connectivity issues.
    ///
    /// - Parameter error: The error that prevented the camera route from changing
    ///   successfully.
    func cameraDidFailToChangeRoute(error: Error) {
        telemetryManager.captureError(error, name: .audioRouteChangeFailed)
    }

    /// Called when the camera capture route changes.
    ///
    /// This callback indicates that the underlying capture route has changed,
    /// such as a transition between different audio or video input/output
    /// configurations. Route changes may occur due to system interruptions,
    /// hardware connections, or configuration updates.
    ///
    /// - Parameters:
    ///   - reason: An integer value describing the reason for the route change.
    ///   - context: A snapshot of the camera state at the time the route
    ///     change occurred.
    func cameraDidChangeRoute(reason: Int, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraSystem,
            message: "Audio route changed",
            metadata: [
                "reason": .int(Int(reason)),
                "state": .string("\(context.state)")
            ]
        )
    }

    /// Called when changing the torch state fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the torch state change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangeTorch(error: Error, context: CameraContext) {
        telemetryManager.captureError(
            error,
            name: .torchNotAvailable,
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue)
            ]
        )
    }

    /// Called when changing the camera zoom factor fails.
    ///
    /// This callback indicates that an attempt to update the camera’s zoom
    /// level did not succeed and the active zoom factor remains unchanged.
    ///
    /// Implementations typically use this event to capture diagnostics and
    /// error telemetry for troubleshooting zoom-related failures.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the zoom change from being applied.
    ///   - context: A snapshot of the camera state at the time the zoom change
    ///     failed.
    func cameraDidFailToChangeZoom(error: Error, context: CameraContext) {
        telemetryManager.captureError(error, name: .zoomChangeFailed)
    }

    /// Called when the camera encounters a runtime error during operation.
    ///
    /// This callback indicates that an unrecoverable or unexpected error occurred
    /// while the camera was active, such as a capture session failure, media
    /// pipeline disruption, or underlying AVFoundation error.
    ///
    /// Implementations typically use this event to capture diagnostics and error
    /// telemetry, assess whether recovery actions are required, and monitor overall
    /// camera stability.
    ///
    /// - Parameters:
    ///   - error: The runtime error encountered by the camera.
    ///   - context: A snapshot of the camera state at the time the error occurred.
    func cameraDidReceiveRuntimeError(_ error: Error, context: CameraContext) {
        telemetryManager.captureError(error, name: .cameraRuntimeError)
    }

    /// Called when the camera capture session is interrupted.
    ///
    /// This callback indicates that the active capture session was temporarily
    /// interrupted due to an external or system-driven reason, such as an incoming
    /// phone call, another app taking control of the camera, audio route changes,
    /// or the app transitioning to the background.
    ///
    /// Implementations typically use this event to pause ongoing capture or
    /// recording workflows, update UI state, and capture telemetry for interruption
    /// analysis.
    ///
    /// - Parameters:
    ///   - reason: An integer representing the interruption reason as provided by
    ///     the underlying capture session or system.
    ///   - context: A snapshot of the camera state at the time the interruption
    ///     occurred.
    func cameraDidReceiveSessionInterruption(reason: Int, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraSystem,
            message: "Camera session interrupted",
            metadata: [
                "reason": .int(reason),
                "state": .string("\(context.state)")
            ]
        )
    }

    /// Called when the camera fails to recover after a service reset.
    ///
    /// This callback indicates that recovery logic was attempted after a
    /// service interruption or reset, but the camera could not return to a
    /// usable state.
    ///
    /// Implementations typically use this event to capture diagnostics and
    /// error telemetry for troubleshooting and stability monitoring.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the camera from recovering.
    ///   - context: A snapshot of the camera state at the time the recovery
    ///     failure occurred.
    func cameraDidFailToRecoverFromServiceReset(error: Error, context: CameraContext) {
        telemetryManager.captureError(error, name: .cameraFailedToRecoverFromReset)
    }

    /// Called when resuming a paused recording fails.
    ///
    /// This callback indicates that an attempt to resume an existing
    /// recording session did not succeed and the recording remains paused
    /// or stopped.
    ///
    /// Implementations typically use this event to capture diagnostics and
    /// error telemetry related to recording lifecycle failures.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the recording from resuming.
    ///   - context: A snapshot of the camera state at the time the resume
    ///     attempt failed.
    func cameraDidFailToResumeRecording(error: Error, context: CameraContext) {
        telemetryManager.captureError(error, name: .cameraFailedToResumeRecording)
    }

    /// Called when setting the camera focus point fails.
    ///
    /// This callback indicates that an attempt to update the camera’s
    /// focus point did not succeed.
    ///
    /// - Parameters:
    ///   - point: The focus point that was requested but could not be applied,
    ///     expressed in normalized device coordinates.
    ///   - error: The error that prevented the focus update.
    ///   - context: A snapshot of the camera state at the time the failure
    ///     occurred.
    func cameraDidFailToSetFocusPoint(_ point: CGPoint, error: Error, context: CameraContext) {
        telemetryManager.captureError(
            error,
            name: .focusChangeFailed,
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "focusPoint": .string("(\(point.x), \(point.y))")
            ]
        )
    }

    /// Called when pausing an active recording fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the recording from being paused.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToPauseRecording(error: Error, context: CameraContext) {
        telemetryManager.captureError(error, name: .pauseRecordingFailed)
    }

    /// Called when setting the capture session preset fails.
    ///
    /// This callback indicates that an attempt to apply the specified
    /// capture preset did not succeed.
    ///
    /// - Parameters:
    ///   - preset: The capture session preset that was requested but
    ///     could not be applied.
    ///   - error: The error that prevented the preset from being set.
    ///   - context: A snapshot of the camera state at the time the
    ///     failure occurred.
    func cameraDidFailToSetPreset(_ preset: AVCaptureSession.Preset, error: Error, context: CameraContext) {
        telemetryManager.captureError(
            error,
            name: .presetChangeFailed,
            metadata: [
                "preset": .string(preset.rawValue)
            ]
        )
    }

    /// Called when starting a recording fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented recording from starting.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToStartRecording(error: Error, context: CameraContext) {
        telemetryManager.captureError(
            error,
            name: .videoRecordingFailed,
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "resolution": .string(context.selectedPreset.rawValue),
                "isAudioAvailable": .bool(AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint)
            ]
        )
    }

    /// Called when a recording finishes successfully.
    ///
    /// - Parameters:
    ///    - clip: The finalized video clip produced by the recording session.
    ///    -  context: A snapshot of the camera state at the time of failure.
    func cameraDidFinishRecording(clip: VideoClip, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .videoRecording,
            message: "Video recording stopped",
            metadata: [
                "clipCount": .int(context.clipCount),
                "devicePosition": .int(context.deviceOrientation.rawValue),
                "duration": .double(clip.duration),
                "preset": .string(context.selectedPreset.rawValue)
            ]
        )
    }

    /// Called when the camera finishes initialization.
    ///
    /// This callback indicates that the camera has been successfully
    /// initialized and is ready to perform capture operations using the
    /// provided configuration.
    ///
    /// - Parameters:
    ///   - configuration: The camera configuration that was applied during
    ///     initialization and will govern capture behavior.
    ///   - context: A snapshot of the camera state at the time initialization
    ///     completed.
    func cameraDidInitialize(configuration: TruvideoSdkCameraConfiguration, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraLifecycle,
            message: "Camera initialized successfully",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "isTorchAvailable": .bool(context.isTorchAvailable),
                "resolution": .string(context.selectedPreset.rawValue)
            ].merging(configuration.metadata, uniquingKeysWith: { lhs, _ in lhs })
        )
    }

    /// Called when a zoom magnification interaction completes.
    ///
    /// This event typically corresponds to the end of a user-driven
    /// zoom interaction.
    ///
    /// - Parameters:
    ///   - value: The zoom delta that will be applied. Positive values
    ///     increase the zoom factor, while negative values decrease it.
    ///   - newZoomFactor: The updated zoom factor applied to the active camera.
    ///   - context: A snapshot of the camera state immediately before the
    ///     zoom change is applied.
    func cameraDidMagnifyZoom(by value: CGFloat, newZoomFactor: CGFloat, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Zoom magnification ended",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "magnificationValue": .double(value),
                "newZoomFactor": .double(newZoomFactor)
            ]
        )
    }

    /// Called when the user opens the system settings from the camera experience.
    ///
    /// This callback indicates that the camera flow has triggered navigation
    /// to the system Settings app, typically as a result of a permission denial
    /// or a user action to manually update camera or microphone authorization.
    ///
    /// Implementations commonly use this event to track permission recovery
    /// flows, user intent, or to annotate telemetry timelines when the user
    /// leaves the camera experience.
    ///
    /// - Parameter context: A snapshot of the camera state at the time the
    ///   system settings were opened.
    func cameraDidOpenSettings(context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "System settings opened from camera"
        )
    }

    /// Called when an active recording is paused successfully.
    ///
    /// This callback indicates that the recording session has been paused
    /// and provides the elapsed recording time at which the pause occurred.
    ///
    /// - Parameters:
    ///   - pauseTime: The elapsed recording time, in seconds, at which the
    ///     recording was paused. This value represents the total recorded
    ///     duration excluding paused intervals.
    ///   - context: A snapshot of the camera state at the time the recording
    ///     was paused.
    func cameraDidPauseRecording(pauseTime: TimeInterval, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .videoRecording,
            message: "Video recording paused",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "pauseTime": .double(pauseTime),
                "clipCount": .int(context.clipCount)
            ]
        )
    }

    /// Called when the active recording reaches the maximum allowed clip duration.
    ///
    /// This callback indicates that the recording has reached the configured
    /// maximum duration limit and can no longer continue capturing additional
    /// media for the current clip. Implementations typically use this event to
    /// stop recording, update UI state, or notify the user that the time limit
    /// has been reached.
    ///
    /// - Parameters:
    ///   - duration: The elapsed recording time, in seconds, at which the
    ///     maximum clip duration was reached.
    ///   - context: A snapshot of the camera state at the time the duration
    ///     limit was reached.
    func cameraDidReachMaxClipDuration(_ duration: TimeInterval, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .warning,
            category: .videoRecording,
            message: "Recording force-ended at elapsed time",
            metadata: [
                "duration": .double(duration)
            ]
        )
    }

    /// Called when the camera successfully recovers after a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidRecoverFromServiceReset(context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraSystem,
            message: "Camera recovered from reset"
        )
    }

    /// Called when the camera services are reset.
    ///
    /// This event indicates that underlying capture services were restarted
    /// due to an interruption or failure.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidResetServices(context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraSystem,
            message: "Camera services were reset",
            metadata: [
                "state": .string("\(context.state)")
            ]
        )
    }

    /// Called when a permission request is resolved.
    ///
    /// - Parameters:
    ///   - mediaType: The media type for which permission was requested.
    ///   - granted: A Boolean value indicating whether permission was granted.
    ///   - context: A snapshot of the camera state at the time the request
    ///     was resolved.
    func cameraDidResolvePermission(for mediaType: AVMediaType, granted: Bool, context: CameraContext) {
        guard granted else {
            let error = UtilityError(
                kind: ErrorReason(rawValue: "DEVICE_NOT_AUTHORIZED"),
                failureReason: "Permission for \(mediaType.rawValue) denied by user"
            )

            telemetryManager.captureError(
                error,
                name: .devicePermissionDenied,
                metadata: [
                    "authorizationStatus": .string("\(AVCaptureDevice.authorizationStatus(for: mediaType))"),
                    "mediaType": .string(mediaType.rawValue)
                ]
            )

            return
        }

        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .authorization,
            message: "Authorization granted",
            metadata: [
                "mediaType": .string(mediaType.rawValue)
            ]
        )
    }

    /// Called when a paused recording resumes successfully.
    ///
    /// This callback indicates that the recording session has resumed from
    /// a previously paused state and continues from the specified elapsed
    /// recording time.
    ///
    /// - Parameters:
    ///   - resumeTime: The elapsed recording time, in seconds, from which
    ///     the recording resumed. This value represents the total recorded
    ///     duration excluding paused intervals.
    ///   - context: A snapshot of the camera state at the time the recording
    ///     was resumed.
    func cameraDidResumeRecording(resumeTime: TimeInterval, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .videoRecording,
            message: "Video recording resumed",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "clipCount": .int(context.clipCount),
                "resumeTime": .double(resumeTime)
            ]
        )
    }

    /// Called when video recording starts successfully.
    ///
    /// This callback indicates that the camera has entered an active recording
    /// state using the provided configuration. At this point, video capture
    /// is in progress and media data is being written according to the
    /// selected recording mode and constraints.
    ///
    /// Implementations commonly use this event to update UI state, start
    /// timers, or emit telemetry related to the beginning of a recording
    /// session.
    ///
    /// - Parameters:
    ///   - configuration: The camera configuration applied at the moment recording started.
    ///   - context: A snapshot of the camera state at the time recording started.
    func cameraDidStartRecording(configuration: TruvideoSdkCameraConfiguration, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .videoRecording,
            message: "Video recording started",
            metadata: [
                "aspectRatio": .string("\(context.aspectRatio)"),
                "devicePosition": .int(context.videoPosition.rawValue),
                "isAudioAvailable": .bool(AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint),
                "isTorchAvailable": .bool(context.isTorchAvailable),
                "isTorchEnabled": .bool(context.isTorchEnabled),
                "maxDuration": .double(configuration.mode.maxVideoDuration),
                "resolution": .string(context.selectedPreset.rawValue)
            ]
        )
    }

    /// Called when the device orientation used by the camera is updated.
    ///
    /// This callback indicates that the camera has detected a change in
    /// device orientation and has updated its internal state accordingly.
    /// Orientation updates may affect capture output, preview layout,
    /// and recorded media metadata.
    ///
    /// - Parameters:
    ///   - orientation: The new device orientation applied to the camera.
    ///   - context: A snapshot of the camera state at the time the orientation
    ///     update occurred.
    func cameraDidUpdateOrientation(orientation: UIDeviceOrientation, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Preview orientation updated",
            metadata: [
                "orientation": .string("\(orientation)")
            ]
        )
    }

    /// Called immediately before a photo capture begins.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillCapturePhoto(context: CameraContext) {
        let flashMode = context.isTorchEnabled ? AVCaptureDevice.FlashMode.on : .off
        let metadata: Metadata = [
            "devicePosition": .int(context.videoPosition.rawValue),
            "flashMode": .int(flashMode.rawValue),
            "resolution": .string(context.selectedPreset.rawValue)
        ]

        telemetryManager.captureBreadcrumb(
            "Photo capture started",
            severity: .info,
            category: .photoCapture,
            metadata: metadata
        )
    }

    /// Called immediately before the capture session preset changes.
    ///
    /// This callback indicates that the camera is about to apply the
    /// specified capture session preset, which may affect capture
    /// quality, resolution, and performance characteristics.
    ///
    /// - Parameters:
    ///   - preset: The capture session preset that is about to be applied.
    ///   - context: A snapshot of the camera state immediately before
    ///     the preset change occurs.
    func cameraWillChangePreset(_ preset: AVCaptureSession.Preset, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Camera will change capture preset",
            metadata: [
                "newPreset": .string(preset.rawValue),
                "preset": .string(context.selectedPreset.rawValue)
            ]
        )
    }

    /// Called when a zoom magnification interaction completes.
    ///
    /// This event typically corresponds to the end of a user-driven
    /// zoom interaction.
    ///
    /// - Parameters:
    ///   - value: The zoom delta that will be applied. Positive values
    ///     increase the zoom factor, while negative values decrease it.
    ///   - context: A snapshot of the camera state immediately before the
    ///     zoom change is applied.
    func cameraWillMagnifyZoom(by value: CGFloat, context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraUI,
            message: "Zoom magnification started",
            metadata: [
                "devicePosition": .int(context.videoPosition.rawValue),
                "magnificationValue": .double(value)
            ]
        )
    }

    /// Called immediately before the camera begins initialization.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillInitialize() {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraLifecycle,
            message: "Camera initialization started"
        )
    }

    /// Called immediately before attempting recovery from a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillRecoverFromServiceReset(context: CameraContext) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .cameraSystem,
            message: "Camera recovering from reset"
        )
    }

    /// Called immediately before requesting permission for a media type.
    ///
    /// - Parameter mediaType: The media type for which permission will be requested.
    func cameraWillRequestPermission(for mediaType: AVMediaType) {
        telemetryManager.captureBreadcrumb(
            severity: .info,
            category: .authorization,
            message: "Authorization requested",
            metadata: [
                "mediaType": .string(mediaType.rawValue)
            ]
        )
    }
}

private extension TruvideoSdkCameraConfiguration {
    /// A dictionary of telemetry metadata representing the camera configuration settings.
    ///
    /// This computed property provides a structured collection of all key camera configuration
    /// values in a format suitable for telemetry reporting. It converts configuration settings
    /// into typed metadata values that can be tracked, logged, and analyzed for debugging,
    /// analytics, and user behavior insights.
    ///
    /// - Returns: A dictionary mapping configuration keys to their typed metadata values
    var metadata: [String: MetadataValue] {
        [
            "flashMode": .string(flashMode.rawValue),
            "lensFacing": .string(lensFacing.rawValue),
            "imageFormat": .string(imageFormat.rawValue),
            "isHighResolutionEnabled": .bool(isHighResolutionPhotoEnabled),
            "maxPictureCount": .int(mode.maxPictureCount),
            "maxVideoCount": .int(mode.maxVideoCount),
            "maxMediaCount": .int(mode.maxMediaCount),
            "maxVideoDuration": .double(mode.maxVideoDuration)
        ]
    }
}
