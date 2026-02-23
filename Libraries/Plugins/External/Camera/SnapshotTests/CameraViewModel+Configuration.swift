//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
internal import Telemetry
import TruvideoSdk
import UIKit
import Utilities

@testable import TruvideoSdkCamera

extension CameraViewModel {
    convenience init(
        audioDevice: AudioDevice = AudioDeviceMock(),
        videoDevice: VideoDevice = VideoDeviceMock(),
        configuration: TruvideoSdkCameraConfiguration,
        truVideoSdk: TruVideoSDK,
        onComplete: @escaping (TruvideoSdkCameraResult) -> Void,
        state: CameraViewModelConfiguration
    ) {
        self.init(
            configuration: configuration,
            audioDevice: audioDevice,
            truVideoSdk: truVideoSdk,
            videoDevice: videoDevice,
            onComplete: onComplete
        )

        self.isCaptureInFlight = state.isCaptureInFlight
        self.lastPhotoCaptureUptime = state.lastPhotoCaptureUptime
        self.mediasTaken = state.mediasTaken
        self.photosTaken = state.photosTaken
        self.presets = state.presets
        self.allowsHitTesting = state.allowsHitTesting
        self.isAuthorized = state.isAuthorized
        self.isTorchAvailable = state.isTorchAvailable ?? !UIDevice.current.isPad
        self.isTorchEnabled = state.isTorchEnabled
        self.isSnackbarPresented = state.isSnackbarPresented
        self.lastZoomFactor = state.lastZoomFactor
        self.remainingTime = state.remainingTime
        self.requiresConfirmation = state.requiresConfirmation
        self.timeRecorded = state.timeRecorded
        self.selectedPreset = state.selectedPreset
        self.state = state.state
        self.zoomFactors = state.zoomFactors
        self.zoomFactor = state.zoomFactor
        self.medias = state.medias

        if let orientation = configuration.orientation {
            self.orientationDidUpdate(to: orientation.deviceOrientation)
        }
    }
}
