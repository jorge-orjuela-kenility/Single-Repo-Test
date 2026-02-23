//
// Copyright © 2025 TruVideo. All rights reserved.
//

import XCTest

@testable import TruvideoSdkCamera

final class GalleryViewUITests: XCTestCase {
    private var app: XCUIApplication!
    private var cameraScreen: CameraScreen!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-CameraSwiftUIExamplePermissionsUITest", "CameraSwiftUIExampleUITests"]
        app.launch()
        cameraScreen = CameraScreen(app: app)
    }

    // MARK: - Gallery

    func testUCGalleryCameraOrientationUnlocked() {
        // Given, When, Then
        XCTAssertTrue(cameraScreen.openCamera.waitForExistence(timeout: 3))
        cameraScreen.openCamera.tap()
        sleep(1)

        XCTAssertTrue(cameraScreen.takePhotoButton.waitForExistence(timeout: 5))
        cameraScreen.takePhotoButton.tap()

        XCTAssertTrue(cameraScreen.mediaCountButton.waitForExistence(timeout: 3))
        cameraScreen.mediaCountButton.tap()

        XCTAssertTrue(cameraScreen.galleryView.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.galleryGrid.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.image(at: 0).waitForExistence(timeout: 3))
        cameraScreen.image(at: 0).tap()

        XCUIDevice.shared.orientation = .portrait
        sleep(1)

        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)

        XCUIDevice.shared.orientation = .landscapeRight
        sleep(1)

        XCUIDevice.shared.orientation = .portrait
        sleep(1)
    }

    func testUCGalleryDeleteFirstFile() {
        // Given, When, Then
        XCTAssertTrue(cameraScreen.openCamera.waitForExistence(timeout: 3))
        cameraScreen.openCamera.tap()
        sleep(1)

        XCTAssertTrue(cameraScreen.takePhotoButton.waitForExistence(timeout: 5))
        cameraScreen.takePhotoButton.tap()
        sleep(1)
        cameraScreen.takePhotoButton.tap()

        XCTAssertTrue(cameraScreen.mediaCountButton.waitForExistence(timeout: 3))
        cameraScreen.mediaCountButton.tap()

        XCTAssertTrue(cameraScreen.galleryView.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.galleryGrid.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.image(at: 0).waitForExistence(timeout: 3))
        cameraScreen.image(at: 0).tap()

        XCTAssertTrue(cameraScreen.closeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(cameraScreen.deleteButton.waitForExistence(timeout: 5))

        cameraScreen.deleteButton.tap()
        sleep(1)

        cameraScreen.closeButton.tap()

        cameraScreen.image(at: 0).tap()
        cameraScreen.deleteButton.tap()
        sleep(1)
    }

    func testUCGalleryDeleteLastFile() {
        // Given, When, Then
        XCTAssertTrue(cameraScreen.openCamera.waitForExistence(timeout: 3))
        cameraScreen.openCamera.tap()
        sleep(1)

        XCTAssertTrue(cameraScreen.takePhotoButton.waitForExistence(timeout: 5))
        cameraScreen.takePhotoButton.tap()
        sleep(1)
        cameraScreen.takePhotoButton.tap()

        XCTAssertTrue(cameraScreen.mediaCountButton.waitForExistence(timeout: 3))
        cameraScreen.mediaCountButton.tap()

        XCTAssertTrue(cameraScreen.galleryView.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.galleryGrid.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.secondPhoto.waitForExistence(timeout: 3))
        cameraScreen.secondPhoto.tap()

        XCTAssertTrue(cameraScreen.closeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(cameraScreen.deleteButton.waitForExistence(timeout: 5))

        cameraScreen.deleteButton.tap()
        sleep(1)

        cameraScreen.closeButton.tap()

        cameraScreen.image(at: 0).tap()
        cameraScreen.deleteButton.tap()
        sleep(1)
    }

    func testUCGalleryDeleteMediaViewer() {
        // Given, When, Then
        XCTAssertTrue(cameraScreen.openCamera.waitForExistence(timeout: 3))
        cameraScreen.openCamera.tap()
        sleep(1)

        XCTAssertTrue(cameraScreen.takePhotoButton.waitForExistence(timeout: 5))
        cameraScreen.takePhotoButton.tap()
        sleep(1)
        cameraScreen.takePhotoButton.tap()

        XCTAssertTrue(cameraScreen.mediaCountButton.waitForExistence(timeout: 3))
        cameraScreen.mediaCountButton.tap()

        cameraScreen.secondPhoto.tap()

        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)

        XCTAssertTrue(cameraScreen.closeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(cameraScreen.deleteButton.waitForExistence(timeout: 5))

        cameraScreen.deleteButton.tap()
        sleep(1)

        cameraScreen.closeButton.tap()
        sleep(1)

        XCUIDevice.shared.orientation = .portrait
        sleep(1)

        cameraScreen.image(at: 0).tap()

        XCUIDevice.shared.orientation = .landscapeRight
        sleep(1)

        cameraScreen.deleteButton.tap()
        sleep(1)
    }

    func testUCGalleryAccessAfterCapture() {
        // Given, When, Then
        XCTAssertTrue(cameraScreen.openCamera.waitForExistence(timeout: 3))
        cameraScreen.openCamera.tap()
        sleep(1)

        XCTAssertTrue(cameraScreen.takePhotoButton.waitForExistence(timeout: 5))
        cameraScreen.takePhotoButton.tap()
        XCTAssertTrue(cameraScreen.mediaCountButton.waitForExistence(timeout: 3))
        XCTAssertEqual(cameraScreen.mediaCountButton.label, "1")

        XCTAssertTrue(cameraScreen.recordVideoButton.waitForExistence(timeout: 5))
        cameraScreen.recordVideoButton.tap()
        sleep(2)
        cameraScreen.recordVideoButton.tap()

        XCTAssertTrue(cameraScreen.mediaCountButton.waitForExistence(timeout: 3))
        XCTAssertEqual(cameraScreen.mediaCountButton.label, "1, 1")

        cameraScreen.takePhotoButton.tap()
        sleep(1)

        cameraScreen.recordVideoButton.tap()
        sleep(1)
        cameraScreen.recordVideoButton.tap()
        sleep(6)

        XCTAssertEqual(cameraScreen.mediaCountButton.label, "2, 2")
        cameraScreen.mediaCountButton.tap()

        XCTAssertTrue(cameraScreen.galleryView.waitForExistence(timeout: 5))
        XCTAssertTrue(cameraScreen.galleryGrid.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(cameraScreen.galleryGrid.images.count, 0)

        cameraScreen.image(at: 0).tap()
        sleep(1)

        cameraScreen.closeButton.tap()

        cameraScreen.video(at: 1).tap()
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func testUCGalleryVideoPlaybackControls() {
        // Given, When, Then
        XCTAssertTrue(cameraScreen.openCamera.waitForExistence(timeout: 3))
        cameraScreen.openCamera.tap()
        sleep(1)

        XCTAssertTrue(cameraScreen.recordVideoButton.waitForExistence(timeout: 5))
        cameraScreen.recordVideoButton.tap()
        sleep(20)
        cameraScreen.recordVideoButton.tap()

        sleep(3)
        cameraScreen.recordVideoButton.tap()
        sleep(5)
        cameraScreen.recordVideoButton.tap()

        sleep(3)
        cameraScreen.recordVideoButton.tap()
        sleep(5)
        cameraScreen.recordVideoButton.tap()

        XCTAssertTrue(cameraScreen.mediaCountButton.waitForExistence(timeout: 20))
        cameraScreen.mediaCountButton.tap()

        XCTAssertTrue(cameraScreen.galleryView.waitForExistence(timeout: 5))
        XCTAssertTrue(cameraScreen.video(at: 0).waitForExistence(timeout: 5))
        cameraScreen.video(at: 0).tap()
        sleep(2)

        XCTAssertTrue(cameraScreen.mediaPreview.waitForExistence(timeout: 5))

        cameraScreen.mediaPreview.tap()

        XCTAssertTrue(cameraScreen.previewElapsedTime.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.previewSlider.waitForExistence(timeout: 3))
        XCTAssertTrue(cameraScreen.previewRemainingTime.waitForExistence(timeout: 3))

        cameraScreen.video(at: 0).swipeLeft()
        sleep(5)

        cameraScreen.mediaPreview.tap()
        sleep(20)

        XCTAssertTrue(cameraScreen.previewElapsedTime.waitForExistence(timeout: 7))
        XCTAssertTrue(cameraScreen.previewSlider.waitForExistence(timeout: 7))
        XCTAssertTrue(cameraScreen.previewRemainingTime.waitForExistence(timeout: 7))

        cameraScreen.video(at: 1).swipeRight()
        sleep(6)

        cameraScreen.mediaPreview.tap()
        sleep(5)

        cameraScreen.closeButton.tap()
    }
}
