//
//  VideoEditorImplementationIntegrationTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 14/12/23.
//

import AVKit
@testable import TruvideoSdkVideo
import XCTest

final class VideoEditorImplementationIntegrationTests: XCTestCase {
    func test_trim_generatesEditedVideo_withValidInputs() async throws {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        let inputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: inputURL, width: 30, height: 10, duration: 15)
        addURLForRemoval(inputURL)

        let result = try await sut.edit(
            video: .init(
                videoURL: inputURL,
                outputURL: outputURL,
                startPosition: 10.25,
                endPosition: 14.9,
                rotationAngle: 0,
                volumen: 1.0
            )
        )
        guard let trimmedVideoURL = result.editedVideoURL else {
            XCTFail("Expected a trimmed video URL")
            return
        }
        addURLForRemoval(trimmedVideoURL)
        let asset = AVAsset(url: trimmedVideoURL)
        let duration = try await asset.load(.duration).seconds

        XCTAssertTrue(FileManager.default.fileExists(atPath: trimmedVideoURL.path))
        XCTAssertEqual(duration, 4.65)
    }

    func test_edit_throwsError_withInvalidInputs() async throws {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        let inputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: inputURL, width: 30, height: 10, duration: 15)
        addURLForRemoval(inputURL)

        let receivedError = await errorFor(action: {
            _ = try await sut.edit(
                video: .init(
                    videoURL: inputURL,
                    outputURL: outputURL,
                    startPosition: 18,
                    endPosition: 15,
                    rotationAngle: 0,
                    volumen: 1.0
                )
            )
        })

        XCTAssertEqual(receivedError, .invalidTrimRange)
    }

    func test_getThumbnail_generatesThumbnail_withValidInputs() async throws {
        let sut = TruvideoSdkVideoEditorImplementation(
            credentialsManager: TruvideoCredentialsManagerSpy(isUserAuthenticated: true)
        )
        let inputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: inputURL, width: 30, height: 10, duration: 15)
        addURLForRemoval(inputURL)

        let result = try await sut.getThumbnailForVideo(at: inputURL, interval: 2)
        addURLForRemoval(result)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }
}
