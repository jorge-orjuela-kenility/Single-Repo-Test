//
//  TruvideoSdkVideo.swift
//  TruvideoSdkNoiseCancelling
//
//  Created by Luis Francisco Piura Mejia on 17/10/23.
//

import Combine

public let TruvideoSdkVideo: TruvideoSdkVideoInterface & NSTruvideoSdkVideoInterface = TruvideoSdkVideoInterfaceImp()

@objc public class TruvideoSdkVideoProvider: NSObject {
    @objc public static let shared: NSTruvideoSdkVideoInterface = TruvideoSdkVideo
}

/// Interface to access the `TruvideoSdkNoiseCancelling` functionalities
public protocol TruvideoSdkVideoInterface {
    func getVideoInformation(
        input: TruvideoSdkVideoFile
    ) async throws -> TruvideoSdkVideoInformation

    /// Engine to perform noise cancellation actions
    var engine: TruvideoSdkVideoNoiseCancellationEngine { get }

    func generateThumbnail(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor,
        position: TimeInterval,
        width: Int?,
        height: Int?
    ) async throws -> TruvideoSdkVideoThumbnailResult

    func canConcat(input: [TruvideoSdkVideoFile]) async throws -> Bool

    func MergeBuilder(
        input: [TruvideoSdkVideoFile],
        output: TruvideoSdkVideoFileDescriptor
    ) -> MergeBuilder

    func ConcatBuilder(
        input: [TruvideoSdkVideoFile],
        output: TruvideoSdkVideoFileDescriptor
    ) -> ConcatBuilder

    func EncodingBuilder(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor
    ) -> EncodingBuilder

    func streamRequests(
        withStatus status: TruvideoSdkVideoRequest.Status?
    ) -> AnyPublisher<[TruvideoSdkVideoRequest], Never>

    func streamRequest(withId id: UUID) throws -> AnyPublisher<TruvideoSdkVideoRequest, Never>

    func deleteRequest(withId id: UUID) throws

    func deleteRequests() throws
}

@objc public protocol NSTruvideoSdkVideoInterface {
    @objc func getRequests(withStatus status: TruvideoSdkVideoRequest.Status) throws -> [TruvideoSdkVideoRequest]

    @objc func configureTruvideoSdkAppDelegate(_ appDelegate: TruvideoSdkVideoAppDelegate)

    @objc func getVideoInformationWithCompletion(
        _ input: TruvideoSdkVideoFile,
        completion: @escaping (TruvideoSdkVideoInformation?, NSError?) -> Void
    )

    @objc func generateThumbnailWithCompletion(
        _ input: TruvideoSdkVideoFile,
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor,
        position: NSNumber,
        width: NSNumber?,
        height: NSNumber?,
        completion: @escaping (TruvideoSdkVideoThumbnailResult?, NSError?) -> Void
    )

    @objc func canConcatWithCompletion(
        _ input: [TruvideoSdkVideoFile],
        completion: @escaping (NSNumber?, NSError?) -> Void
    )

    @objc func MergeBuilder(
        input: [TruvideoSdkVideoFile],
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor
    ) -> MergeBuilder

    @objc func ConcatBuilder(
        input: [TruvideoSdkVideoFile],
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor
    ) -> ConcatBuilder

    @objc func EncodingBuilder(
        input: TruvideoSdkVideoFile,
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor
    ) -> EncodingBuilder
}

extension TruvideoSdkVideoInterface {
    public func streamRequests(
        withStatus status: TruvideoSdkVideoRequest.Status? = nil
    ) -> AnyPublisher<[TruvideoSdkVideoRequest], Never> {
        streamRequests(withStatus: status)
    }

    func generateThumbnail(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor,
        position: TimeInterval = 1000,
        width: Int? = nil,
        height: Int? = nil
    ) async throws -> TruvideoSdkVideoThumbnailResult {
        try await generateThumbnail(input: input, output: output, position: position, width: width, height: height)
    }

    func deleteRequest(withId id: UUID) throws {
        try deleteRequest(withId: id)
    }

    func deleteRequests() throws {
        try deleteRequests()
    }
}

protocol TruvideoSdkVideoEditor {
    func edit(video: TruvideoSdkVideoEditorInput) async throws -> TruvideoSdkVideoEditorResult
    func getThumbnailForVideo(
        at: URL,
        interval: TimeInterval,
        width: Int?,
        height: Int?
    ) async throws -> URL
}

struct TruvideoSdkVideoEditorInput {
    let videoURL: URL
    let outputURL: URL
    let startPosition: TimeInterval
    let endPosition: TimeInterval
    let rotationAngle: Int
    let volumen: Float

    init(
        videoURL: URL,
        outputURL: URL,
        startPosition: TimeInterval,
        endPosition: TimeInterval,
        rotationAngle: Int,
        volumen: Float
    ) {
        self.videoURL = videoURL
        self.outputURL = outputURL
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.rotationAngle = rotationAngle
        self.volumen = volumen
    }
}

/// Result for the trimming action
@objc public class TruvideoSdkVideoEditorResult: NSObject {
    @objc public let editedVideoURL: URL?

    init(editedVideoURL: URL?) {
        self.editedVideoURL = editedVideoURL
    }
}

public protocol TruvideoSdkVideoNoiseCancellationEngine {
    /// Loads and process the audio from the given file performing the noise cancellation
    /// process and returns a temporal url for the new generated file.
    ///
    /// - Parameter fileURL: The origin of the audio file to be processed.
    /// - Returns: The destination url of the new generated.
    func clearNoiseForFile(input: TruvideoSdkVideoFile, output: TruvideoSdkVideoFileDescriptor) async throws
        -> TruvideoSdkVideoNoiseCancellationResult
}

/// The result of the noise cancel
public struct TruvideoSdkVideoNoiseCancellationResult {
    /// URL of the clean file
    public let fileURL: URL
}

public enum TruvideoSdkVideoFrameRate: String {
    case twentyFourFps = "24"
    case twentyFiveFps = "25"
    case thirtyFps = "30"
    case fiftyFps = "50"
    case sixtyFps = "60"
    case unknown = "0"

    static func getValue(from string: String) -> TruvideoSdkVideoFrameRate {
        switch string {
        case "24/1", "24000/1001":
            .twentyFourFps
        case "25/1", "25000/1001":
            .twentyFiveFps
        case "30/1", "30000/1001":
            .thirtyFps
        case "50/1", "50000/1001":
            .fiftyFps
        case "60/1", "60000/1001":
            .sixtyFps
        default:
            .unknown
        }
    }
}

/// The result of the thumbnail generation
@objc public class TruvideoSdkVideoThumbnailResult: NSObject {
    /// URL of the generated thumbnail
    @objc public let generatedThumbnailURL: URL

    init(generatedThumbnailURL: URL) {
        self.generatedThumbnailURL = generatedThumbnailURL
    }
}
