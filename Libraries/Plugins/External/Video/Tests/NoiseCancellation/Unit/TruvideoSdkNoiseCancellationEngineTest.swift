//
//  TruvideoSdkNoiseCancellationEngineTest.swift
//  TruvideoSdkVideoTests
//
//  Created by Jose Moran on 9/12/24.
//

@testable import TruvideoSdkVideo
import XCTest

final class TruvideoSdkNoiseCancellationEngineTests: XCTestCase {
    func createVideoTemporaryURL() -> URL {
        URL(
            fileURLWithPath: UUID().uuidString,
            isDirectory: false,
            relativeTo: URL(fileURLWithPath: NSTemporaryDirectory())
        )
    }

    func test_noiseCancellationEngineProcess() async throws {
        let sut = makeSUT(isAuthenticated: true)

        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "test_video", withExtension: "mp4") else {
            XCTFail("File not found")
            return
        }

        let input = TruvideoSdkVideoFile(url: url)
        let output = TruvideoSdkVideoFileDescriptor.custom(rawPath: createVideoTemporaryURL().absoluteString)

        do {
            _ = try await sut.clearNoiseForFile(input: input, output: output)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    private func makeSUT(isAuthenticated: Bool = false) -> TruvideoNoiseCancellationEngine {
        let fileProcessor = TruvideoFileProcessor()
        let commandExecutor = FFMPEGCommandExecutorImplementation()
        let credentialsManager = TruvideoCredentialsManagerSpy(isUserAuthenticated: isAuthenticated)
        let commandGenerator = FFMPEGCommandGenerator()
        let videoValidator = TruvideoSdkVideoFileValidator()

        let sut = TruvideoNoiseCancellationEngine(
            fileProcessor: fileProcessor,
            credentialsManager: credentialsManager,
            commandGenerator: commandGenerator,
            commandExecutor: commandExecutor,
            videoValidator: videoValidator
        )

        return sut
    }
}
