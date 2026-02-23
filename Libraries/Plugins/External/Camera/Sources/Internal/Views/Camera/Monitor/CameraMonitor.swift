//
// Copyright © 2026 TruVideo. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

/// A value type that describes the current operational context of the camera.
///
/// `CameraContext` provides a snapshot of the camera’s configuration,
/// capabilities, and runtime state at a specific point in time. It is
/// commonly used to supply contextual information to observers, monitors,
/// or telemetry systems without exposing mutable camera internals.
///
/// This type is immutable and `Sendable`, making it safe to pass across
/// concurrency boundaries.
struct CameraContext: Sendable {
    /// The aspect ratio currently used by the capture session.
    ///
    /// This value reflects the relationship between the captured media’s
    /// width and height and may vary depending on the active camera preset
    /// or device configuration.
    let aspectRatio: CGFloat

    /// The number of video clips currently associated with the session.
    ///
    /// This value typically increases as recording segments are created
    /// within the same capture flow.
    let clipCount: Int

    /// The current orientation of the device relative to the user interface.
    ///
    /// This value is used to adapt capture behavior and metadata to match
    /// how the user is holding the device at the time of capture.
    let deviceOrientation: UIDeviceOrientation

    /// Indicates whether the device torch (flashlight) is available.
    ///
    /// This value reflects hardware capability only and does not imply
    /// whether the torch is currently enabled.
    let isTorchAvailable: Bool

    /// Indicates whether the torch is currently enabled.
    let isTorchEnabled: Bool

    /// The number of photos captured during the current session.
    let photoCount: Int

    /// The active capture session preset.
    ///
    /// The preset determines the overall quality and resolution of the
    /// capture output and influences performance characteristics.
    let selectedPreset: AVCaptureSession.Preset

    /// The current recording state of the camera.
    ///
    /// This value represents the high-level lifecycle state of recording
    /// operations, such as idle, recording, or paused.
    let state: RecordingState

    /// The video codec used for video capture and encoding.
    ///
    /// This value affects compression efficiency, compatibility,
    /// and output file characteristics.
    let videoCodec: AVVideoCodecType

    /// The physical position of the active video capture device.
    ///
    /// For example, `.front` or `.back`.
    let videoPosition: AVCaptureDevice.Position
}

/// A protocol that observes and reports camera lifecycle events.
///
/// `CameraMonitor` defines a set of callbacks that are invoked as the camera
/// transitions through its operational lifecycle, including initialization,
/// permission resolution, capture operations, recording state changes, and
/// error conditions.
///
/// This protocol is intended for monitoring, diagnostics, analytics, or
/// telemetry purposes only. Implementations must not attempt to control or
/// mutate camera behavior from these callbacks.
///
/// All callbacks provide a snapshot `CameraContext` representing the camera
/// state at the time the event occurred.
///
/// Conforming types must be `Sendable`, as callbacks may be invoked across
/// concurrency boundaries.
protocol CameraMonitor: Sendable {
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
    func cameraDidCapturePhoto(_ photo: Photo, context: CameraContext)

    /// Called when the camera focus point changes.
    ///
    /// - Parameters:
    ///   - point: The new focus point, expressed in normalized device coordinates.
    ///   - context: A snapshot of the camera state after the focus update.
    func cameraDidChangeFocusPoint(to point: CGPoint, context: CameraContext)

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
    )

    /// Called when the capture session preset changes.
    ///
    /// This event reflects changes in capture quality, resolution,
    /// or performance characteristics.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangePreset(context: CameraContext)

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
    func cameraDidChangeRoute(reason: UInt, context: CameraContext)

    /// Called when the torch state changes.
    ///
    /// This event indicates that the torch has been enabled or disabled.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangeTorch(context: CameraContext)

    /// Called when the camera zoom factor changes.
    ///
    /// This callback indicates that the camera has applied a new zoom level,
    /// either in response to a user interaction or a programmatic update.
    ///
    /// - Parameters:
    ///   - zoomFactor: The updated zoom factor applied to the active camera.
    ///   - context: A snapshot of the camera state after the zoom change
    ///     was applied.
    func cameraDidChangeZoom(_ zoomFactor: CGFloat, context: CameraContext)

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
    func cameraDidContinue(medias: [Media], context: CameraContext)

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
    func cameraDidDismiss(medias: [Media], context: CameraContext)

    /// Called when a photo capture operation fails.
    ///
    /// This callback indicates that the photo capture lifecycle could not
    /// be completed and no usable photo was produced.
    ///
    /// - Parameters:
    ///   - error: The error that caused the capture to fail.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToCapturePhoto(error: Error, context: CameraContext)

    /// Called when changing the camera position fails.
    ///
    /// - Parameters:
    ///   - newPosition: The intended target camera position.
    ///   - error: The error that prevented the position change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangePosition(
        to newPosition: AVCaptureDevice.Position,
        error: Error,
        context: CameraContext
    )

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
    func cameraDidFailToChangePreset(
        _ preset: AVCaptureSession.Preset,
        error: Error,
        context: CameraContext
    )

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
    func cameraDidFailToChangeRoute(error: Error)

    /// Called when changing the torch state fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the torch state change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangeTorch(error: Error, context: CameraContext)

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
    func cameraDidFailToChangeZoom(error: Error, context: CameraContext)

    /// Called when a recording fails to finish successfully.
    ///
    /// This callback indicates that the recording lifecycle was interrupted or
    /// terminated unexpectedly before completion, and the resulting video clip
    /// may be incomplete or unavailable.
    ///
    /// Implementations typically use this event to capture error telemetry,
    /// update UI state, and perform any necessary cleanup or recovery actions
    /// related to the failed recording.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the recording from finishing
    ///     successfully.
    ///   - context: A snapshot of the camera state at the time the failure
    ///     occurred.
    func cameraDidFailToFinishRecording(error: Error, context: CameraContext)

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
    func cameraDidFailToInitialize(error: Error, context: CameraContext)

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
    func cameraDidFailToRecoverFromServiceReset(error: Error, context: CameraContext)

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
    func cameraDidFailToResumeRecording(error: Error, context: CameraContext)

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
    func cameraDidFailToSetFocusPoint(_ point: CGPoint, error: Error, context: CameraContext)

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
    func cameraDidFailToSetPreset(_ preset: AVCaptureSession.Preset, error: Error, context: CameraContext)

    /// Called when starting a recording fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented recording from starting.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToStartRecording(error: Error, context: CameraContext)

    /// Called when a recording finishes successfully.
    ///
    /// - Parameters:
    ///    - clip: The finalized video clip produced by the recording session.
    ///    -  context: A snapshot of the camera state at the time of failure.
    func cameraDidFinishRecording(clip: VideoClip, context: CameraContext)

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
    func cameraDidInitialize(configuration: TruvideoSdkCameraConfiguration, context: CameraContext)

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
    func cameraDidMagnifyZoom(by value: CGFloat, newZoomFactor: CGFloat, context: CameraContext)

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
    func cameraDidOpenSettings(context: CameraContext)

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
    func cameraDidPauseRecording(pauseTime: TimeInterval, context: CameraContext)

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
    func cameraDidReachMaxClipDuration(_ duration: TimeInterval, context: CameraContext)

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
    func cameraDidReceiveRuntimeError(_ error: Error, context: CameraContext)

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
    func cameraDidReceiveSessionInterruption(reason: Int, context: CameraContext)

    /// Called when the camera successfully recovers after a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidRecoverFromServiceReset(context: CameraContext)

    /// Called when the camera services are reset.
    ///
    /// This event indicates that underlying capture services were restarted
    /// due to an interruption or failure.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidResetServices(context: CameraContext)

    /// Called when a permission request is resolved.
    ///
    /// - Parameters:
    ///   - mediaType: The media type for which permission was requested.
    ///   - granted: A Boolean value indicating whether permission was granted.
    ///   - context: A snapshot of the camera state at the time the request
    ///     was resolved.
    func cameraDidResolvePermission(for mediaType: AVMediaType, granted: Bool, context: CameraContext)

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
    func cameraDidResumeRecording(resumeTime: TimeInterval, context: CameraContext)

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
    func cameraDidStartRecording(configuration: TruvideoSdkCameraConfiguration, context: CameraContext)

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
    func cameraDidUpdateOrientation(orientation: UIDeviceOrientation, context: CameraContext)

    /// Called immediately before a photo capture begins.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillCapturePhoto(context: CameraContext)

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
    func cameraWillChangePreset(_ preset: AVCaptureSession.Preset, context: CameraContext)

    /// Called immediately before the camera begins initialization.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillInitialize()

    /// Called immediately before a zoom magnification is applied.
    ///
    /// This callback indicates that the camera is about to adjust its zoom
    /// level by the specified amount. It is typically invoked in response
    /// to a user-driven zoom interaction, such as a pinch gesture.
    ///
    /// - Parameters:
    ///   - value: The zoom delta that will be applied. Positive values
    ///     increase the zoom factor, while negative values decrease it.
    ///   - context: A snapshot of the camera state immediately before the
    ///     zoom change is applied.
    func cameraWillMagnifyZoom(by value: CGFloat, context: CameraContext)

    /// Called immediately before attempting recovery from a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillRecoverFromServiceReset(context: CameraContext)

    /// Called immediately before requesting permission for a media type.
    ///
    /// - Parameter mediaType: The media type for which permission will be requested.
    func cameraWillRequestPermission(for mediaType: AVMediaType)
}

extension CameraMonitor {
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
    func cameraDidCapturePhoto(_ photo: Photo, context: CameraContext) {}

    /// Called when the camera focus point changes.
    ///
    /// - Parameters:
    ///   - point: The new focus point, expressed in normalized device coordinates.
    ///   - context: A snapshot of the camera state after the focus update.
    func cameraDidChangeFocusPoint(to point: CGPoint, context: CameraContext) {}

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
    ) {}

    /// Called when the capture session preset changes.
    ///
    /// This event reflects changes in capture quality, resolution,
    /// or performance characteristics.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangePreset(context: CameraContext) {}

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
    func cameraDidChangeRoute(reason: UInt, context: CameraContext) {}

    /// Called when the torch state changes.
    ///
    /// This event indicates that the torch has been enabled or disabled.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangeTorch(context: CameraContext) {}

    /// Called when the camera zoom factor changes.
    ///
    /// This callback indicates that the camera has applied a new zoom level,
    /// either in response to a user interaction or a programmatic update.
    ///
    /// - Parameters:
    ///   - zoomFactor: The updated zoom factor applied to the active camera.
    ///   - context: A snapshot of the camera state after the zoom change
    ///     was applied.
    func cameraDidChangeZoom(_ zoomFactor: CGFloat, context: CameraContext) {}

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
    func cameraDidContinue(medias: [Media], context: CameraContext) {}

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
    func cameraDidDismiss(medias: [Media], context: CameraContext) {}

    /// Called when a photo capture operation fails.
    ///
    /// This callback indicates that the photo capture lifecycle could not
    /// be completed and no usable photo was produced.
    ///
    /// - Parameters:
    ///   - error: The error that caused the capture to fail.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToCapturePhoto(error: Error, context: CameraContext) {}

    /// Called when changing the camera position fails.
    ///
    /// - Parameters:
    ///   - newPosition: The intended target camera position.
    ///   - error: The error that prevented the position change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangePosition(
        to newPosition: AVCaptureDevice.Position,
        error: Error,
        context: CameraContext
    ) {}

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
    func cameraDidFailToChangePreset(
        _ preset: AVCaptureSession.Preset,
        error: Error,
        context: CameraContext
    ) {}

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
    func cameraDidFailToChangeRoute(error: Error) {}

    /// Called when changing the torch state fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the torch state change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangeTorch(error: Error, context: CameraContext) {}

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
    func cameraDidFailToChangeZoom(error: Error, context: CameraContext) {}

    /// Called when a recording fails to finish successfully.
    ///
    /// This callback indicates that the recording lifecycle was interrupted or
    /// terminated unexpectedly before completion, and the resulting video clip
    /// may be incomplete or unavailable.
    ///
    /// Implementations typically use this event to capture error telemetry,
    /// update UI state, and perform any necessary cleanup or recovery actions
    /// related to the failed recording.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the recording from finishing
    ///     successfully.
    ///   - context: A snapshot of the camera state at the time the failure
    ///     occurred.
    func cameraDidFailToFinishRecording(error: Error, context: CameraContext) {}

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
    func cameraDidFailToInitialize(error: Error, context: CameraContext) {}

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
    func cameraDidFailToRecoverFromServiceReset(error: Error, context: CameraContext) {}

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
    func cameraDidFailToResumeRecording(error: Error, context: CameraContext) {}

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
    func cameraDidFailToSetFocusPoint(_ point: CGPoint, error: Error, context: CameraContext) {}

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
    func cameraDidFailToSetPreset(_ preset: AVCaptureSession.Preset, error: Error, context: CameraContext) {}

    /// Called when starting a recording fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented recording from starting.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToStartRecording(error: Error, context: CameraContext) {}

    /// Called when a recording finishes successfully.
    ///
    /// - Parameters:
    ///    - clip: The finalized video clip produced by the recording session.
    ///    -  context: A snapshot of the camera state at the time of failure.
    func cameraDidFinishRecording(clip: VideoClip, context: CameraContext) {}

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
    func cameraDidInitialize(configuration: TruvideoSdkCameraConfiguration, context: CameraContext) {}

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
    func cameraDidMagnifyZoom(by value: CGFloat, newZoomFactor: CGFloat, context: CameraContext) {}

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
    func cameraDidOpenSettings(context: CameraContext) {}

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
    func cameraDidPauseRecording(pauseTime: TimeInterval, context: CameraContext) {}

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
    func cameraDidReachMaxClipDuration(_ duration: TimeInterval, context: CameraContext) {}

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
    func cameraDidReceiveRuntimeError(_ error: Error, context: CameraContext) {}

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
    func cameraDidReceiveSessionInterruption(reason: Int, context: CameraContext) {}

    /// Called when the camera successfully recovers after a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidRecoverFromServiceReset(context: CameraContext) {}

    /// Called when the camera services are reset.
    ///
    /// This event indicates that underlying capture services were restarted
    /// due to an interruption or failure.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidResetServices(context: CameraContext) {}

    /// Called when a permission request is resolved.
    ///
    /// - Parameters:
    ///   - mediaType: The media type for which permission was requested.
    ///   - granted: A Boolean value indicating whether permission was granted.
    ///   - context: A snapshot of the camera state at the time the request
    ///     was resolved.
    func cameraDidResolvePermission(for mediaType: AVMediaType, granted: Bool, context: CameraContext) {}

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
    func cameraDidResumeRecording(resumeTime: TimeInterval, context: CameraContext) {}

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
    func cameraDidStartRecording(configuration: TruvideoSdkCameraConfiguration, context: CameraContext) {}

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
    func cameraDidUpdateOrientation(orientation: UIDeviceOrientation, context: CameraContext) {}

    /// Called immediately before a photo capture begins.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillCapturePhoto(context: CameraContext) {}

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
    func cameraWillChangePreset(_ preset: AVCaptureSession.Preset, context: CameraContext) {}

    /// Called immediately before the camera begins initialization.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillInitialize() {}

    /// Called immediately before a zoom magnification is applied.
    ///
    /// This callback indicates that the camera is about to adjust its zoom
    /// level by the specified amount. It is typically invoked in response
    /// to a user-driven zoom interaction, such as a pinch gesture.
    ///
    /// - Parameters:
    ///   - value: The zoom delta that will be applied. Positive values
    ///     increase the zoom factor, while negative values decrease it.
    ///   - context: A snapshot of the camera state immediately before the
    ///     zoom change is applied.
    func cameraWillMagnifyZoom(by value: CGFloat, context: CameraContext) {}

    /// Called immediately before attempting recovery from a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillRecoverFromServiceReset(context: CameraContext) {}

    /// Called immediately before requesting permission for a media type.
    ///
    /// - Parameter mediaType: The media type for which permission will be requested.
    func cameraWillRequestPermission(for mediaType: AVMediaType) {}
}

/// A `CameraMonitor` implementation that forwards camera events to multiple monitors.
///
/// `MultiplexCameraMonitor` acts as a fan-out dispatcher, allowing multiple
/// `CameraMonitor` instances to observe the same camera lifecycle events.
/// This is useful for composing independent concerns such as logging,
/// analytics, debugging, and telemetry without coupling them together.
///
/// All events received by the multiplexer are forwarded to each registered
/// monitor in the order they were provided during initialization.
///
/// Event delivery is serialized on the main dispatch queue to ensure
/// predictable ordering and thread-safety when interacting with UI-bound
/// or main-thread–constrained observers.
struct MultiplexCameraMonitor: CameraMonitor {
    // MARK: - Private Properties

    private let monitors: [CameraMonitor]
    private let queue = DispatchQueue.main

    // MARK: - Initializer

    /// Creates a new multiplexer that forwards events to the provided monitors.
    ///
    /// - Parameter monitors: The monitors that should receive camera events.
    ///   Events are delivered in the same order as this array.
    init(monitors: [CameraMonitor]) {
        self.monitors = monitors
    }

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
        queue.async {
            monitors.forEach { $0.cameraDidCapturePhoto(photo, context: context) }
        }
    }

    /// Called when the camera focus point changes.
    ///
    /// - Parameters:
    ///   - point: The new focus point, expressed in normalized device coordinates.
    ///   - context: A snapshot of the camera state after the focus update.
    func cameraDidChangeFocusPoint(to point: CGPoint, context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidChangeFocusPoint(to: point, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidChangePosition(from: oldPosition, to: newPosition, context: context) }
        }
    }

    /// Called when the capture session preset changes.
    ///
    /// This event reflects changes in capture quality, resolution,
    /// or performance characteristics.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangePreset(context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidChangePreset(context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidChangeRoute(reason: reason, context: context) }
        }
    }

    /// Called when the torch state changes.
    ///
    /// This event indicates that the torch has been enabled or disabled.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangeTorch(context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidChangeTorch(context: context) }
        }
    }

    /// Called when the camera zoom factor changes.
    ///
    /// This callback indicates that the camera has applied a new zoom level,
    /// either in response to a user interaction or a programmatic update.
    ///
    /// - Parameters:
    ///   - zoomFactor: The updated zoom factor applied to the active camera.
    ///   - context: A snapshot of the camera state after the zoom change
    ///     was applied.
    func cameraDidChangeZoom(_ zoomFactor: CGFloat, context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidChangeZoom(zoomFactor, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidContinue(medias: medias, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidDismiss(medias: medias, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToCapturePhoto(error: error, context: context) }
        }
    }

    /// Called when changing the camera position fails.
    ///
    /// - Parameters:
    ///   - newPosition: The intended target camera position.
    ///   - error: The error that prevented the position change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangePosition(
        to newPosition: AVCaptureDevice.Position,
        error: Error,
        context: CameraContext
    ) {
        queue.async {
            monitors.forEach { $0.cameraDidFailToChangePosition(to: newPosition, error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToChangePreset(preset, error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToChangeRoute(error: error) }
        }
    }

    /// Called when changing the torch state fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the torch state change.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToChangeTorch(error: Error, context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidFailToChangeTorch(error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToChangeZoom(error: error, context: context) }
        }
    }

    /// Called when a recording fails to finish successfully.
    ///
    /// This callback indicates that the recording lifecycle was interrupted or
    /// terminated unexpectedly before completion, and the resulting video clip
    /// may be incomplete or unavailable.
    ///
    /// Implementations typically use this event to capture error telemetry,
    /// update UI state, and perform any necessary cleanup or recovery actions
    /// related to the failed recording.
    ///
    /// - Parameters:
    ///   - error: The error that prevented the recording from finishing
    ///     successfully.
    ///   - context: A snapshot of the camera state at the time the failure
    ///     occurred.
    func cameraDidFailToFinishRecording(error: Error, context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidFailToFinishRecording(error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToInitialize(error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToRecoverFromServiceReset(error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToResumeRecording(error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToSetFocusPoint(point, error: error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidFailToSetPreset(preset, error: error, context: context) }
        }
    }

    /// Called when starting a recording fails.
    ///
    /// - Parameters:
    ///   - error: The error that prevented recording from starting.
    ///   - context: A snapshot of the camera state at the time of failure.
    func cameraDidFailToStartRecording(error: Error, context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidFailToStartRecording(error: error, context: context) }
        }
    }

    /// Called when a recording finishes successfully.
    ///
    /// - Parameters:
    ///    - clip: The finalized video clip produced by the recording session.
    ///    -  context: A snapshot of the camera state at the time of failure.
    func cameraDidFinishRecording(clip: VideoClip, context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidFinishRecording(clip: clip, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidInitialize(configuration: configuration, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidMagnifyZoom(by: value, newZoomFactor: newZoomFactor, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidOpenSettings(context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidPauseRecording(pauseTime: pauseTime, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidReachMaxClipDuration(duration, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidReceiveRuntimeError(error, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidReceiveSessionInterruption(reason: reason, context: context) }
        }
    }

    /// Called when the camera successfully recovers after a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidRecoverFromServiceReset(context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidRecoverFromServiceReset(context: context) }
        }
    }

    /// Called when the camera services are reset.
    ///
    /// This event indicates that underlying capture services were restarted
    /// due to an interruption or failure.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidResetServices(context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidResetServices(context: context) }
        }
    }

    /// Called when a permission request is resolved.
    ///
    /// - Parameters:
    ///   - mediaType: The media type for which permission was requested.
    ///   - granted: A Boolean value indicating whether permission was granted.
    ///   - context: A snapshot of the camera state at the time the request
    ///     was resolved.
    func cameraDidResolvePermission(for mediaType: AVMediaType, granted: Bool, context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraDidResolvePermission(for: mediaType, granted: granted, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidResumeRecording(resumeTime: resumeTime, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidStartRecording(configuration: configuration, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraDidUpdateOrientation(orientation: orientation, context: context) }
        }
    }

    /// Called immediately before a photo capture begins.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillCapturePhoto(context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraWillCapturePhoto(context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraWillChangePreset(preset, context: context) }
        }
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
        queue.async {
            monitors.forEach { $0.cameraWillMagnifyZoom(by: value, context: context) }
        }
    }

    /// Called immediately before the camera begins initialization.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillInitialize() {
        queue.async {
            monitors.forEach { $0.cameraWillInitialize() }
        }
    }

    /// Called immediately before attempting recovery from a service reset.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraWillRecoverFromServiceReset(context: CameraContext) {
        queue.async {
            monitors.forEach { $0.cameraWillRecoverFromServiceReset(context: context) }
        }
    }

    /// Called immediately before requesting permission for a media type.
    ///
    /// - Parameter mediaType: The media type for which permission will be requested.
    func cameraWillRequestPermission(for mediaType: AVMediaType) {
        queue.async {
            monitors.forEach { $0.cameraWillRequestPermission(for: mediaType) }
        }
    }
}
