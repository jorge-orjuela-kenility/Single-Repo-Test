//
//  TruvideoSdkVideoAppDelegate.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 1/2/25.
//

import Foundation
import UIKit

@objc public protocol TruvideoSdkVideoAppDelegate: NSObjectProtocol, UIApplicationDelegate {
    @objc var orientationLock: UIInterfaceOrientationMask { get set }

    @objc func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask
}
