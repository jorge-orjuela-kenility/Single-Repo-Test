//
//  VideosInformationGeneratorTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 12/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class VideosInformationGeneratorTests: XCTestCase {
    func test_throwsUserNotAuthenticatedException_whenUserIsNotAuthenticated() async throws {
        let sut = makeSUT(authenticated: false)
        let video = try await getTestVideoURL()

        await assertError(
            expectedError: .userNotAuthenticated,
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.informationGenerator.getVideoInformation(video: video) }
        )
    }

    func test_throwsInvalidFile_whenFileDoesNotExist() async throws {
        let sut = makeSUT(authenticated: true)
        let video = anyFileURL()

        await assertError(
            expectedError: .invalidInputFiles(reason: .inputContainsNonExistingFiles),
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.informationGenerator.getVideoInformation(video: video) }
        )
    }

    func test_returnsVideoInfo_whenDataIsValidAndUserIsAuthenticated() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideoURL = try await getTestVideoURL()
        let secondVideoURL = try await getTestVideoURL()
        let commandExecutor = sut.commandExecutor
        commandExecutor.mockForCallAt(
            index: 1,
            data: .fixture(
                url: secondVideoURL,
                size: .zero,
                durationMillis: 10000,
                format: "mp4",
                videoTracks: [.fixture(codec: "h265", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac", sampleRate: 10)],
                orientation: .portrait,
                videoSize: .init(width: 10, height: 10)
            )
        )

        let firstVideoInfo = try await sut.informationGenerator.getVideoInformation(video: firstVideoURL)
        let secondVideoInfo = try await sut.informationGenerator.getVideoInformation(video: secondVideoURL)

        XCTAssertTrue(firstVideoInfo.hasAudio)
        XCTAssertEqual(firstVideoInfo.audioCodec, "")
        XCTAssertEqual(firstVideoInfo.size, .zero)
        XCTAssertEqual(firstVideoInfo.videoCodec, "h264")
        XCTAssertEqual(firstVideoInfo.orientation, .landscape)

        XCTAssertTrue(secondVideoInfo.hasAudio)
        XCTAssertEqual(secondVideoInfo.audioCodec, "aac")
        XCTAssertEqual(secondVideoInfo.videoSize, .init(width: 10, height: 10))
        XCTAssertEqual(secondVideoInfo.videoCodec, "h265")
        XCTAssertEqual(secondVideoInfo.orientation, .portrait)

        XCTAssertEqual(commandExecutor.getMediaInformationCallCount, 2)
    }

    // MARK: - Helpers

    private func makeSUT(authenticated: Bool) -> (
        commandExecutor: MockFFMPEGCommandExecutor,
        informationGenerator: VideosInformationGenerator
    ) {
        let credentialsManager = TruvideoCredentialsManagerSpy(isUserAuthenticated: authenticated)
        let commandExecutor = MockFFMPEGCommandExecutor()
        let videosInformationGenerator = VideosInformationGenerator(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor
        )

        return (commandExecutor, videosInformationGenerator)
    }

    private func anyFileURL() -> URL {
        .init(string: "file://any-file.mov")!
    }
}
