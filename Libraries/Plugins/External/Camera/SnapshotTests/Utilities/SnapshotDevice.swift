//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreGraphics
import UIKit

enum SnapshotDevice {
    case iPhone16Pro
    case iPad13InchM4

    var expectedModelIdentifier: String {
        switch self {
        case .iPhone16Pro:
            "iPhone17,1"

        case .iPad13InchM4:
            "iPad16,6"
        }
    }

    var size: CGSize {
        switch self {
        case .iPhone16Pro:
            .init(width: 402, height: 874)

        case .iPad13InchM4:
            .init(width: 1_024, height: 1_366)
        }
    }

    var suffix: String {
        switch self {
        case .iPhone16Pro:
            "iPhone"

        case .iPad13InchM4:
            "iPad"
        }
    }

    var displayName: String {
        switch self {
        case .iPhone16Pro:
            "iPhone 16 Pro"

        case .iPad13InchM4:
            "iPad 13-inch M4"
        }
    }

    static var current: SnapshotDevice? {
        guard let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            return nil
        }

        switch model {
        case "iPhone17,1":
            return .iPhone16Pro

        case "iPad16,6":
            return .iPad13InchM4

        default:
            return nil
        }
    }
}
