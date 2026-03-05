//
//  XCTestCase+generateTestVideo.swift
//  TruvideoSdkVideoTests
//
//  Created by Victor Arana on 12/7/23.
//

import Foundation
@testable import TruvideoSdkVideo
import XCTest

extension XCTestCase {
    private struct UnexpectedTestVideoCreationError: Error {}

    func getTestVideoURL(width: Int = 20, height: Int = 20, withAudio: Bool = false) async throws -> URL {
        let testURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mov")
        try await generateTestVideo(in: testURL, width: width, height: height, withAudio: withAudio)
        addURLForRemoval(testURL)
        return testURL
    }

    func generateTestVideo(
        in outputURL: URL,
        width: Int = 20,
        height: Int = 20,
        fps: Int = 30,
        duration: TimeInterval = 3.0,
        color: String = "black",
        withAudio: Bool = false
    ) async throws {
        let commandParameters: [Any] = withAudio ?
            [
                "-f",
                "lavfi",
                "-i",
                "color=c=\(color):s=\(width)x\(height):r=\(fps):d=\(duration)",
                "-f",
                "lavfi",
                "-i",
                "\"sine=frequency=1000:duration=\(duration)\"",
                outputURL
            ]
            : [
                "-f",
                "lavfi",
                "-i",
                "color=c=\(color):s=\(width)x\(height):r=\(fps):d=\(duration)",
                outputURL
            ]
        let command = commandParameters.reduce("") { "\($0) \($1)" }

        let commandExecutor: FFMPEGCommandExecutor =
            FFMPEGCommandExecutorImplementation(transformProvider: MockVideoTransformProvider())
        do {
            try await commandExecutor.executeFFMPEGCommand(command)

            if !FileManager.default.fileExists(atPath: outputURL.path) {
                throw UnexpectedTestVideoCreationError()
            }
        } catch {
            throw UnexpectedTestVideoCreationError()
        }
    }
}
