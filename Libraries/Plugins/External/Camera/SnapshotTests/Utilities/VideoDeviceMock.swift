//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import TruVideoFoundation
import UIKit
import Utilities

@testable import TruvideoSdkCamera

class VideoDeviceMock: VideoDevice {
    // MARK: - Overridden properties

    override var isTorchAvailable: Bool {
        !UIDevice.current.isPad
    }

    // MARK: - Overridden methods

    override func setTorchMode(_ mode: AVCaptureDevice.TorchMode) throws(UtilityError) {}
    override func configure(in session: AVCaptureSession) throws(UtilityError) {}
    override func setPosition(_ newPosition: AVCaptureDevice.Position) throws(UtilityError) {}
}
