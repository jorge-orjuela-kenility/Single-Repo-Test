//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import DI
import SwiftUI

final class AdaptiveOrientationLayoutViewModel: ObservableObject {
    // MARK: - Private Properties

    private var previousOrientation = DeviceOrientation.unknown

    // MARK: - Dependencies

    @Dependency(\.orientationMonitor)
    private var orientationMonitor: OrientationMonitor

    @Dependency(\.preferredOrientation)
    private var preferredOrientation: UIDeviceOrientation?

    // MARK: - Published Properties

    /// The alignment to use when positioning content within the layout frame.
    ///
    /// This property determines how content is aligned within its container based on the
    /// device orientation. The alignment is automatically updated when the device orientation
    /// changes:
    /// - `.top`: Used for portrait orientations
    /// - `.leading`: Used for landscape right orientation
    /// - `.trailing`: Used for landscape left orientation
    ///
    /// The alignment is applied to the frame of the content view to ensure proper positioning
    /// during orientation transitions. The property is published to allow SwiftUI views to
    /// react to alignment changes with smooth animations.
    @Published private(set) var alignment = Alignment.top

    /// The padding value to apply to the layout, measured in points.
    ///
    /// This property specifies the amount of padding to apply around the content. Currently
    /// set to `0` and reserved for future use when padding adjustments based on orientation
    /// are needed. The property is published to allow SwiftUI views to react to padding changes.
    @Published private(set) var padding = 0

    /// The rotation angle to apply to the content based on device orientation.
    ///
    /// This property contains the angle by which the content should be rotated to match the
    /// device's physical orientation. The rotation angle is automatically calculated when
    /// orientation changes:
    /// - `0°`: For portrait orientations (no rotation)
    /// - `90°`: For landscape left orientation (rotate clockwise)
    /// - `-90°`: For landscape right orientation (rotate counter-clockwise)
    ///
    /// The rotation is applied using SwiftUI's `rotationEffect` modifier to provide smooth
    /// visual transitions when the device orientation changes. The property is published to
    /// allow SwiftUI views to react to rotation changes with animations.
    @Published private(set) var rotationAngle = Angle.zero

    // MARK: - Initializer

    /// Creates a new instance of the `AdaptiveOrientationLayoutViewModel`.
    init() {
        if let preferredOrientation {
            let deviceOrientation = DeviceOrientation(orientation: preferredOrientation, source: .system)

            didReceive(deviceOrientation)
        }

        Task { @MainActor in
            for try await orientation in orientationMonitor.orientationUpdates() {
                didReceive(orientation)
            }
        }
    }

    // MARK: - OrientationMonitor

    /// Handles a new device orientation update and applies the corresponding rotation angle.
    ///
    /// This method is triggered when a new `DeviceOrientationInfo` is received.
    /// It updates the current orientation, calculates the transition between the
    /// previous and new orientations, and determines the appropriate rotation angle.
    /// If the orientation source comes from sensors while the device is physically
    /// in portrait mode, it preserves or updates the rotation angle accordingly.
    ///
    /// - Parameter deviceOrientation: The latest orientation information, including its source and value.
    func didReceive(_ deviceOrientation: DeviceOrientation) {
        let hasMissMatch = deviceOrientation.orientation.isLandscape && UIDevice.current.orientation.isPortrait
        let hasOrientationChanged = deviceOrientation.orientation != previousOrientation.orientation || hasMissMatch

        guard hasOrientationChanged || deviceOrientation.source == .system, preferredOrientation == nil else {
            return
        }

        previousOrientation = deviceOrientation

        guard deviceOrientation.source == .sensors else {
            alignment = .top
            rotationAngle = .zero

            return
        }

        switch deviceOrientation.orientation {
        case .landscapeLeft:
            alignment = .trailing
            rotationAngle = Angle(degrees: 90)

        case .landscapeRight:
            alignment = .leading
            rotationAngle = Angle(degrees: -90)

        default:
            alignment = .top
            rotationAngle = .zero
        }
    }
}
