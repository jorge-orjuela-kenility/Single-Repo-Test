//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import DI
import SwiftUI
import UIKit

/// Resolves the resulting rotation angle when transitioning between device orientations.
///
/// `OrientationAngleCalculator` is responsible for interpreting an input rotation angle
/// according to a specific device orientation reference frame (portrait, landscape left,
/// or landscape right). Rather than performing a raw mathematical rotation, this type
/// applies orientation-aware rules to ensure that angle transitions remain visually
/// consistent when the device orientation changes.
///
/// The calculator operates using three pieces of state:
/// - A **reference orientation**, which defines the coordinate system used to interpret angles
/// - An **orientation transition**, describing the change from one device orientation to another
/// - An **input angle**, representing the last known rotation angle prior to the transition
///
/// Once these values are configured, calling `calculate()` returns the resolved angle
/// in the target orientation’s coordinate space.
final class OrientationAngleCalculator {
    // MARK: - Private Properties

    private var currentAngle = Angle.zero
    private var referenceOrientation: UIDeviceOrientation?
    private var transition = OrientationTransition(from: .faceDown, to: .faceDown)

    // MARK: - Computed Properties

    private var angle: Angle {
        switch (transition.from, transition.to) {
        case (.portrait, .landscapeRight):
            .degrees(-90)

        case (.portrait, .landscapeLeft):
            .degrees(90)

        case (.landscapeRight, .landscapeLeft):
            .degrees(90)

        case (.landscapeLeft, .portrait):
            currentAngle.radians > 0 ? .degrees(0) : .degrees(-360)

        case (.landscapeLeft, .landscapeRight):
            .degrees(-90)

        case (.landscapeRight, .portrait):
            currentAngle.radians > 0 ? .degrees(360) : .degrees(0)

        default:
            currentAngle
        }
    }

    private var angleInLandscape: Angle {
        switch (transition.from, transition.to) {
        case (.portrait, .landscapeRight):
            currentAngle.radians > 0 ? .degrees(0) : .degrees(-180)

        case (.landscapeLeft, .landscapeRight), (.landscapeRight, .landscapeLeft):
            .degrees(180)

        case (.landscapeRight, .portrait) where referenceOrientation == .landscapeRight:
            currentAngle.radians > 0 ? .degrees(270) : .degrees(90)

        case (.portrait, .landscapeLeft) where referenceOrientation == .landscapeRight:
            currentAngle.radians > 0 ? .degrees(180) : .degrees(0)

        case (.landscapeLeft, .portrait) where referenceOrientation == .landscapeRight:
            currentAngle.radians > 0 ? .degrees(90) : .degrees(0)

        case (.landscapeRight, .portrait) where referenceOrientation == .landscapeLeft:
            currentAngle.radians > 0 ? .degrees(270) : .degrees(-90)

        case (.portrait, .landscapeLeft) where referenceOrientation == .landscapeLeft:
            currentAngle.radians > 0 ? .degrees(360) : .degrees(0)

        case (.landscapeLeft, .portrait) where referenceOrientation == .landscapeLeft:
            currentAngle.radians > 0 ? .degrees(0) : .degrees(-90)

        default:
            currentAngle
        }
    }

    // MARK: - Configuration

    /// Sets the input angle used as the basis for the rotation calculation.
    ///
    /// - Parameter angle: The last known rotation angle before the orientation change.
    /// - Returns: Self, allowing for method chaining.
    func withInputAngle(_ angle: Angle) -> Self {
        self.currentAngle = angle
        return self
    }

    /// Sets the reference orientation used to interpret rotation angles.
    ///
    /// - Parameter referenceOrientation: The orientation that defines the coordinate
    ///   system for angle resolution. If `nil`, a default reference frame is used.
    /// - Returns: Self, allowing for method chaining.
    func withOrientation(_ referenceOrientation: UIDeviceOrientation?) -> Self {
        self.referenceOrientation = referenceOrientation
        return self
    }

    /// Sets the orientation transition to be evaluated.
    ///
    /// - Parameter transition: A value describing the source and destination
    ///   device orientations involved in the rotation.
    /// - Returns: Self, allowing for method chaining.
    func withTransition(_ transition: OrientationTransition) -> Self {
        self.transition = transition
        return self
    }

    // MARK: - Instance methods

    /// Calculates and returns the resolved rotation angle for the current configuration.
    ///
    /// The calculation applies orientation-specific rules based on the configured
    /// reference orientation. Each reference orientation uses a distinct coordinate
    /// system to ensure smooth and visually consistent rotations.
    ///
    /// - Returns: The resolved `Angle` in the target orientation’s coordinate space.
    func calculate() -> Angle {
        guard let referenceOrientation, referenceOrientation.isLandscape else {
            return angle
        }

        return angleInLandscape
    }
}

/// A model that represents a transition between two device orientations.
///
/// `OrientationTransition` encapsulates the mapping from a starting orientation (`from`)
/// to a target orientation (`to`). It is primarily used to calculate the correct
/// rotation angle when animating between different device orientations.
///
/// The type also provides a set of predefined valid transitions, with their corresponding
/// `Angle` values, ensuring that only supported rotations are handled.
///
/// Typical usage includes:
/// - Validating whether a transition is supported.
/// - Mapping an input angle to its equivalent angle in the target orientation.
/// - Ensuring smooth icon and interface rotations during device orientation changes.
struct OrientationTransition: Hashable {
    /// The starting orientation of the device
    let from: UIDeviceOrientation

    // swiftlint:disable identifier_name
    /// The target orientation of the device
    let to: UIDeviceOrientation
    // swiftlint:enable identifier_name
}
