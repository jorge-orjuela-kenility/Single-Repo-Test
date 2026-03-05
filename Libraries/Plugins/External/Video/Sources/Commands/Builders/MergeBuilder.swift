//
//  MergeBuilder.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 29/2/24.
//

import Foundation

public struct TruvideoSdkVideoMergeMediaEntry {
    let fileIndex: Int
    let entryIndex: Int
    
    public init(fileIndex: Int, entryIndex: Int) {
        self.fileIndex = fileIndex
        self.entryIndex = entryIndex
    }
}

public struct TruvideoSdkVideoMergeVideoTrack {
    let tracks: [TruvideoSdkVideoMergeMediaEntry]
    let width: Int?
    let height: Int?
    
    public init(tracks: [TruvideoSdkVideoMergeMediaEntry], width: Int? = nil, height: Int? = nil) {
        self.tracks = tracks
        self.width = width
        self.height = height
    }
}

public struct TruvideoSdkVideoMergeAudioTrack {
    let tracks: [TruvideoSdkVideoMergeMediaEntry]
    
    public init(tracks: [TruvideoSdkVideoMergeMediaEntry]) {
        self.tracks = tracks
    }
}

extension TruvideoSdkVideoMergeMediaEntry: Equatable, Codable {}
extension TruvideoSdkVideoMergeVideoTrack: Equatable, Codable {}
extension TruvideoSdkVideoMergeAudioTrack: Equatable, Codable {}

@objc public final class MergeBuilder: NSObject {
    private let id: UUID
    private let videos: [TruvideoSdkVideoFile]
    private let output: TruvideoSdkVideoFileDescriptor
    
    private let engine: TruvideoSdkVideoRequestEngine
    private let store: VideoStore
    
    public var width: CGFloat?
    public var height: CGFloat?
    public var framesRate: TruvideoSdkVideoFrameRate = .thirtyFps
    public var videoTracks: [TruvideoSdkVideoMergeVideoTrack] = []
    public var audioTracks: [TruvideoSdkVideoMergeAudioTrack] = []
    
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
            type: .merge,
            status: .idle,
            output: output,
            createdAt: .init(),
            updatedAt: .init(),
            mergeData: .init(
                videos: videos.map { $0.url },
                width: width,
                height: height,
                framesRate: framesRate,
                videoTracks: videoTracks,
                audioTracks: audioTracks
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
            guard let firstVideo = videos.first,
                  let outputUrl = output.url(fileExtension: firstVideo.fileExtension) else { return }
            TruvideoSdkVideoUtils.createEmptyFile(atURL: outputUrl)
            try store.insert(
                request: LocalVideoRequest(
                    id: request.id,
                    status: .idle,
                    outputPath: outputUrl,
                    output: request.output,
                    type: .merge,
                    inputFiles: request.mergeData?.videos.enumerated().map {
                        .init(path: $1, index: $0)
                    } ?? [],
                    rawData: request.mergeData?.serializable.jsonRepresentation,
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
