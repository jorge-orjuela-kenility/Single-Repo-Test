//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import UIKit

/// Represents orientation data including its source of origin.
struct DeviceOrientation: Hashable {
    /// The current device orientation.
    let orientation: UIDeviceOrientation

    /// The source of the orientation update.
    let source: Source

    // MARK: - Static Properties

    /// A default unknown orientation value, typically used as a fallback.
    static let unknown = DeviceOrientation(orientation: .unknown, source: .system)

    // MARK: - Types

    /// The origin of the orientation reading.
    enum Source {
        /// Orientation derived from physical sensors (e.g., accelerometer/gyroscope).
        case sensors

        /// Orientation reported by the iOS system/device.
        case system
    }
}

/// Represents the origin or scope of orientation updates delivered by an
/// `OrientationMonitor`.
///
/// `MonitoringType` allows subscribers to specify whether they want to receive:
/// - **all orientation updates** (from both sensors and the system),
/// - **only physical sensor–based updates**, or
/// - **only system-reported interface orientation updates**.
///
/// This filtering helps clients receive only the orientation events relevant
/// to their use-case—for example, using system orientation to align UI rotation,
/// or using sensor orientation for real-time motion responsiveness.
enum MonitoringType {
    /// Receives **all orientation updates**, regardless of source.
    ///
    /// This includes:
    /// - physical sensor readings (accelerometer/gyroscope), and
    /// - system-reported interface orientation.
    ///
    /// Use this option when you require a unified stream that merges both
    /// sources and selects the most appropriate orientation over time.
    case all

    /// Receives orientation changes derived exclusively from **device sensors**.
    ///
    /// These updates reflect the device’s physical orientation based on motion data
    /// and may provide finer-grained updates than system notifications.
    ///
    /// Use this option when building motion-reactive UI or features that
    /// depend on the actual physical orientation of the device.
    case sensors

    /// Receives orientation updates reported by the **iOS system**.
    ///
    /// These updates correspond to interface rotations determined by the system,
    /// often influenced by factors like orientation lock or the active app state.
    ///
    /// Use this when synchronizing UI components with system interface orientation,
    /// such as rotating buttons or adjusting layouts based on the system’s perspective.
    case system
}

/// A protocol that defines the interface for monitoring device orientation changes.
///
/// This protocol provides a standardized way to observe and respond to device orientation
/// changes across different monitoring implementations. It abstracts the complexity of
/// orientation detection and provides a clean callback-based interface for receiving
/// orientation updates.
///
/// ## Usage
///
/// ```swift
/// class MyViewController: UIViewController {
///     private let orientationMonitor: OrientationMonitor
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///
///         orientationMonitor.updateHandler = { [weak self] orientation in
///             self?.handleOrientationChange(to: orientation)
///         }
///
///         orientationMonitor.startMonitoring()
///     }
///
///     override func viewWillDisappear(_ animated: Bool) {
///         super.viewWillDisappear(animated)
///         orientationMonitor.stopMonitoring()
///     }
/// }
/// ```
protocol OrientationMonitor: AnyObject {
    /// Represents the most recent known device orientation for a subscriber.
    ///
    /// This property reflects the current orientation state as detected or provided by
    /// the `OrientationMonitor`. It serves as the reference orientation used to
    /// calculate transitions, rotation angles, and visual adjustments when new
    /// orientation updates are received.
    ///
    /// Implementations of this property should ensure it always reflects the
    /// **last applied orientation**, whether derived from sensors, the system, or
    /// manually set values. When a new `DeviceOrientationInfo` arrives, this value
    /// should be updated before handling the rotation logic in `didReceive(_:)`.
    var currentOrientation: DeviceOrientation { get }

    /// Returns an asynchronous sequence that produces `DeviceOrientation` events
    /// originating from the specified source.
    ///
    /// This method provides a unified, consumer-friendly interface for observing
    /// orientation changes without exposing the underlying emitter or its internal
    /// sequence type. The returned value conforms to `AsyncSequence`, allowing the
    /// caller to iterate orientation updates using `for await` syntax.
    func orientationUpdates(from type: MonitoringType) -> AsyncStream<DeviceOrientation>

    /// Begins monitoring device orientation changes.
    ///
    /// This method starts the orientation detection process and begins calling the
    /// `updateHandler` closure whenever the device orientation changes.
    func startMonitoring()

    /// Stops monitoring device orientation changes.
    ///
    /// This method stops the orientation detection process and ceases calling the
    /// `updateHandler` closure.
    func stopMonitoring()
}

extension OrientationMonitor {
    /// Returns an asynchronous sequence that produces `DeviceOrientation` events
    /// originating from the specified source.
    ///
    /// This method provides a unified, consumer-friendly interface for observing
    /// orientation changes without exposing the underlying emitter or its internal
    /// sequence type. The returned value conforms to `AsyncSequence`, allowing the
    /// caller to iterate orientation updates using `for await` syntax.
    func orientationUpdates() -> AsyncStream<DeviceOrientation> {
        orientationUpdates(from: .all)
    }
}
