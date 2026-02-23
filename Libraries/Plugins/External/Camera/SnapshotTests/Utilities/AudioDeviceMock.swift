//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import Foundation
import TruVideoFoundation
import Utilities

@testable import TruvideoSdkCamera

class AudioDeviceMock: AudioDevice {
    // MARK: - Overridden methods

    override func configure(in session: AVCaptureSession) throws(UtilityError) {}
}
