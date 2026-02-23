//
//  UIInterfaceOrientationMask+title.swift
//  TruvideoSdkCamera
//
//  Created by Victor Arana on 3/26/25.
//

import UIKit

extension UIInterfaceOrientationMask {
    var title: String {
        switch self {
        case .portrait:
            "PORTRAIT"
        case .portraitUpsideDown:
            "PORTRAIT-UPSIDE-DOWN"
        case .landscapeLeft:
            "LANDSCAPE-LEFT"
        case .landscapeRight:
            "LANDSCAPE-RIGHT"
        default:
            "UNKNOWN"
        }
    }

    var deviceOrientation: UIDeviceOrientation {
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
