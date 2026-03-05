//
//  ConcatInputValidatorTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 12/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class ConcatInputValidatorTests: XCTestCase {
    func test_throwsUserNotAuthenticatedException_whenUserIsNotAuthenticated() async {
        let sut = makeSUT(authenticated: false)

        await assertError(
            expectedError: .userNotAuthenticated,
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.inputValidator.canProcessConcatWith(videos: []) }
        )
    }

    func test_throwsInvalidFile_whenOneOrMoreFilesDoNotExist() async throws {
        let sut = makeSUT(authenticated: true)
        let videos = [anyFileURL(), anyFileURL()]

        await assertError(
            expectedError: .invalidInputFiles(reason: .inputContainsNonExistingFiles),
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.inputValidator.canProcessConcatWith(videos: videos) }
        )
    }

    func test_throwsNoEnoughFiles_whenPassingLessThanTheAmountOfNeededFiles() async throws {
        let sut = makeSUT(authenticated: true)
        let firstFile = try await getTestVideoURL()

        await assertError(
            expectedError: .invalidInputFiles(reason: .notEnoughVideos),
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.inputValidator.canProcessConcatWith(videos: [firstFile]) }
        )
    }

    func test_throwsInvalidFile_whenPassingAnEmptyList() async throws {
        let sut = makeSUT(authenticated: true)

        await assertError(
            expectedError: .invalidInputFiles(reason: .notEnoughVideos),
            commandExecutor: sut.commandExecutor,
            on: { _ = try await sut.inputValidator.canProcessConcatWith(videos: []) }
        )
    }

    func test_returnsFalse_whenUsingVideosWithDifferentConfigs() async throws {
        let sut = makeSUT(authenticated: true)
        let commandExecutor = sut.commandExecutor
        let firstVideoURL = try await getTestVideoURL()
        let secondVideoURL = try await getTestVideoURL()
        let videos = [
            firstVideoURL,
            secondVideoURL
        ]
        sut.commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h265", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac", sampleRate: 10)],
                orientation: .portrait,
                videoSize: .init(width: 10, height: 10)
            )
        )

        var canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [],
                orientation: .portrait,
                videoSize: .zero
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [],
                orientation: .landscape,
                videoSize: .init(width: 10, height: 10)
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [],
                orientation: .landscape,
                videoSize: .zero
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 0,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h265", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac", sampleRate: 10)],
                orientation: .landscape,
                videoSize: .zero
            )
        )
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h265", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "mp3", sampleRate: 10)],
                orientation: .landscape,
                videoSize: .zero
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 0,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h265", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac", sampleRate: 1)],
                orientation: .landscape,
                videoSize: .zero
            )
        )
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(codec: "h265", pixelFormat: "yuvj420p")],
                audioTracks: [.fixture(codec: "aac", sampleRate: 10)],
                orientation: .landscape,
                videoSize: .zero
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 0,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [],
                orientation: .portrait,
                videoSize: .zero
            )
        )
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture()],
                audioTracks: [],
                orientation: .portrait,
                videoSize: .init(width: 1, height: 1)
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 0,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture()],
                audioTracks: [],
                orientation: .portrait,
                videoSize: .init(width: 1, height: 1)
            )
        )
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [],
                orientation: .portrait,
                videoSize: .init(width: 1, height: 1)
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 0,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [],
                orientation: .portrait,
                videoSize: .init(width: 10, height: 10)
            )
        )
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [.fixture()],
                orientation: .portrait,
                videoSize: .init(width: 1, height: 1)
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 0,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(), .fixture()],
                audioTracks: [],
                orientation: .landscape,
                videoSize: .init(width: 1, height: 1)
            )
        )
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [],
                audioTracks: [],
                orientation: .portrait,
                videoSize: .init(width: 1, height: 1)
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)

        commandExecutor.resetCallsCounters()
        commandExecutor.mockForCallAt(
            index: 0,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture()],
                audioTracks: [.fixture()],
                orientation: .portrait,
                videoSize: .init(width: 1, height: 1)
            )
        )
        commandExecutor.mockForCallAt(
            index: 1,
            data: .init(
                url: secondVideoURL,
                size: 50000,
                durationMillis: 10000,
                format: "format_name",
                videoTracks: [.fixture(), .fixture()],
                audioTracks: [.fixture(), .fixture()],
                orientation: .portrait,
                videoSize: .init(width: 100, height: 100)
            )
        )

        canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertFalse(canProcessConcat)
    }

    func test_returnsTrue_whenUsingVideosWithEqualConfigs() async throws {
        let sut = makeSUT(authenticated: true)
        let firstVideoURL = try await getTestVideoURL()
        let secondVideoURL = try await getTestVideoURL()
        let videos = [
            firstVideoURL,
            secondVideoURL
        ]

        let canProcessConcat = try await sut.inputValidator.canProcessConcatWith(videos: videos)
        XCTAssertTrue(canProcessConcat)
    }

    // MARK: - Helpers

    private func makeSUT(authenticated: Bool) -> (
        commandExecutor: MockFFMPEGCommandExecutor,
        inputValidator: ConcatInputValidator
    ) {
        let credentialsManager = TruvideoCredentialsManagerSpy(isUserAuthenticated: authenticated)
        let commandExecutor = MockFFMPEGCommandExecutor()
        let videosInformationGenerator = VideosInformationGenerator(
            credentialsManager: credentialsManager,
            commandExecutor: commandExecutor
        )
        let sut = ConcatInputValidator(
            credentialsManager: credentialsManager,
            videosInformationGenerator: videosInformationGenerator,
            commandExecutor: commandExecutor
        )

        return (commandExecutor, sut)
    }

    private func anyFileURL() -> URL {
        .init(string: "file://any-file.mov")!
    }
}
