//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
internal import Telemetry
import TruvideoSdk
import UIKit

@testable import TruvideoSdkCamera

struct CameraViewModelConfiguration {
    // MARK: - Properties

    var allowsHitTesting = false
    var aspectRatio: CGFloat = 9 / 16
    var deviceOrientation: UIDeviceOrientation = .portrait
    var isAuthorized = true
    var isCaptureInFlight = false
    var isSnackbarPresented = false
    var isTorchAvailable: Bool?
    var isTorchEnabled = false
    var lastPhotoCaptureUptime: TimeInterval = .zero
    var lastZoomFactor: CGFloat = 1
    var medias: [Media] = []
    var mediasTaken = 0
    var photosTaken = 0
    var presets: [AVCaptureSession.Preset] = [.hd1920x1080, .hd1280x720, .vga640x480]
    var remainingTime: String = 0.toHMS()
    var requiresConfirmation = false
    var selectedPreset: AVCaptureSession.Preset = .hd1280x720
    var state: RecordingState = .initialized
    var timeRecorded: String = 0.toHMS()
    var validationState: CameraViewModel.ValidationState = .initial
    var zoomFactors: [CGFloat] = [1]
    var zoomFactor: CGFloat = 1
}
