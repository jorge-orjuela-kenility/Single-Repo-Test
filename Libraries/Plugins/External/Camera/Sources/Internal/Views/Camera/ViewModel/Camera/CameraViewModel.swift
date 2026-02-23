//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import Combine
internal import DI
import Foundation
internal import Telemetry
internal import TruVideoMediaUpload
import TruvideoSdk
import UIKit
internal import Utilities

final class CameraViewModel: ObservableObject {
    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let container: StreamContainer
    let monitor: CameraMonitor
    private let onComplete: (TruvideoSdkCameraResult) -> Void

    // MARK: - Dependencies

    @Dependency(\.preferredOrientation)
    var preferredOrientation: UIDeviceOrientation?

    // MARK: - Internal Properties

    /// Indicates whether a photo capture operation is currently in progress.
    ///
    /// This flag prevents multiple simultaneous photo captures and is used for
    /// debouncing capture requests. It's set to `true` when capture starts and
    /// reset to `false` when the capture completes or fails.
    var isCaptureInFlight = false

    /// The system uptime timestamp of the last photo capture operation.
    ///
    /// This property is used for debouncing photo capture requests to prevent
    /// rapid successive captures, especially when flash is enabled. The value
    /// represents the system uptime in seconds when the last photo was captured.
    var lastPhotoCaptureUptime = TimeInterval.zero

    /// The total count of media items (photos and videos) captured in the current session.
    ///
    /// This counter tracks the cumulative number of media items captured and is
    /// used for enforcing maximum media count limits. It's incremented when capture
    /// starts and decremented if capture fails.
    var mediasTaken = 0

    /// The movie output processor responsible for video recording operations.
    ///
    /// This processor handles video encoding, file writing, and recording state
    /// management. It processes video and audio sample buffers and manages the
    /// recording lifecycle including pause/resume functionality.
    let movieOutputProcessor = MovieOutputProcessor()

    /// The count of photos captured in the current session.
    ///
    /// This counter tracks the number of photos taken and is used for enforcing
    /// maximum photo count limits. It's incremented when photo capture succeeds
    /// and decremented if the photo is deleted.
    var photosTaken = 0

    // MARK: - Properties

    /// The audio capture device that manages microphone operations and lifecycle.
    ///
    /// This property provides access to the audio capture device responsible for
    /// microphone operations including audio recording, permission management,
    /// and audio session coordination. The device encapsulates all audio-related
    /// functionality and provides a high-level interface for audio operations.
    let audioDevice: AudioDevice

    /// The core capture session that coordinates all media capture operations.
    ///
    /// This property provides access to the main `AVCaptureSession` that serves as
    /// the central coordinator for all media capture operations. The session manages
    /// the lifecycle of audio and video inputs/outputs, handles device configuration,
    /// and provides the foundation for synchronized media capture.
    let captureSession = AVCaptureSession()

    /// The camera configuration containing settings and preferences for the camera session.
    ///
    /// This property holds the complete configuration for the camera module including
    /// capture modes, media limits, output paths, resolution preferences, and other
    /// settings that control camera behavior. The configuration is set during
    /// initialization and remains constant throughout the camera session lifecycle.
    let configuration: TruvideoSdkCameraConfiguration

    /// Indicates whether the camera device supports torch (flashlight) functionality.
    ///
    /// This property tracks whether the current camera device has torch capabilities.
    /// It defaults to `false` representing the initial state before torch availability
    /// has been determined. The property is updated when the camera device is configured
    /// and torch support is checked.
    var isTorchAvailable = false

    /// Localized error message for display to users. Empty string when no error.
    private(set) var localizedError = ""

    /// The video preview layer that displays the camera feed in the UI.
    let previewLayer = AVCaptureVideoPreviewLayer()

    /// The video capture device that manages camera operations and lifecycle.
    ///
    /// This property provides access to the main video capture device responsible for
    /// camera operations including video recording, photo capture, torch control, zoom
    /// management, and focus handling. The device encapsulates all camera-related
    /// functionality and provides a high-level interface for camera operations.
    let videoDevice: VideoDevice

    // MARK: - Published Properties

    /// Controls whether user interactions are enabled for camera UI components.
    ///
    /// This property manages the interactive state of camera interface elements to prevent
    /// user input during critical operations such as camera switching, recording state changes,
    /// or other asynchronous operations that could cause conflicts or unexpected behavior.
    @Published var allowsHitTesting = false

    /// The current aspect ratio of the camera preview, expressed as height divided by width.
    ///
    /// This property represents the aspect ratio of the camera preview in the format height:width.
    @Published private(set) var aspectRatio: CGFloat

    /// The current orientation of the device relative to the user interface.
    ///
    /// This property tracks the device's orientation and is used to adjust the camera
    /// interface layout and behavior accordingly.
    @Published private(set) var deviceOrientation: UIDeviceOrientation

    /// Indicates whether the user is currently authenticated with the TruVideo service.
    ///
    /// This property tracks the authentication state of the user and determines whether
    /// the camera functionality should be available. When `true`, the user has been
    /// successfully authenticated and can access camera features. When `false`, the
    /// user is not authenticated and camera functionality should be restricted.
    @Published private(set) var isAuthenticated: Bool

    /// Combined authorization status for both audio and video devices.
    /// `true` when both camera and microphone access are granted, `false` when either is denied.
    @Published var isAuthorized = true

    /// Torch/flashlight status. `true` when torch is enabled, `false` when disabled.
    @Published var isTorchEnabled = false

    /// A boolean indicating whether the snackbar should be presented.
    @Published var isSnackbarPresented = false

    /// The last zoom factor applied to the camera preview.
    @Published var lastZoomFactor: CGFloat = 1

    /// Collection of all available video capture presets ordered by quality (highest to lowest).
    ///
    /// This property provides access to all supported video resolution presets in order
    /// of quality, from highest to lowest resolution. It serves as the definitive list
    /// of available capture presets that can be selected by the user or applied
    /// programmatically to the capture session.
    @Published var presets = [AVCaptureSession.Preset.hd1920x1080, .hd1280x720, .vga640x480]

    /// The remaining recording time in Hours:Minutes:Seconds format.
    ///
    /// This property displays how much recording time is left based on the
    /// configured maximum video duration. It updates in real time as the
    /// recording progresses, providing a clear visual indicator of the
    /// remaining available time.
    @Published var remainingTime = 0.toHMS()

    /// Whether the user must confirm before leaving or performing a potentially
    /// destructive action.
    @Published var requiresConfirmation = false

    /// The total duration of recorded video in Hours:Minutes:Seconds format.
    ///
    /// This property displays the cumulative recording time in a human-readable format.
    @Published var timeRecorded = 0.toHMS()

    /// The currently selected video capture resolution preset.
    ///
    /// This property tracks the active video resolution setting for the camera session.
    /// It determines the capture resolution and quality level used for video recording
    /// and photo capture operations. The preset is applied to the underlying
    /// `AVCaptureSession` to configure the appropriate resolution settings.
    @Published var selectedPreset = AVCaptureSession.Preset.hd1280x720

    /// The current lifecycle state of the recording process.
    @Published var state = RecordingState.initialized

    /// A collection of active media upload streams.
    ///
    /// This published property contains all `MUStream` instances that have been created
    /// for uploading media content captured during the camera session. Streams are
    /// automatically added to this array when media is recorded and needs to be uploaded.
    @Published var streams: [MUStream] = []

    /// The current validation state of the view or operation.
    ///
    /// This property tracks the validation status using a `ValidationState` enum that
    /// represents different validation conditions. It defaults to `.initial` representing
    /// the starting state before any validation has been performed.
    @Published private(set) var validationState = ValidationState.initial

    /// The available zoom factor options that users can select from.
    ///
    /// This array defines the zoom levels that are available for selection in the camera
    /// interface. Each value represents a magnification factor.
    @Published var zoomFactors: [CGFloat] = [1]

    /// The current zoom factor applied to the camera preview.
    ///
    /// This property represents the magnification level of the camera view.
    @Published var zoomFactor: CGFloat = 1

    /// The collection of media items displayed in the gallery.
    ///
    /// This published property contains all media items (both video clips and photos)
    /// that are currently displayed in the gallery.
    @Published var medias: [Media] = [] {
        didSet {
            /// Detect media deletion when the array count decreases
            if medias.count < oldValue.count {
                let photoCount = medias.lazy.filter(\.isPhoto).count

                mediasTaken = medias.count

                if photoCount < oldValue.filter(\.isPhoto).count {
                    photosTaken = photoCount
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// The default capture preset for the active camera lens.
    ///
    /// This computed property returns the most appropriate `AVCaptureSession.Preset`
    /// based on the currently active video device (`front` or `back`) and the
    /// configured resolution preferences.
    ///
    /// The selection logic follows this priority order:
    ///
    /// 1. If the available resolutions array is empty, the selected resolution
    ///    (`frontResolution` or `backResolution`) is used directly.
    ///
    /// 2. If the selected resolution exists in the available resolutions array,
    ///    it is used.
    ///
    /// 3. Otherwise, it falls back to the first available preset in the array,
    ///    or `.hd1280x720` if that preset is unavailable.
    ///
    /// - For the **front camera**, it uses `frontResolution` and `frontResolutions`.
    /// - For the **back camera**, it uses `backResolution` and `backResolutions`.
    ///
    /// This ensures the capture session always starts with a valid and supported
    /// preset, even if the configuration contains outdated or unsupported values.
    ///
    /// - Returns: A valid `AVCaptureSession.Preset` for the current lens configuration.
    var defaultPreset: AVCaptureSession.Preset {
        let resolutions = videoDevice.position == .back ? configuration.backResolutions : configuration.frontResolutions
        let resolution = videoDevice.position == .back ? configuration.backResolution : configuration.frontResolution

        guard resolutions.contains(resolution) || resolutions.isEmpty else {
            return resolutions.first?.preset ?? .hd1280x720
        }

        return resolution.preset
    }

    /// Returns a formatted string representing the current video clip count and limit.
    ///
    /// This computed property calculates the number of video clips captured and formats
    /// it according to the configuration's maximum video count. It handles different
    /// display scenarios including unlimited clips, no clips, and limited clip counts.
    var numberOfClips: String {
        let maxVideoCount = TruvideoSdkCameraMediaMode.maxVideoCount
        let numberOfClips = medias.lazy.filter(\.isClip).count

        guard configuration.mode.maxVideoDuration > 0 else {
            return ""
        }

        if configuration.mode.maxVideoCount == maxVideoCount || configuration.mode.maxVideoCount == 0 {
            return numberOfClips == 0 ? "" : "\(numberOfClips)"
        }

        return "\(numberOfClips)/\(configuration.mode.maxVideoCount)"
    }

    /// Returns a formatted string representing the current total media count and limit.
    ///
    /// This computed property calculates the total number of media items captured and
    /// formats it according to the configuration's maximum media count. It only displays
    /// the count when the mode is configured for total media limits (not individual
    /// photo or video limits).
    var numberOfMedias: String {
        let maxMediaCount = TruvideoSdkCameraMediaMode.maxMediaCount
        let isWithinRange = configuration.mode.maxMediaCount > 0 && configuration.mode.maxMediaCount < maxMediaCount

        guard configuration.mode.maxPictureCount == 0, configuration.mode.maxVideoCount == 0, isWithinRange else {
            return ""
        }

        return "\(mediasTaken)/\(configuration.mode.maxMediaCount)"
    }

    /// Returns a formatted string representing the current photo count and limit.
    ///
    /// This computed property calculates the number of photos captured and formats
    /// it according to the configuration's maximum picture count. It handles different
    /// display scenarios including unlimited photos, no photos, and limited photo counts.
    var numberOfPhotos: String {
        let maxPictureCount = TruvideoSdkCameraMediaMode.maxPictureCount
        let numberOfPhotos = medias.lazy.filter(\.isPhoto).count

        if configuration.mode.maxPictureCount == maxPictureCount || configuration.mode.maxPictureCount == 0 {
            return numberOfPhotos == 0 ? "" : "\(numberOfPhotos)"
        }

        return "\(numberOfPhotos)/\(configuration.mode.maxPictureCount)"
    }

    /// Determines whether the remaining recording time should be displayed.
    ///
    /// This computed property evaluates whether the remaining time indicator
    /// needs to be shown during video recording. It compares the current mode's
    /// maximum video duration against the SDK’s global maximum allowed duration,
    /// and returns `true` only when:
    /// - The configured maximum duration is smaller than the SDK limit, and
    /// - The recording state is either `.running` or `.paused`.
    ///
    /// This ensures the remaining time is shown only when the recording has
    /// a defined time limit and is currently active.
    var shouldDisplayRemainingTime: Bool {
        let timeRange = 1 ..< TruvideoSdkCameraMediaMode.maxVideoDurationAllowed

        return timeRange.contains(configuration.mode.maxVideoDuration) && [.running, .paused].contains(state)
    }

    // MARK: - Types

    /// A set of validation states that can be combined to represent different validation conditions.
    ///
    /// `ValidationState` provides a type-safe way to manage validation states using bit flags.
    /// It conforms to `OptionSet` to allow combining multiple states and checking for specific conditions.
    struct ValidationState: OptionSet {
        // MARK: - Properties

        /// The element type of the option set.
        let rawValue: Int

        // MARK: - Static Properties

        /// The initial state when no validation has been performed.
        static let initial = ValidationState([])

        /// The state when the data fails validation.
        ///
        /// This state indicates that validation has been performed and the data
        /// does not meet the required criteria.
        static let invalid = ValidationState(rawValue: 2 << 1)

        /// The state when the data passes validation.
        ///
        /// This state indicates that validation has been performed and the data
        /// meets all required criteria.
        static let valid = ValidationState(rawValue: 2 << 2)
    }

    // MARK: - Initializer

    /// Creates a new instance with configuration, completion handler, and orientation monitoring.
    ///
    /// This initializer sets up the instance with a camera configuration, a completion
    /// callback that will be invoked when the operation completes, and an orientation
    /// monitor for tracking device orientation changes during the process.
    ///
    /// - Parameters:
    ///   - configuration: The camera configuration containing settings and preferences.
    ///   - audioDevice: The audio capture device that manages microphone operations and lifecycle.
    ///   - container: A container that manages media upload streams and coordinates their synchronization.
    ///   - monitor: A type that observes and reports camera lifecycle events.
    ///   - truVideoSdk: The main entry point for the TruVideo SDK.
    ///   - videoDevice: The video capture device that manages camera operations and lifecycle.
    ///   - onCompleted: Closure to be called when the operation completes with the result.
    init(
        configuration: TruvideoSdkCameraConfiguration,
        audioDevice: AudioDevice = AudioDevice(),
        container: StreamContainer = StreamContainer.shared,
        monitor: CameraMonitor = MultiplexCameraMonitor(monitors: [CameraEventMonitor(), CameraTelemetryMonitor()]),
        truVideoSdk: TruVideoSDK = TruvideoSdk,
        videoDevice: VideoDevice = VideoDevice(),
        onComplete: @escaping (TruvideoSdkCameraResult) -> Void
    ) {
        let orientation = UIApplication.shared.activeInterfaceOrientation
        let deviceOrientation = configuration.orientation?.deviceOrientation ?? UIDeviceOrientation(from: orientation)
        let outputDirectory = URL(string: configuration.outputPath) ?? URL(fileURLWithPath: NSTemporaryDirectory())

        self.aspectRatio = deviceOrientation.cameraAspectRatio
        self.audioDevice = audioDevice
        self.configuration = configuration
        self.container = container
        self.deviceOrientation = deviceOrientation
        self.isAuthenticated = truVideoSdk.isAuthenticated
        self.monitor = monitor
        self.onComplete = onComplete
        self.videoDevice = videoDevice

        if ProcessInfo.processInfo.arguments.contains("CameraSwiftUIExampleUITests") {
            isAuthenticated = true
        }

        if isAuthenticated {
            previewLayer.session = captureSession
            previewLayer.videoGravity = .resizeAspectFill

            isTorchEnabled = configuration.flashMode == .on
            movieOutputProcessor.outputDirectory = outputDirectory

            initialize()
            configureObservers()
            configureSessionObservers()
            subscribeToSecondsRecorded()

            if configuration.orientation == nil {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(didReceiveOrientationDidChangeNotification(_:)),
                    name: UIDevice.orientationDidChangeNotification,
                    object: nil
                )
            }
        }
    }

    // MARK: - Deinitializer

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Instance methods

    /// Processes the captured media and marks the validation state as valid.
    ///
    /// This method converts all captured media items to the TruVideo SDK format
    /// and updates the validation state to indicate that the media collection
    /// is ready for further processing or submission.
    func onContinue() {
        let result = TruvideoSdkCameraResult(media: medias.map(TruvideoSdkCameraMedia.from))

        monitor.cameraDidContinue(medias: medias, context: makeContextSnapshot())
        onComplete(result)

        validationState = .valid
    }

    /// Validates clips state before dismissal and updates validation state accordingly.
    ///
    /// Sets `validationState` to `.invalid` if clips or photos are not empty (preventing dismissal),
    /// or `.valid` if clips are empty (allowing dismissal).
    ///
    /// - Parameter force: A Boolean value indicating whether the dismissal should bypass normal validation.
    func onDismiss(force: Bool = false) {
        allowsHitTesting = false

        guard (medias.isEmpty && ![.paused, .running].contains(state)) || force else {
            allowsHitTesting = true
            requiresConfirmation = true

            validationState = .invalid
            return
        }

        let streams = streams

        monitor.cameraDidDismiss(medias: medias, context: makeContextSnapshot())
        onComplete(TruvideoSdkCameraResult(media: []))

        validationState = .valid

        Task.detached {
            for stream in streams {
                try await stream.delete()
            }
        }
    }

    /// Opens the app's settings page in the iOS Settings application.
    ///
    /// This method checks whether the system can open the app settings URL.
    /// If so, it will transition the user to the settings screen, allowing them
    /// to manually update permissions such as camera, microphone, or photo library access.
    func openAppSettings() {
        let openSettingsURLString = UIApplication.openSettingsURLString

        if let settingsURL = URL(string: openSettingsURLString), UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            monitor.cameraDidOpenSettings(context: makeContextSnapshot())
        }
    }

    // MARK: - Notification methods

    @MainActor
    @objc
    private func didReceiveOrientationDidChangeNotification(_ notification: Notification) {
        if UIDevice.current.orientation.isSupported, ![.paused, .running].contains(state) {
            let deviceOrientation = DeviceOrientation(orientation: UIDevice.current.orientation, source: .system)

            orientationDidUpdate(to: deviceOrientation.orientation)
        }
    }

    // MARK: - Internal methods

    /// Displays an error message to the user through the snackbar interface.
    ///
    /// This function provides a centralized way to handle and display error messages
    /// to users in the camera interface. It sets the localized error message and
    /// triggers the presentation of a snackbar to inform the user about the error
    /// condition. This ensures consistent error handling and user feedback across
    /// the camera application.
    ///
    /// The function operates on the main actor to ensure UI updates are performed
    /// safely and synchronously. It updates both the error message and the snackbar
    /// presentation state, providing immediate visual feedback to the user about
    /// any issues that occur during camera operations.
    ///
    /// - Parameter error: The localized error message to display to the user
    @MainActor
    func didReceiveError(_ error: String) {
        localizedError = error
        isSnackbarPresented = true
    }

    /// This method should be invoked whenever the device’s orientation changes.
    /// It updates the internal `deviceOrientation` state, recalculates the camera
    /// preview’s aspect ratio, and triggers a preview orientation refresh via
    /// `updatePreviewOrientation()`.
    ///
    /// - Parameter orientation: The new `UIDeviceOrientation` reported by the
    ///   device’s motion sensors.
    func orientationDidUpdate(to orientation: UIDeviceOrientation) {
        defer { updatePreviewOrientation() }

        deviceOrientation = orientation

        aspectRatio = orientation.cameraAspectRatio
    }

    /// Creates and starts a media upload stream for the specified file.
    ///
    /// This method initiates the upload process for a captured media file (photo or video)
    /// by creating a new stream, appending the file contents, and finalizing the stream.
    /// The stream is automatically added to the `streams` array for tracking and display.
    ///
    /// - Parameters:
    ///   - url: The file URL of the captured media (photo or video) to upload.
    ///   - file: The file type (`.jpg`, `.png`, `.mp4`, etc.) of the media being uploaded.
    func startStreamIfNeeded(from url: URL, of file: FileType) {
        if configuration.streamingUpload {
            Task { @MainActor in
                do {
                    let stream = try await container.newStream(from: url, of: file)

                    streams.append(stream)
                } catch {
                    print(error)
                    // LOG to telemetry
                }
            }
        }
    }

    // MARK: - Private methods

    func makeContextSnapshot() -> CameraContext {
        CameraContext(
            aspectRatio: aspectRatio,
            clipCount: medias.filter(\.isClip).count,
            deviceOrientation: deviceOrientation,
            isTorchAvailable: isTorchAvailable,
            isTorchEnabled: isTorchEnabled,
            photoCount: medias.filter(\.isPhoto).count,
            selectedPreset: selectedPreset,
            state: state,
            videoCodec: videoDevice.configuration.codec,
            videoPosition: videoDevice.position
        )
    }

    private func subscribeToSecondsRecorded() {
        movieOutputProcessor.$recordingDuration
            .filter(\.isValid)
            .map(\.seconds)
            .receive(on: RunLoop.main)
            .sink { [weak self] seconds in
                guard let self else { return }

                timeRecorded = seconds.toHMS()
                remainingTime = max(self.configuration.mode.maxVideoDuration - seconds, 0).toHMS()

                if seconds >= configuration.mode.maxVideoDuration, state == .running {
                    toggleRecord()
                    monitor.cameraDidReachMaxClipDuration(seconds, context: makeContextSnapshot())

                    Task {
                        await self.didReceiveError(Localizations.maxClipDurationReached)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func updatePreviewOrientation() {
        Task { @MainActor in
            let videoOrientation = AVCaptureVideoOrientation(from: deviceOrientation)

            previewLayer.connection?.videoOrientation = videoOrientation

            await videoDevice.setVideoOrientation(videoOrientation)

            monitor.cameraDidUpdateOrientation(orientation: deviceOrientation, context: makeContextSnapshot())
        }
    }
}

extension UIDeviceOrientation {
    /// The camera preview aspect ratio corresponding to this device orientation.
    ///
    /// This value is used to determine the layout ratio for the camera preview
    /// based on the current physical orientation of the device.
    ///
    /// - For landscape orientations, a 16:9 ratio is returned.
    /// - For portrait and other orientations (`faceUp`, `faceDown`, `unknown`),
    ///   a 9:16 ratio is returned.
    /// - On iPad, a square (1:1) aspect ratio is always used to provide
    ///   a consistent preview layout across orientations.
    ///
    /// This property is intended specifically for camera preview layout logic
    /// and should not be used as a general-purpose screen aspect ratio.
    fileprivate var cameraAspectRatio: CGFloat {
        guard !UIDevice.current.isPad else {
            return 1
        }

        switch self {
        case .landscapeLeft, .landscapeRight:
            return 16 / 9
        default:
            return 9 / 16
        }
    }
}
