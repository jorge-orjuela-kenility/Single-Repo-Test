//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Combine
internal import DI
import Foundation
import SwiftUI
import TruvideoSdk
import UIKit

/// A specialized hosting controller responsible for displaying and managing the SwiftUI-based camera interface.
///
/// This controller encapsulates a `CameraView` and coordinates its interaction with UIKit,
/// including orientation handling and Combine-based observation of the camera's internal state.
///
/// The controller dynamically updates its supported interface orientations based on the camera's
/// operational state — for example, locking to landscape while recording and restoring the system’s
/// supported orientations when paused or finished.
final class CameraHostingController: UIHostingController<CameraView> {
    // MARK: - Private Properties

    private var _supportedInterfaceOrientations = UIInterfaceOrientationMask.allButUpsideDown
    private var cancellables = Set<AnyCancellable>()
    private let onDismiss: () -> Void
    private let orientationMonitor: OrientationMonitor
    private let viewModel: CameraViewModel

    // MARK: - Dependencies

    @Dependency(\.preferredOrientation)
    private var preferredOrientation: UIDeviceOrientation?

    // MARK: - Overridden Properties

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        _supportedInterfaceOrientations
    }

    // MARK: - Initializers

    /// Creates a new camera hosting controller with a given configuration and completion handler.
    ///
    /// The initializer sets up the SwiftUI `CameraView` using the provided `CameraViewModel`.
    /// It also subscribes to orientation changes via the view model’s `state` publisher.
    ///
    /// - Parameters:
    ///   - configuration: The camera configuration containing settings and
    ///     preferences used to initialize the camera experience.
    ///   - truVideoSdk: The TruVideo SDK instance used to perform camera-related
    ///     operations. Defaults to the shared `TruvideoSdk` instance.
    ///   - orientationMonitor: A type that defines the interface for monitoring device orientation changes.
    ///   - onComplete: A closure invoked when the camera flow finishes with a
    ///     `TruvideoSdkCameraResult` (for example, after capturing or confirming
    ///     media). Use this to handle the final result of the camera session.
    ///   - onDismiss: A closure invoked when the hosting controller is dismissed,
    ///     regardless of whether the camera flow completed successfully or was
    ///     cancelled.
    init(
        configuration: TruvideoSdkCameraConfiguration,
        truVideoSdk: TruVideoSDK = TruvideoSdk,
        orientationMonitor: OrientationMonitor = DeviceOrientationMonitor(),
        onComplete: @escaping (TruvideoSdkCameraResult) -> Void,
        onDismiss: @escaping () -> Void = {}
    ) {
        let preferredOrientation = configuration.orientation?.deviceOrientation
        let orientationMask = preferredOrientation.map(UIInterfaceOrientationMask.init(from:))
        let supportedInterfaceOrientations = orientationMask ?? Bundle.main.supportedOrientations

        _supportedInterfaceOrientations = supportedInterfaceOrientations

        self.onDismiss = onDismiss
        self.orientationMonitor = orientationMonitor
        self.viewModel = CameraViewModel(configuration: configuration, truVideoSdk: truVideoSdk, onComplete: onComplete)

        DependencyValues.current.orientationMonitor = orientationMonitor
        DependencyValues.current.preferredOrientation = preferredOrientation

        let rootView = CameraView(viewModel: viewModel)

        super.init(rootView: rootView)

        if truVideoSdk.isAuthenticated {
            setNeedsUpdateSupportedInterfaceOrientations()

            viewModel.$state
                .sink { [weak self] state in
                    self?.didReceiveRecordingStateUpdate(state)
                }
                .store(in: &cancellables)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle methods

    override func viewDidDisappear(_ animated: Bool) {
        onDismiss()
        orientationMonitor.stopMonitoring()

        super.viewDidDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    // swiftlint:enable type_contents_order

    // MARK: - Private methods

    private func didReceiveRecordingStateUpdate(_ state: RecordingState) {
        defer {
            if #available(iOS 16.0, *) {
                setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }

        guard [.paused, .running].contains(state) else {
            setNeedsUpdateSupportedInterfaceOrientations()

            if !UIDevice.current.isPad, preferredOrientation == nil {
                orientationMonitor.startMonitoring()
            }

            return
        }

        let orientation = view.window?.windowScene?.interfaceOrientation ?? .portrait

        _supportedInterfaceOrientations = UIInterfaceOrientationMask(from: orientation)
        orientationMonitor.stopMonitoring()
    }

    private func setNeedsUpdateSupportedInterfaceOrientations() {
        let orientation = preferredOrientation.map(UIInterfaceOrientationMask.init(from:))

        _supportedInterfaceOrientations = orientation ?? Bundle.main.supportedOrientations
    }
}

extension UIInterfaceOrientationMask {
    /// Creates an interface orientation mask from a camera-specific orientation.
    ///
    /// This initializer maps a `UIDeviceOrientation` value to the
    /// corresponding `UIInterfaceOrientationMask` used by UIKit for rotation and
    /// layout decisions.
    ///
    /// Use this when you need to express the camera’s desired orientation in terms
    /// of UIKit’s orientation mask system (for example, when returning
    /// `supportedInterfaceOrientations` from a view controller).
    ///
    /// - Parameter orientation: The camera interface orientation to convert into
    ///   a `UIInterfaceOrientationMask`.
    fileprivate init(from orientation: UIDeviceOrientation) {
        self = switch orientation {
        case .landscapeLeft:
            .landscapeRight

        case .landscapeRight:
            .landscapeLeft

        default:
            .portrait
        }
    }

    /// Creates a new orientation value from the given UIKit interface orientation,
    /// normalizing unsupported or unspecified cases to `.portrait`.
    ///
    /// This initializer translates a `UIInterfaceOrientation` coming from UIKit
    /// (for example, from device or window orientation queries) into the internal
    /// orientation representation used by the camera module. Only the standard
    /// `.portrait`, `.landscapeLeft`, and `.landscapeRight` cases are mapped
    /// explicitly; any other orientation (such as `.portraitUpsideDown` or unknown
    /// values) is gracefully normalized to `.portrait`.
    ///
    /// - Parameter orientation: The `UIInterfaceOrientation` value to be converted
    ///   into the corresponding internal orientation.
    fileprivate init(from orientation: UIInterfaceOrientation) {
        self =
            switch orientation {
            case .portrait:
                .portrait

            case .landscapeLeft:
                .landscapeLeft

            case .landscapeRight:
                .landscapeRight

            default:
                .portrait
            }
    }
}

extension UIDeviceOrientation {
    /// Maps a `UIInterfaceOrientation` value to a corresponding `UIDeviceOrientation`.
    ///
    /// This initializer exists because `UIInterfaceOrientation` and `UIDeviceOrientation`
    /// use opposite coordinate systems for landscape orientations:
    /// - `UIInterfaceOrientation.landscapeLeft` corresponds to
    ///   `UIDeviceOrientation.landscapeRight`
    /// - `UIInterfaceOrientation.landscapeRight` corresponds to
    ///   `UIDeviceOrientation.landscapeLeft`
    ///
    /// This inversion is required to correctly interpret the physical device orientation
    /// when converting from interface-based orientation (UI) to device-based orientation
    /// (hardware).
    ///
    /// Any unsupported or unknown orientations default to `.portrait` to ensure a safe,
    /// predictable fallback.
    ///
    /// - Parameter orientation: The interface orientation to convert.
    init(from orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait:
            self = .portrait

        case .landscapeLeft:
            self = .landscapeRight

        case .landscapeRight:
            self = .landscapeLeft

        default:
            self = .portrait
        }
    }
}
