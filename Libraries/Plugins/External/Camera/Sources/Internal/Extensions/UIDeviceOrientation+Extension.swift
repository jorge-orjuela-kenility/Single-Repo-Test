//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import UIKit

extension UIDeviceOrientation {
    /// Determines whether the current device orientation is supported by the application.
    ///
    /// This computed property checks if the current `UIDeviceOrientation` is supported by the
    /// application by comparing it against the supported interface orientations. It uses a
    /// sophisticated approach to determine the supported orientations by first checking the
    /// active window scene, and falling back to the bundle's Info.plist configuration.
    var isSupported: Bool {
        var supportedOrientations = Bundle.main.supportedOrientations
        let scene = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        if let window = scene?.windows.first {
            supportedOrientations = UIApplication.shared.supportedInterfaceOrientations(for: window)
        }

        return switch self {
        case .landscapeLeft:
            supportedOrientations.contains(.landscapeRight)

        case .landscapeRight:
            supportedOrientations.contains(.landscapeLeft)

        case .portrait:
            supportedOrientations.contains(.portrait)

        default:
            false
        }
    }

    // MARK: - Initializer

    /// Creates an orientation instance from an `AVCaptureVideoOrientation`.
    ///
    /// This initializer converts an `AVCaptureVideoOrientation` to the corresponding
    /// orientation value, handling the landscape orientation mapping where left and right
    /// are swapped. It provides a safe conversion with a default fallback for unknown
    /// orientation values.
    ///
    /// - Parameter orientation: The `AVCaptureVideoOrientation` to convert from
    init(from orientation: AVCaptureVideoOrientation) {
        switch orientation {
        case .landscapeLeft:
            self = .landscapeRight

        case .landscapeRight:
            self = .landscapeLeft

        case .portrait:
            self = .portrait

        case .portraitUpsideDown:
            self = .portraitUpsideDown

        @unknown default:
            self = .portrait
        }
    }
}
