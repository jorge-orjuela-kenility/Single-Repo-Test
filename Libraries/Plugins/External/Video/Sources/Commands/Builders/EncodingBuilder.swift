//
//  EncodingBuilder.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 29/2/24.
//

import Foundation

public struct TruvideoSdkVideoEncodeVideoEntry {
    let entryIndex: Int
    let width: Int?
    let height: Int?

    public init(entryIndex: Int, width: Int? = nil, height: Int? = nil) {
        self.entryIndex = entryIndex
        self.width = width
        self.height = height
    }
}

extension TruvideoSdkVideoEncodeVideoEntry: Equatable, Codable {}

@objc public final class EncodingBuilder: NSObject {
    private let id: UUID
    private let video: TruvideoSdkVideoFile
    private let output: TruvideoSdkVideoFileDescriptor

    private let engine: TruvideoSdkVideoRequestEngine
    private let store: VideoStore

    public var width: CGFloat?
    public var height: CGFloat?
    public var framesRate: TruvideoSdkVideoFrameRate = .thirtyFps
    public var videoTracks: [TruvideoSdkVideoEncodeVideoEntry] = []
    public var audioTracks: [Int] = []

    init(
        video: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor,
        engine: TruvideoSdkVideoRequestEngine,
        store: VideoStore
    ) {
        let id = UUID()
        self.id = id
        self.video = video
        self.output = output
        self.engine = engine
        self.store = store
    }

    @objc public func build() -> TruvideoSdkVideoRequest {
        let request = TruvideoSdkVideoRequest(
            id: id,
            type: .encode,
            status: .idle,
            output: output,
            createdAt: .init(),
            updatedAt: .init(),
            encodingData: .init(
                inputFileURL: video.url,
                width: width,
                height: height,
                videoTracks: videoTracks,
                audioTracks: audioTracks,
                framesRate: framesRate
            ),
            engine: engine
        )
        save(request: request)
        return request
    }

    private func save(request: TruvideoSdkVideoRequest) {
        do {
            // File must exist in order to create the bookmark for the URL
            // therefore we create an empty file at outputURL so we can create the bookmark
            guard let outputUrl = output.url(fileExtension: FileExtension.mp4.rawValue) else { return }
            TruvideoSdkVideoUtils.createEmptyFile(atURL: outputUrl)
            try store.insert(
                request: LocalVideoRequest(
                    id: request.id,
                    status: .idle,
                    outputPath: outputUrl,
                    output: output,
                    type: .encode,
                    inputFiles: request.encodingData.map {
                        [LocalVideoRequestFile(path: $0.inputFileURL, index: 0)]
                    } ?? [],
                    rawData: request.encodingData?.serializable.jsonRepresentation,
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
