//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

final class TruvideoSdkCameraOrientationImp: TruvideoSdkCameraDelegate {
    /// Shared instance used to apply orientation updates from `CameraViewFullScreenPresenter`
    static let shared = TruvideoSdkCameraOrientationImp()

    func getTruvideoSdkCameraInformation() -> TruvideoSdkCameraInformation {
        Logger.addLog(event: .getCameraInformation, eventMessage: .getCameraInformation)
        let cameraManager = CameraManager()
        return TruvideoSdkCameraInformation(
            frontCamera: TruvideoSdkCameraDevice(
                id: "0",
                lensFacing: .front,
                resolutions: [],
                withFlash: false,
                isTapToFocusEnabled: cameraManager.isTapToFocusEnabled(for: .front),
                sensorOrientation: 0
            ),
            backCamera: TruvideoSdkCameraDevice(
                id: "1",
                lensFacing: .back,
                resolutions: [],
                withFlash: true,
                isTapToFocusEnabled: cameraManager.isTapToFocusEnabled(for: .back),
                sensorOrientation: 1
            )
        )
    }
}

/// `TruvideoSdkCameraInterfaceImp` protocol implementation class
final class TruvideoSdkCameraInterfaceImp: TruvideoSdkCameraInterface, TruvideoSdkCameraEventsInterface {
    /// Variable to edit preferred app orientation
    var camera: TruvideoSdkCameraDelegate { TruvideoSdkCameraOrientationImp.shared }
    /// Events observer
    var events: TruvideoSdkCameraEventObserver { TruvideoSdkCameraEvent.events.eraseToAnyPublisher() }
}
