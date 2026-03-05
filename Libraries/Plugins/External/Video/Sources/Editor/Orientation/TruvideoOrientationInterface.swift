//
//  TruvideoOrientationInterface.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 1/2/25.
//

import Combine
import UIKit

public protocol TruvideoOrientationInterface {
    func lockToTruvideoOrientation()

    func unlockAppOrientation()

    func configureTruvideoSdkAppDelegate(_ appDelegate: TruvideoSdkVideoAppDelegate)
}
