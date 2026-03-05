//
// Copyright © 2025 TruVideo. All rights reserved.
//

import SnapshotTesting
import Testing
import UIKit

@testable import TruvideoSdkCamera

@MainActor
struct CameraSnapshotTests: SnapshotTestable {
    // MARK: - Properties

    var recordMode = false

    // MARK: - Tests

    // MARK: - Camera launch tests

    @Test
    func testThatCameraViewLaunchPortraitOrientation() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in }
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatCameraViewLaunchInLandscapeLeftOrientation() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .landscapeLeft)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in }
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeLeft)
    }

    @Test
    func testThatCameraViewLaunchInLandscapeRightOrientation() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .landscapeRight)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in }
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeRight)
    }

    // MARK: - Camera launch tests while recording

    @Test
    func testThatCameraViewLaunchInLandscapeLeftOrientationWhenRecording() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .landscapeLeft)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(state: .running)
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeLeft)
    }

    @Test
    func testThatCameraViewLaunchInLandscapeRightOrientationWhenRecording() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .landscapeRight)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(state: .running)
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeRight)
    }

    @Test
    func testThatCameraViewLaunchInPortraitOrientationWhenRecording() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .portrait)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(state: .running)
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .portrait)
    }

    // MARK: - Remaining timer tests

    @Test
    func testThatCameraViewDisplayDescendingTimerWithSingleVideoOrPictureMode() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(
            mode: .singleVideoOrPicture(videoDuration: 20),
            orientation: .landscapeRight
        )

        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in
            },
            state: .init(
                remainingTime: 5.toHMS(),
                state: .running,
                timeRecorded: 15.toHMS()
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeRight)
    }

    @Test
    func testThatCameraViewDisplayDescendingTimerWithVideoAndPictureMode() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(
            mode: .videoAndPicture(videoDuration: 20),
            orientation: .portrait
        )

        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in
            },
            state: .init(
                remainingTime: 5.toHMS(),
                state: .running,
                timeRecorded: 15.toHMS()
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .portrait)
    }

    @Test
    func testThatCameraViewDisplayDescendingTimerWithSingleVideoMode() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(
            mode: TruvideoSdkCameraMediaMode.singleVideo(videoDuration: 20),
            orientation: .landscapeRight
        )

        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in
            },
            state: .init(
                remainingTime: 19.toHMS(),
                state: .running,
                timeRecorded: 20.toHMS()
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeRight)
    }

    // MARK: - Flash Toggle Tests

    @Test
    func testThatCameraViewDisplaysActiveFlashState() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .portrait)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in
            },
            state: .init(isTorchAvailable: true, isTorchEnabled: true)
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .portrait)
    }

    @Test
    func testThatCameraViewDisplaysInactiveFlashState() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .portrait)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in
            },
            state: .init(isTorchAvailable: true, isTorchEnabled: false)
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .portrait)
    }

    @Test
    func testThatCameraViewDisplaysDisabledFlashState() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .portrait)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in
            },
            state: .init(isTorchAvailable: false)
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .portrait)
    }

    // MARK: - ExitConfirmation

    @Test
    func testThatExitConfirmationAppearsWithCapturedPhoto() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(allowsHitTesting: true, medias: [MockMediaFactory.createMockPhotoMedia()])
        )

        // When
        viewModel.onDismiss()
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatExitConfirmationAppearsWithCapturedVideo() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(allowsHitTesting: true, medias: [MockMediaFactory.createMockClipMedia(duration: 15.0)])
        )

        // When
        viewModel.onDismiss()
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatExitConfirmationAppearsWithMultipleMediaItems() async throws {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                medias: [
                    MockMediaFactory.createMockPhotoMedia(),
                    MockMediaFactory.createMockClipMedia(duration: 10.0),
                    MockMediaFactory.createMockPhotoMedia(),
                    MockMediaFactory.createMockClipMedia(duration: 5.0)
                ]
            )
        )

        // When
        viewModel.onDismiss()
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    // MARK: - Continue button Tests

    @Test
    func testThatContinueButtonIsHiddenBeforeAnyMediaCaptured() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                medias: [],
                state: .initialized
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatContinueButtonAppearsAfterFirstPhotoCaptured() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                medias: [MockMediaFactory.createMockPhotoMedia()],
                state: .initialized
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatContinueButtonAppearsAfterFirstVideoCaptured() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                medias: [MockMediaFactory.createMockClipMedia(duration: 5.0)],
                state: .initialized
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatContinueButtonIsHiddenWhileRecording() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                medias: [MockMediaFactory.createMockPhotoMedia()],
                state: .running
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatContinueButtonRemainsVisibleWithMultipleMediaItems() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                medias: [
                    MockMediaFactory.createMockPhotoMedia(),
                    MockMediaFactory.createMockClipMedia(duration: 10.0),
                    MockMediaFactory.createMockPhotoMedia()
                ],
                state: .initialized
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    // MARK: - Paused Recording State

    @Test
    func testThatCameraViewShowsPausedStateInPortraitOrientation() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration()
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                state: .paused,
                timeRecorded: 15.0.toHMS()
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut)
    }

    @Test
    func testThatCameraViewShowsPausedStateInLandscapeLeftOrientation() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .landscapeLeft)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                state: .paused,
                timeRecorded: 15.0.toHMS()
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeLeft)
    }

    @Test
    func testThatCameraViewShowsPausedStateInLandscapeRightOrientation() {
        // Given
        let configuration = TruvideoSdkCameraConfiguration(orientation: .landscapeRight)
        let truvideoSDKMock = TruvideoSDKMock()
        let viewModel = CameraViewModel(
            configuration: configuration,
            truVideoSdk: truvideoSDKMock,
            onComplete: { _ in },
            state: .init(
                allowsHitTesting: true,
                state: .paused,
                timeRecorded: 15.0.toHMS()
            )
        )

        // When
        let sut = CameraView(viewModel: viewModel)

        // Then
        assertSnapshotForAllDevices(sut, orientation: .landscapeRight)
    }
}
