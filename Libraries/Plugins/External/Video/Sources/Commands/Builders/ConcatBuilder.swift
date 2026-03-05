//
//  ConcatBuilder.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 29/2/24.
//

import Foundation

@objc public final class ConcatBuilder: NSObject {
    private let id: UUID
    private let videos: [TruvideoSdkVideoFile]
    private let output: TruvideoSdkVideoFileDescriptor
    
    private let engine: TruvideoSdkVideoRequestEngine
    private let store: VideoStore
    
    init(
        videos: [TruvideoSdkVideoFile],
        output: TruvideoSdkVideoFileDescriptor,
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore
    ) {
        let id = UUID()
        self.id = id
        self.videos = videos
        self.output = output
        self.engine = engine
        self.store = store
    }
    
    @objc public func build() throws -> TruvideoSdkVideoRequest {
        guard videos.count > 1 else { throw TruvideoSdkVideoError.invalidInputFiles(reason: .notEnoughVideos) }
        
        let request = TruvideoSdkVideoRequest(
            id: id,
            type: .concat,
            status: .idle,
            output: output,
            createdAt: .init(),
            updatedAt: .init(),
            concatData: .init(videos: videos.map { $0.url }),
            engine: engine
        )
        save(request: request)
        return request
    }
    
    private func save(request: TruvideoSdkVideoRequest) {
        do {
            // File must exist in order to create the bookmark for the URL
            // therefore we create an empty file at outputURL so we can create the bookmark
            guard let firstVideo = videos.first,
            let outputUrl = output.url(fileExtension: firstVideo.fileExtension) else { return }
            TruvideoSdkVideoUtils.createEmptyFile(atURL: outputUrl)
            try store.insert(
                request: LocalVideoRequest(
                    id: request.id,
                    status: .idle,
                    outputPath: outputUrl,
                    output: output,
                    type: .concat,
                    inputFiles: request.concatData?.videos.enumerated().map {
                        .init(path: $1, index: $0)
                    } ?? [],
                    createdAt: .init(),
                    updatedAt: .init()
                )
            )
            // Once the bookmark is created the empty file is deleted
            TruvideoSdkVideoUtils.deleteFileIfExists(atURL: outputUrl)
        } catch {
            Logger.logError(event: .insertRequest, eventMessage: .insertRequestFailed(error: error))
        }
    }
}
