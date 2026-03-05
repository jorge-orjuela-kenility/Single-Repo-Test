//
//  MockVideoTransformProvider.swift
//  TruvideoSdkVideo
//
//  Created by Paul Alvarez on 12/03/25.
//

@testable import TruvideoSdkVideo

class MockVideoTransformProvider: VideoTransformProvider {
    var transformToReturn: CGAffineTransform = .identity

    func getTransform(for url: URL) async throws -> CGAffineTransform {
        transformToReturn
    }
}
