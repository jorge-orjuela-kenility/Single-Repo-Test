//
//  XCTestCase+assertError.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 14/12/23.
//

@testable import TruvideoSdkVideo
import XCTest

extension XCTestCase {
    func assertError(
        expectedError: TruvideoSdkVideoError,
        commandExecutor: MockFFMPEGCommandExecutor,
        on action: @escaping () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let receivedError = await errorFor(action: action)
        XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        XCTAssertEqual(commandExecutor.executeCommandCallCount, 0, file: file, line: line)
        XCTAssertEqual(commandExecutor.getMediaInformationCallCount, 0, file: file, line: line)
    }

    func errorFor(
        action: @escaping () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> TruvideoSdkVideoError? {
        var receivedError: TruvideoSdkVideoError?

        do {
            try await action()
        } catch {
            receivedError = error as? TruvideoSdkVideoError
        }

        return receivedError
    }
}
