//
//  TruvideoSdkOrientationManager.swift
//  TruvideoSdkShared
//
//  Created by Victor Arana on 11/11/24.
//

import Combine
import UIKit

class TruvideoSdkOrientationManager: TruvideoOrientationInterface {
    static let shared = TruvideoSdkOrientationManager()

    private var previousAppOrientation: UIInterfaceOrientationMask?

    private weak var appDelegate: TruvideoSdkVideoAppDelegate?

    private var truvideoOrientationMask: UIInterfaceOrientationMask = .portrait

    func lockToTruvideoOrientation() {
        guard let appDelegate else { return }
        previousAppOrientation = appDelegate.orientationLock

        if UIDevice.current.userInterfaceIdiom == .phone {
            appDelegate.orientationLock = .portrait
        } else {
            switch UIDeviceOrientation.currentAppOrientation() {
            case .portraitUpsideDown:
                truvideoOrientationMask = .portraitUpsideDown
                appDelegate.orientationLock = .portraitUpsideDown
            case .landscapeLeft:
                truvideoOrientationMask = .landscapeLeft
                appDelegate.orientationLock = .landscapeLeft
            case .landscapeRight:
                truvideoOrientationMask = .landscapeRight
                appDelegate.orientationLock = .landscapeRight
            default:
                truvideoOrientationMask = .portrait
                appDelegate.orientationLock = .portrait
            }
        }
    }

    func unlockAppOrientation() {
        guard let appDelegate, let previousAppOrientation else { return }
        appDelegate.orientationLock = previousAppOrientation
        self.previousAppOrientation = nil
    }

    func configureTruvideoSdkAppDelegate(_ appDelegate: TruvideoSdkVideoAppDelegate) {
        self.appDelegate = appDelegate
    }
}

extension UIDeviceOrientation {
    static func currentAppOrientation() -> UIDeviceOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .portrait
        }
        let interfaceOrientation = windowScene.interfaceOrientation

        switch interfaceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}
