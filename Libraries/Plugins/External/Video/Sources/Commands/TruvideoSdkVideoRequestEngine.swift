//
//  TruvideoSdkVideoRequestEngine.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 1/3/24.
//

protocol TruvideoSdkVideoRequestEngine {
    func process(request: TruvideoSdkVideoRequest) async throws -> TruvideoSdkVideoRequest.Result
    func cancel(request: TruvideoSdkVideoRequest) throws
}
