//
//  TruvideoSdkVideoEditorImplementationTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 14/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class TruvideoSdkVideoEditorImplementationTests: XCTestCase {
    func test_editor_throwsUserNotAuthenticated_whenUserIsNotAuthenticated() async {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: false)
        )

        await assertError(
            expectedError: .userNotAuthenticated,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: URL(string: "any-url.mov")!,
                        outputURL: URL(string: "any-url.mov")!,
                        startPosition: 0,
                        endPosition: 0,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
    }

    func test_editor_throwsVideoNotFound_whenUserPassedFileDoesNotExist() async {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        await assertError(
            expectedError: .notFoundVideo,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: URL(string: "file://any-url.mov")!,
                        outputURL: URL(string: "file://any-url.mov")!,
                        startPosition: 0,
                        endPosition: 0,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
    }

    func test_editor_throwsInvalidFile_whenUserPassedFileIsNotAVideo() async {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        let imageURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "png")
        addURLForRemoval(imageURL)
        let image = UIImage.make(withColor: .black)
        FileManager.default.createFile(atPath: imageURL.path, contents: image.pngData()!)

        await assertError(
            expectedError: .invalidFile,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: imageURL,
                        outputURL: URL(string: "any-url.mov")!,
                        startPosition: 0,
                        endPosition: 0,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
    }

    func test_editor_throwsInvalidTrimInterval_whenPassedIntervalsAreNotValid() async throws {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        let testVideoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        addURLForRemoval(testVideoURL)
        try await generateTestVideo(in: testVideoURL, width: 10, height: 10, duration: 3)

        await assertError(
            expectedError: .invalidTrimRange,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: testVideoURL,
                        outputURL: URL(string: "any-url.mov")!,
                        startPosition: 0,
                        endPosition: 4,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
        await assertError(
            expectedError: .invalidTrimRange,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: testVideoURL,
                        outputURL: URL(string: "any-url.mov")!,
                        startPosition: 3,
                        endPosition: 2,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
        await assertError(
            expectedError: .invalidTrimRange,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: testVideoURL,
                        outputURL: URL(string: "any-url.mov")!,
                        startPosition: 1,
                        endPosition: 1,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
        await assertError(
            expectedError: .invalidTrimRange,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: testVideoURL,
                        outputURL: URL(string: "any-url.mov")!,
                        startPosition: -1,
                        endPosition: 1,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
        await assertError(
            expectedError: .invalidTrimRange,
            commandExecutor: .init(),
            on: {
                _ = try await sut.edit(
                    video: .init(
                        videoURL: testVideoURL,
                        outputURL: URL(string: "any-url.mov")!,
                        startPosition: 1,
                        endPosition: -2,
                        rotationAngle: 0,
                        volumen: 1.0
                    )
                )
            }
        )
    }

    func test_editor_throwsTrimFailed_whenCommandExecutionFails() async throws {
        let commandExecutor = MockFFMPEGCommandExecutor()
        commandExecutor.mockedResult = .failure(TruvideoSdkVideoError.invalidFile)
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true),
            commandExecutor: commandExecutor
        )
        let testVideoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        addURLForRemoval(testVideoURL)
        try await generateTestVideo(in: testVideoURL, width: 10, height: 10, duration: 10)

        let receivedError = await errorFor(action: {
            _ = try await sut.edit(
                video: .init(
                    videoURL: testVideoURL,
                    outputURL: outputURL,
                    startPosition: 0,
                    endPosition: 4,
                    rotationAngle: 0,
                    volumen: 1.0
                )
            )
        })

        XCTAssertEqual(receivedError, .trimFailed)
        XCTAssertEqual(commandExecutor.executeCommandCallCount, 1)
    }

    func test_editor_executesCommand_whenInputsAreValid() async throws {
        let commandExecutor = MockFFMPEGCommandExecutor()
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true),
            commandExecutor: commandExecutor
        )
        let testVideoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        addURLForRemoval(testVideoURL)
        try await generateTestVideo(in: testVideoURL, width: 10, height: 10, duration: 10)

        let receivedError = await errorFor(action: {
            _ = try await sut.edit(
                video: .init(
                    videoURL: testVideoURL,
                    outputURL: outputURL,
                    startPosition: 0,
                    endPosition: 4,
                    rotationAngle: 0,
                    volumen: 1.0
                )
            )
        })

        XCTAssertNil(receivedError)
        XCTAssertEqual(commandExecutor.executeCommandCallCount, 1)
        XCTAssertFalse(commandExecutor.lastExecutedCommand.isEmpty)
    }

    func test_getThumbnail_throwsUserNotAuthenticated_whenUserIsNotAuthenticated() async {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: false)
        )

        await assertError(
            expectedError: .userNotAuthenticated,
            commandExecutor: .init(),
            on: {
                _ = try await sut.getThumbnailForVideo(at: URL(string: "any-url.mov")!, interval: 0)
            }
        )
    }

    func test_getThumbnail_throwsVideoNotFound_whenUserPassedFileDoesNotExist() async {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        await assertError(
            expectedError: .notFoundVideo,
            commandExecutor: .init(),
            on: {
                _ = try await sut.getThumbnailForVideo(at: URL(string: "file://any-url.mov")!, interval: 0)
            }
        )
    }

    func test_getThumbnail_throwsInvalidFile_whenUserPassedFileIsNotAVideo() async {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        let imageURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "png")
        addURLForRemoval(imageURL)
        let image = UIImage.make(withColor: .black)
        FileManager.default.createFile(atPath: imageURL.path, contents: image.pngData()!)

        await assertError(
            expectedError: .invalidFile,
            commandExecutor: .init(),
            on: {
                _ = try await sut.getThumbnailForVideo(at: imageURL, interval: 0)
            }
        )
    }

    func test_getThumbnail_throwsInvalidTrimInterval_whenPassedIntervalsAreNotValid() async throws {
        let commandExecutor = MockFFMPEGCommandExecutor()
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true),
            commandExecutor: commandExecutor
        )
        let testVideoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        addURLForRemoval(testVideoURL)
        try await generateTestVideo(in: testVideoURL, width: 10, height: 10, duration: 3)

        await assertError(
            expectedError: .invalidTrimRange,
            commandExecutor: .init(),
            on: {
                _ = try await sut.getThumbnailForVideo(at: testVideoURL, interval: 3.5)
            }
        )
        await assertError(
            expectedError: .invalidTrimRange,
            commandExecutor: .init(),
            on: {
                _ = try await sut.getThumbnailForVideo(at: testVideoURL, interval: 3.1)
            }
        )
        XCTAssertEqual(commandExecutor.executeCommandCallCount, 0)
    }

    func test_getThumbnail_throwsTrimFailed_whenCommandExecutionFails() async throws {
        let commandExecutor = MockFFMPEGCommandExecutor()
        commandExecutor.mockedResult = .failure(TruvideoSdkVideoError.invalidFile)
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true),
            commandExecutor: commandExecutor
        )
        let testVideoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: testVideoURL, width: 10, height: 10, duration: 10)
        addURLForRemoval(testVideoURL)

        let receivedError = await errorFor(action: {
            _ = try await sut.getThumbnailForVideo(at: testVideoURL, interval: 5)
        })

        XCTAssertEqual(receivedError, .trimFailed)
        XCTAssertEqual(commandExecutor.executeCommandCallCount, 1)
    }

    func test_thumbnail_executesCommand_whenInputsAreValid() async throws {
        let commandExecutor = MockFFMPEGCommandExecutor()
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true),
            commandExecutor: commandExecutor
        )
        let testVideoURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: testVideoURL, width: 10, height: 10, duration: 10)
        addURLForRemoval(testVideoURL)

        let receivedError = await errorFor(action: {
            _ = try await sut.getThumbnailForVideo(at: testVideoURL, interval: 2)
        })

        XCTAssertNil(receivedError)
        XCTAssertEqual(commandExecutor.executeCommandCallCount, 1)
        XCTAssertFalse(commandExecutor.lastExecutedCommand.isEmpty)
    }
}
