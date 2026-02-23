//
// Copyright © 2026 TruVideo. All rights reserved.
//

import AVFoundation
import Foundation

/// A `CameraMonitor` implementation that translates camera lifecycle events
/// into SDK-level camera events.
///
/// `CameraEventMonitor` acts as an adapter between low-level camera lifecycle
/// callbacks and the Truvideo SDK event system. Each camera event is mapped
/// to a corresponding `TruvideoSdkCameraEvent` and emitted through the
/// shared event stream.
///
/// This type is intended for telemetry, analytics, and event propagation
/// purposes only. It must not mutate camera state.
struct CameraEventMonitor: CameraMonitor, @unchecked Sendable {
    // MARK: - Private properties

    private let events: TruvideoSdkCameraEventPublisher

    // MARK: - Initializer

    /// Creates a new camera event monitor that publishes camera lifecycle events.
    ///
    /// This initializer configures a `CameraEventMonitor` instance with the
    /// provided event publisher. All camera events received by this monitor
    /// will be transformed into SDK-level camera events and forwarded through
    /// the given publisher.
    ///
    /// - Parameter events: The publisher responsible for emitting
    ///   `TruvideoSdkCameraEvent` values to downstream subscribers.
    init(events: TruvideoSdkCameraEventPublisher = TruvideoSdkCameraEvent.events) {
        self.events = events
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
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventPictureTaken(media: .from(photo)))

        events.send(event)
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
        let result = TruvideoSdkCameraResult(media: medias.map(TruvideoSdkCameraMedia.from))
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventMediaContinue(media: result.media))

        events.send(event)
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
        let result = TruvideoSdkCameraResult(media: medias.map(TruvideoSdkCameraMedia.from))
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventMediaDiscard(media: result.media))

        events.send(event)
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
        let lensFacing = context.videoPosition == .back ? TruvideoSdkCameraLensFacing.back : .front
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventCameraFlipped(lensFacing: lensFacing))

        events.send(event)
    }

    /// Called when the capture session preset changes.
    ///
    /// This event reflects changes in capture quality, resolution,
    /// or performance characteristics.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangePreset(context: CameraContext) {
        let size = context.selectedPreset.size
        let resolution = TruvideoSdkCameraResolutionDeprecated(width: Int32(size.width), height: Int32(size.height))
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventResolutionChanged(resolution: resolution))

        events.send(event)
    }

    /// Called when the torch state changes.
    ///
    /// This event indicates that the torch has been enabled or disabled.
    ///
    /// - Parameter context: A snapshot of the camera state at the time of failure.
    func cameraDidChangeTorch(context: CameraContext) {
        let flashMode = context.isTorchEnabled ? TruvideoSdkCameraFlashMode.on : .off
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventFlashModeChanged(flashMode: flashMode))

        events.send(event)
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
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventZoomChanged(zoom: Float(zoomFactor)))

        events.send(event)
    }

    /// Called when a recording finishes successfully.
    ///
    /// - Parameters:
    ///    - clip: The finalized video clip produced by the recording session.
    ///    -  context: A snapshot of the camera state at the time of failure.
    func cameraDidFinishRecording(clip: VideoClip, context: CameraContext) {
        let event = TruvideoSdkCameraEvent(type: .truvideoSdkCameraEventRecordingFinished(media: .from(clip)))

        events.send(event)
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
        let size = context.selectedPreset.size
        let resolution = TruvideoSdkCameraResolutionDeprecated(width: Int32(size.width), height: Int32(size.height))
        let event = TruvideoSdkCameraEvent(
            type: .truvideoSdkCameraEventRecordingPaused(
                resolution: resolution,
                orientation: TruvideoSdkCameraOrientation(orientation: context.deviceOrientation),
                lensFacing: context.videoPosition == .back ? .back : .front
            )
        )

        events.send(event)
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
        let size = context.selectedPreset.size
        let resolution = TruvideoSdkCameraResolutionDeprecated(width: Int32(size.width), height: Int32(size.height))
        let event = TruvideoSdkCameraEvent(
            type: .truvideoSdkCameraEventRecordingStarted(
                resolution: resolution,
                orientation: TruvideoSdkCameraOrientation(orientation: context.deviceOrientation),
                lensFacing: context.videoPosition == .front ? .front : .back
            )
        )

        events.send(event)
    }
}
