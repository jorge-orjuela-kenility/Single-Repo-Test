//
//  XCTestCase+expectMergeAction.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 23/2/24.
//

@testable import TruvideoSdkVideo
import XCTest

extension XCTestCase {
    enum MergeAction {
        case merge
        case concat
    }

    func expect(
        request: TruvideoSdkVideoRequest,
        commandExecutor: MockFFMPEGCommandExecutor,
        expectedError: TruvideoSdkVideoError?,
        firstVideo: TruvideoSdkVideoInformation,
        secondVideo: TruvideoSdkVideoInformation,
        withCommandFailure: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        if withCommandFailure {
            commandExecutor.mockedResult = .failure(NSError(domain: "Any Error", code: 0))
        }
        commandExecutor.mockForCallAt(
            url: firstVideo.url,
            data: firstVideo
        )
        commandExecutor.mockForCallAt(
            url: secondVideo.url,
            data: secondVideo
        )
        var receivedError: TruvideoSdkVideoError?
        do {
            _ = try await request.process()
        } catch {
            receivedError = error as? TruvideoSdkVideoError
            if expectedError == nil {
                XCTFail("Expected no error got \(error) instead", file: file, line: line)
            }
        }

        XCTAssertEqual(receivedError, expectedError, file: file, line: line)
    }
}
