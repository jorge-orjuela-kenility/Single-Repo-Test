//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import DI
import Foundation
import SwiftUI
import UIKit

final class OrientationViewModel: ObservableObject {
    // MARK: - Private Properties

    private let orientationCalculator = OrientationAngleCalculator()

    // MARK: - Dependencies

    @Dependency(\.orientationMonitor)
    private var orientationMonitor: OrientationMonitor

    @Dependency(\.preferredOrientation)
    private var preferredOrientation: UIDeviceOrientation?

    // MARK: - Properties

    /// The previous device orientation before the current change.
    ///
    /// This property tracks the orientation state before the most recent change,
    /// allowing the view model to calculate the transition from the previous
    /// orientation to the new one.
    private(set) var previousDeviceOrientation = UIDeviceOrientation.portrait

    // MARK: - Published Properties

    /// The current device orientation being tracked.
    ///
    /// This property stores the most recent device orientation detected by the
    /// orientation monitor.
    @Published private(set) var deviceOrientation = DeviceOrientation(orientation: .portrait, source: .system)

    /// The current rotation angle for the circular button.
    ///
    /// This published property contains the calculated rotation angle that should
    /// be applied to the circular button.
    @Published var rotationAngle = Angle.zero

    // MARK: - Initializer

    /// Creates a new instance of the `OrientationViewModel`.
    init() {
        let orientation = preferredOrientation ?? UIDeviceOrientation.portrait

        deviceOrientation = DeviceOrientation(orientation: orientation, source: .system)

        if orientationMonitor.currentOrientation.orientation.isSupported {
            didReceive(orientationMonitor.currentOrientation)
        }

        Task { @MainActor in
            for try await orientation in orientationMonitor.orientationUpdates() {
                didReceive(orientation)
            }
        }
    }

    // MARK: - Private methods

    private func calculateAngle(_ transition: OrientationTransition) -> Angle {
        orientationCalculator
            .withInputAngle(rotationAngle)
            .withOrientation(preferredOrientation)
            .withTransition(transition)
            .calculate()
    }

    private func didReceive(_ newDeviceOrientation: DeviceOrientation) {
        let hasMissMatch = newDeviceOrientation.orientation.isLandscape && UIDevice.current.orientation.isPortrait
        let hasOrientationChanged = newDeviceOrientation.orientation != deviceOrientation.orientation

        guard hasOrientationChanged || hasMissMatch else { return }

        previousDeviceOrientation = hasOrientationChanged ? deviceOrientation.orientation : .portrait
        deviceOrientation = newDeviceOrientation

        guard UIDevice.current.userInterfaceIdiom != .pad else {
            return
        }

        let transition = OrientationTransition(from: previousDeviceOrientation, to: deviceOrientation.orientation)

        if UIDevice.current.orientation.isPortrait {
            withAnimation(.spring(duration: 0.3)) {
                rotationAngle = calculateAngle(transition)
            }
        }

        if deviceOrientation.orientation.isPortrait || deviceOrientation.orientation == preferredOrientation {
            rotationAngle = .degrees(0)
        }
    }
}
