//
//  FFMPEGCommandExecutor.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 5/12/23.
//

import Foundation

protocol FFMPEGCommandExecutor {
    func cancelCommandExecution(sessionId: Int)
    @discardableResult
    func executeFFMPEGCommand(
        _ command: String,
        onUpdateSessionId: ((Int) -> Void)?
    ) async throws -> Result<Void, Error>

    @discardableResult
    func executeFFMPEGProbeCommand(_ command: String) async throws -> ExecutionResult

    func getMediaInformation(_ url: URL) async throws -> TruvideoSdkVideoInformation
}

extension FFMPEGCommandExecutor {
    @discardableResult
    func executeFFMPEGCommand(
        _ command: String,
        onUpdateSessionId: ((Int) -> Void)? = nil
    ) async throws -> Result<Void, Error> {
        try await executeFFMPEGCommand(command, onUpdateSessionId: onUpdateSessionId)
    }
}
