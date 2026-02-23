//
//  UIDeviceOrientation+Helpers.swift
//  TruvideoSdkCamera
//
//  Created by Victor Arana on 7/10/24.
//

import CoreImage
import Foundation
import SwiftUI

extension UIDeviceOrientation {
    /// Returns the rotation angle for the current `UIDeviceOrientation`.
    var angle: Angle? {
        switch self {
        case .landscapeLeft: Angle.degrees(90)
        case .landscapeRight: Angle.degrees(-90)
        case .portrait: Angle.degrees(0)
        case .portraitUpsideDown: Angle.degrees(180)
        default: nil
        }
    }

    var transform: CGAffineTransform {
        switch self {
        case .landscapeLeft: .identity.rotated(by: .pi / -2)
        case .landscapeRight: .identity.rotated(by: .pi / 2)
        case .portrait: .identity
        case .portraitUpsideDown: .identity.rotated(by: .pi)
        default: .identity
        }
    }

    var imageOrientation: CGImagePropertyOrientation {
        switch self {
        case .landscapeLeft: .left
        case .landscapeRight: .right
        case .portrait: .up
        case .portraitUpsideDown: .up
        default: .up
        }
    }

    var swapDimensionsForVideo: Bool {
        switch self {
        case .landscapeLeft, .landscapeRight: true
        default: false
        }
    }

    var swapDimensionsForPhoto: Bool {
        !swapDimensionsForVideo
    }

    var interfaceOrientationMask: UIInterfaceOrientationMask {
        switch self {
        case .landscapeLeft:
            .landscapeLeft
        case .landscapeRight:
            .landscapeRight
        case .portraitUpsideDown:
            .portraitUpsideDown
        default:
            .portrait
        }
    }
}
