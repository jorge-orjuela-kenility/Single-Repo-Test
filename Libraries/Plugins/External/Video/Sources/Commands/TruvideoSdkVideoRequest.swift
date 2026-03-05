//
//  TruvideoSdkVideoRequest.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 1/3/24.
//

@objc public final class TruvideoSdkVideoRequest: NSObject {
    public enum `Type` {
        case merge
        case encode
        case concat
    }

    @objc public enum Status: Int {
        case processing
        case error
        case cancelled
        case complete
        case idle
    }

    public struct VideoMergeData: Equatable {
        public let videos: [URL]
        public let width: CGFloat?
        public let height: CGFloat?
        public let framesRate: TruvideoSdkVideoFrameRate
        public let videoTracks: [TruvideoSdkVideoMergeVideoTrack]
        public let audioTracks: [TruvideoSdkVideoMergeAudioTrack]

        var serializable: SerializableMergeData {
            .init(
                width: width,
                height: height,
                videoTracks: videoTracks,
                audioTracks: audioTracks,
                framesRate: framesRate.rawValue
            )
        }

        struct SerializableMergeData: Codable {
            let width: CGFloat?
            let height: CGFloat?
            let videoTracks: [TruvideoSdkVideoMergeVideoTrack]
            let audioTracks: [TruvideoSdkVideoMergeAudioTrack]
            let framesRate: String
        }
    }

    public struct VideoConcatData: Equatable {
        public let videos: [URL]
    }

    public struct VideoEncodingData: Equatable {
        public let inputFileURL: URL
        public let width: CGFloat?
        public let height: CGFloat?
        public let videoTracks: [TruvideoSdkVideoEncodeVideoEntry]
        public let audioTracks: [Int]
        public let framesRate: TruvideoSdkVideoFrameRate

        var serializable: SerializableEncodingData {
            .init(
                width: width,
                height: height,
                videoTracks: videoTracks,
                audioTracks: audioTracks,
                framesRate: framesRate.rawValue
            )
        }

        struct SerializableEncodingData: Codable {
            let width: CGFloat?
            let height: CGFloat?
            let videoTracks: [TruvideoSdkVideoEncodeVideoEntry]
            let audioTracks: [Int]
            let framesRate: String
        }
    }

    @objc public class Result: NSObject {
        @objc public let videoURL: URL

        init(videoURL: URL) {
            self.videoURL = videoURL
        }
    }

    // MARK: - Public members

    public let id: UUID
    public let type: `Type`
    public let status: Status
    public let output: TruvideoSdkVideoFileDescriptor
    public let createdAt: Date
    public let updatedAt: Date
    public let errorMessage: String?
    public private(set) var encodingData: VideoEncodingData?
    public private(set) var mergeData: VideoMergeData?
    public private(set) var concatData: VideoConcatData?
    public private(set) var outputPath: URL?

    // MARK: - Private members

    private let engine: TruvideoSdkVideoRequestEngine
    private lazy var requestHander: TruvideoSdkVideoRequestHandler<TruvideoSdkVideoRequest.Result> = {
        let engine = self.engine
        let request = self
        return .init(action: {
            try await engine.process(request: request)
        })
    }()

    init(
        id: UUID,
        type: Type,
        status: Status,
        output: TruvideoSdkVideoFileDescriptor,
        createdAt: Date,
        updatedAt: Date,
        encodingData: VideoEncodingData? = nil,
        mergeData: VideoMergeData? = nil,
        concatData: VideoConcatData? = nil,
        errorMessage: String? = nil,
        outputPath: URL? = nil,
        engine: TruvideoSdkVideoRequestEngine
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.output = output
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.encodingData = encodingData
        self.mergeData = mergeData
        self.concatData = concatData
        self.errorMessage = errorMessage
        self.outputPath = outputPath
        self.engine = engine
    }

    public func process() async throws -> TruvideoSdkVideoRequest.Result {
        Logger.addLog(event: .processRequest, eventMessage: .processRequest(id: id))
        let result = try await requestHander.result
        outputPath = result.videoURL
        return result
    }

    @objc public func cancel() throws {
        Logger.addLog(event: .cancelRequest, eventMessage: .cancelRequest(id: id))
        return try engine.cancel(request: self)
    }

    @objc public func processWithCompletion(
        completion: @escaping (TruvideoSdkVideoRequest.Result?, NSError?) -> Void
    ) {
        Task {
            do {
                let result = try await self.process()
                completion(result, nil)
            } catch let error as NSError {
                completion(nil, error)
            }
        }
    }
}
