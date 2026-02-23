//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import DI
import Foundation
import SwiftUI
import UIKit

final class ZoomPickerViewModel: ObservableObject {
    // MARK: - Private Properties

    private let orientationCalculator = OrientationAngleCalculator()
    private var previousDeviceOrientation = UIDeviceOrientation.portrait

    // MARK: - Dependencies

    @Dependency(\.orientationMonitor)
    private var orientationMonitor: OrientationMonitor

    @Dependency(\.preferredOrientation)
    private var preferredOrientation: UIDeviceOrientation?

    // MARK: - Properties

    /// The base size used for layout and mask calculations.
    ///
    /// This constant defines the default dimension (44 points) applied to masks
    /// when determining their width or height in collapsed states.
    /// It serves as the minimum or fixed size whenever the mask is not expanded.
    let size: CGFloat = UIDevice.current.isPad ? 55 : 44

    // MARK: - Published Properties

    /// The current rotation angle for the collapsible.
    ///
    /// This published property contains the calculated rotation angle that should
    /// be applied to the collapsible.
    @Published var collapsibleAngle = Angle.zero

    /// The current device orientation being tracked.
    ///
    /// This property stores the most recent device orientation detected by the
    /// orientation monitor.
    @Published private(set) var deviceOrientation = DeviceOrientation(orientation: .portrait, source: .system)

    /// The maximum available size for the zoom picker UI component.
    ///
    /// This property defines the largest bounding size (width and height) that the
    /// zoom picker can occupy within its container. It is typically updated in
    /// response to layout changes, such as device rotation or parent view resizing,
    /// to ensure the zoom picker scales correctly within the available space.
    @Published private(set) var maxSize = CGSize.zero

    /// The current rotation angle for the zoom value.
    ///
    /// This published property contains the calculated rotation angle that should
    /// be applied to the zoom value.
    @Published var rotationAngle = Angle.zero

    // MARK: - Computed Properties

    private var isSystemLandscape: Bool {
        deviceOrientation.orientation.isLandscape && deviceOrientation.source == .system
    }

    // MARK: - Initializer

    init() {
        if preferredOrientation == nil, UIDevice.current.orientation != .portrait {
            let interfaceOrientation = UIApplication.shared.activeInterfaceOrientation
            didReceive(.init(orientation: UIDeviceOrientation(from: interfaceOrientation), source: .system))
        }

        if let preferredOrientation {
            deviceOrientation = DeviceOrientation(orientation: preferredOrientation, source: .system)
            didReceive(self.deviceOrientation)
        }

        let orientationMonitor = orientationMonitor

        Task { @MainActor [weak self] in
            for try await orientation in orientationMonitor.orientationUpdates() {
                guard let self else {
                    return
                }

                didReceive(orientation)
            }
        }
    }

    // MARK: - Private methods

    /// Handles a new device orientation update and applies the corresponding rotation angle.
    ///
    /// This method is triggered when a new `DeviceOrientationInfo` is received.
    /// It updates the current orientation, calculates the transition between the
    /// previous and new orientations, and determines the appropriate rotation angle.
    /// If the orientation source comes from sensors while the device is physically
    /// in portrait mode, it preserves or updates the rotation angle accordingly.
    ///
    /// - Parameter orientation: The latest orientation information, including its
    ///   source (e.g., system or sensors) and value.
    private func didReceive(_ deviceOrientation: DeviceOrientation) {
        Task { @MainActor in
            let hasOrientationChanged = deviceOrientation.orientation != self.deviceOrientation.orientation

            guard hasOrientationChanged || deviceOrientation.source == .system, preferredOrientation == nil else {
                return
            }

            self.previousDeviceOrientation = self.deviceOrientation.orientation
            self.deviceOrientation = deviceOrientation

            let transition = OrientationTransition(from: previousDeviceOrientation, to: deviceOrientation.orientation)

            if deviceOrientation.source == .sensors, UIDevice.current.orientation == .portrait {
                rotationAngle = calculateAngle(transition)
                collapsibleAngle = deviceOrientation.orientation.isPortrait ? Angle.zero : Angle(degrees: 360)
            }

            if deviceOrientation.source == .system, UIDevice.current.orientation == .portrait {
                rotationAngle = calculateAngle(transition)
            }
        }
    }

    /// Calculates the rotation angle required to transition between orientations.
    ///
    /// This method configures the internal `orientationCalculator` with the current
    /// rotation state, the preferred reference orientation, and the requested transition.
    /// It then delegates the angle computation to the calculator, returning the resulting
    /// `Angle` to be applied to the view or layer.
    ///
    /// The calculation accounts for the current device rotation, the target orientation,
    /// and any intermediate transition logic defined by the calculator.
    ///
    /// - Parameter transition: The orientation transition to be performed, describing
    ///   the source and destination orientations.
    /// - Returns: An `Angle` representing the rotation needed to correctly align the
    ///   interface with the target orientation.
    private func calculateAngle(_ transition: OrientationTransition) -> Angle {
        orientationCalculator
            .withInputAngle(rotationAngle)
            .withOrientation(preferredOrientation)
            .withTransition(transition)
            .calculate()
    }

    // MARK: - Instance methods

    /// Returns a formatted string representation of the number with conditional decimal precision.
    ///
    /// This computed property formats the number to show either no decimal places or one decimal place
    /// based on whether the number has a fractional component. If the number is a whole number (no decimal
    /// part), it displays without decimal places. If it has a fractional part, it displays with one
    /// decimal place for precision.
    ///
    /// - Returns: A formatted string that shows either "%.0f" or "%.1f" format depending on the number's value.
    func format(_ value: Double) -> String {
        let format = value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"

        return String(format: format, value)
    }

    /// Calculates the maximum size of an animatable mask based on the device orientation and expansion state.
    ///
    /// This method determines the mask's maximum width and height depending on whether:
    /// - The orientation is coming from the system or from sensors.
    /// - The device is in portrait or landscape orientation.
    /// - The mask is currently expanded or collapsed.
    ///
    /// - Parameter isExpanded: A Boolean flag indicating whether the mask should be expanded (`true`) or collapsed
    /// (`false`).
    /// - Returns: A `CGSize` representing the maximum size of the animatable mask.
    func maxSizeForAnimatableMask(isExpanded: Bool) -> CGSize {
        if UIDevice.current.isPad || isSystemLandscape {
            return isExpanded ? CGSize(width: size, height: .infinity) : CGSize(width: size, height: size)
        }

        guard deviceOrientation.orientation.isPortrait else {
            return isExpanded ? CGSize(width: .infinity, height: size) : CGSize(width: size, height: size)
        }

        return isExpanded ? CGSize(width: .infinity, height: size) : CGSize(width: size, height: size)
    }

    /// Calculates the maximum size of a collapsible mask based on the device orientation and expansion state.
    ///
    /// Similar to `maxSizeForAnimatableMask`, this method adapts the mask dimensions
    /// based on the orientation source and whether the mask is expanded.
    /// The main difference is that when the mask is collapsed, one of its dimensions
    /// shrinks to `0` instead of keeping a fixed `size`.
    ///
    /// - Parameter isExpanded: A Boolean flag indicating whether the mask should be expanded (`true`) or collapsed
    /// (`false`).
    /// - Returns: A `CGSize` representing the maximum size of the collapsible mask.
    func maxSizeForCollapsibleMask(isExpanded: Bool) -> CGSize {
        if UIDevice.current.isPad || isSystemLandscape {
            return isExpanded ? CGSize(width: size, height: .infinity) : CGSize(width: size, height: 0)
        }

        guard deviceOrientation.orientation.isPortrait else {
            return isExpanded ? CGSize(width: .infinity, height: size) : CGSize(width: size, height: 0)
        }

        return isExpanded ? CGSize(width: .infinity, height: size) : CGSize(width: 0, height: size)
    }
}
