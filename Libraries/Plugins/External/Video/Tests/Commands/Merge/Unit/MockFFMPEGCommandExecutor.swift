//
//  MockFFMPEGCommandExecutor.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 12/12/23.
//

import Foundation
@testable import TruvideoSdkVideo

final class MockFFMPEGCommandExecutor: FFMPEGCommandExecutor {
    private(set) var executeCommandCallCount = 0
    private(set) var getMediaInformationCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var lastExecutedCommand = ""
    var cancellationBlock: (() throws -> Void)?
    var mockedResult: Result<Void, Error> = .success(())
    var mockedProbeResult: ExecutionResult = .init(output: "path")

    private var mockedMediaInformation = [Int: TruvideoSdkVideoInformation]()
    private var mockedMediaInformationWithURL = [URL: TruvideoSdkVideoInformation]()

    func executeFFMPEGCommand(
        _ command: String,
        onUpdateSessionId: ((Int) -> Void)?
    ) async throws -> Result<Void, Error> {
        executeCommandCallCount += 1
        lastExecutedCommand = command
        onUpdateSessionId?(executeCommandCallCount)
        try cancellationBlock?()
        if case let .failure(error) = mockedResult {
            throw error
        }
        return mockedResult
    }

    @discardableResult
    func executeFFMPEGProbeCommand(_ command: String) async throws -> ExecutionResult {
        mockedProbeResult
    }

    func cancelCommandExecution(sessionId: Int) {
        mockedResult = .failure(NSError(domain: "Error", code: 0))
        cancelCallCount += 1
    }

    func getMediaInformation(_ url: URL) async throws -> TruvideoSdkVideoInformation {
        let info =
            mockedMediaInformationWithURL[url] ??
            mockedMediaInformation[getMediaInformationCallCount] ??
            defaultMediaInfo(withURL: url)
        getMediaInformationCallCount += 1
        return info
    }

    func mockForCallAt(index: Int, data: TruvideoSdkVideoInformation) {
        mockedMediaInformation[index] = data
    }

    func mockForCallAt(url: URL, data: TruvideoSdkVideoInformation) {
        mockedMediaInformationWithURL[url] = data
    }

    func resetCallsCounters() {
        executeCommandCallCount = 0
        getMediaInformationCallCount = 0
    }

    private func defaultMediaInfo(withURL url: URL) -> TruvideoSdkVideoInformation {
        TruvideoSdkVideoInformation(
            url: url,
            size: .zero,
            durationMillis: 10_000,
            format: "mp4",
            videoTracks: [.fixture(codec: "h264")],
            audioTracks: [.fixture(codec: "")],
            orientation: .landscape,
            videoSize: CGSize(width: 100, height: 200)
        )
    }
}
