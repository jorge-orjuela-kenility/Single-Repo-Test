//
//  TruvideoSdkVideoRequestHandler.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 28/2/24.
//

final class TruvideoSdkVideoRequestHandler<R> {
    var result: R {
        get async throws {
            guard !isProcessing else {
                throw TruvideoSdkVideoError.operationStillsInProgress
            }
            if let previousResult {
                return previousResult
            }
            isProcessing = true
            let result = try await action()
            isProcessing = false
            previousResult = result
            return result
        }
    }

    private var isProcessing = false
    private var previousResult: R?
    private var action: () async throws -> R

    init(action: @escaping () async throws -> R) {
        self.action = action
    }
}
