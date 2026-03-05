//
//  TruvideoSdkVideoInterfaceImp.swift
//  TruvideoSdkNoiseCancelling
//
//  Created by Luis Francisco Piura Mejia on 18/10/23.
//

import Combine
import CoreData
import Foundation
@_implementationOnly import shared

/// `TruvideoSdkNoiseCancelling` protocol implementation class
@objc final class TruvideoSdkVideoInterfaceImp: NSObject, TruvideoSdkVideoInterface {
    private static let storeURL = NSPersistentContainer
        .defaultDirectoryURL()
        .appendingPathComponent("video-store.sqlite")
    private static let coreDataStore = try! CoreDataTruvideoStore(
        storeURL: storeURL
    )
    private static let encoderEngine = TruvideoSdkVideoVideoEncoderEngine(
        store: coreDataStore
    )
    /// Actor that serializes noise cancellation requests (Krisp SDK crashes on concurrent use)
    private static let noiseCancellationCoordinator = NoiseCancellationCoordinator()

    /// Engine to perform the noise cancellation.
    /// Returns an actor-backed engine that queues requests instead of rejecting them.
    var engine: TruvideoSdkVideoNoiseCancellationEngine {
        ActorBackedNoiseCancellationEngine(coordinator: Self.noiseCancellationCoordinator)
    }

    var thumbnailGenerator: TruvideoSdkVideoThumbnailGenerator { TruvideoSdkVideoThumbnailGeneratorImplementation() }

    static let videosInformationGenerator = VideosInformationGenerator()

    private static let requestBuilder =
        TruvideoSdkVideoRequestBuilder(
            store: coreDataStore,
            mergeEngine: mergeEngine,
            concatEngine: concatEngine,
            encodingEngine: encoderEngine
        )

    static let mergeEngine = TruvideoSdkVideoMergeEngine(
        videosInformationGenerator: videosInformationGenerator,
        store: TruvideoSdkVideoInterfaceImp.coreDataStore
    )
    private static let concatEngine = TruvideoSdkVideoConcatEngine(
        inputValidator: concatInputValidator,
        videosInformationGenerator: videosInformationGenerator,
        store: coreDataStore
    )
    private static let concatInputValidator = ConcatInputValidator()

    override init() {
        Logger.addLog(event: .initVideo, eventMessage: .initVideoModule)
        Self.coreDataStore.resetPendingRequests()
    }

    func generateThumbnail(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor,
        position: TimeInterval,
        width: Int?,
        height: Int?
    ) async throws -> TruvideoSdkVideoThumbnailResult {
        try await thumbnailGenerator.generateThumbnail(for: .init(
            input: input,
            output: output,
            position: position,
            width: width,
            height: height
        ))
    }

    func canConcat(input: [TruvideoSdkVideoFile]) async throws -> Bool {
        let videos = input.map(\.url)
        Logger.addLog(event: .compareVideo, eventMessage: .compare(videoPaths: videos))
        return try await Self.concatInputValidator.canProcessConcatWith(videos: videos)
    }

    func MergeBuilder(
        input: [TruvideoSdkVideoFile],
        output: TruvideoSdkVideoFileDescriptor
    ) -> MergeBuilder {
        Logger.addLog(event: .createMergeBuilder, eventMessage: .createMergeBuilder)
        return .init(
            videos: input,
            output: output,
            engine: Self.mergeEngine,
            store: Self.coreDataStore
        )
    }

    func ConcatBuilder(
        input: [TruvideoSdkVideoFile],
        output: TruvideoSdkVideoFileDescriptor
    ) -> ConcatBuilder {
        Logger.addLog(event: .createConcatBuilder, eventMessage: .createConcatBuilder)
        return .init(
            videos: input,
            output: output,
            engine: Self.concatEngine,
            store: Self.coreDataStore
        )
    }

    func EncodingBuilder(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor
    ) -> EncodingBuilder {
        Logger.addLog(event: .createEncodeBuilder, eventMessage: .createEncodeBuilder)
        return .init(
            video: input,
            output: output,
            engine: Self.encoderEngine,
            store: Self.coreDataStore
        )
    }

    func getRequests(withStatus status: TruvideoSdkVideoRequest.Status) throws -> [TruvideoSdkVideoRequest] {
        Logger.addLog(event: .getAllRequest, eventMessage: .getRequestsBy(status: status))
        return try Self.requestBuilder.getRequestsByStatus(status: status)
    }

    func getVideoInformation(input: TruvideoSdkVideoFile) async throws -> TruvideoSdkVideoInformation {
        try await Self.videosInformationGenerator.getVideoInformation(video: input.url)
    }

    func streamRequests(
        withStatus status: TruvideoSdkVideoRequest.Status?
    ) -> AnyPublisher<[TruvideoSdkVideoRequest], Never> {
        Logger.addLog(event: .streamRequestWithStatus, eventMessage: .streamRequestsBy(status: status))
        return Self.requestBuilder.streamRequests(withStatus: status)
    }

    func streamRequest(withId id: UUID) throws -> AnyPublisher<TruvideoSdkVideoRequest, Never> {
        Logger.addLog(event: .streamRequestWithID, eventMessage: .streamRequest(id: id))
        return try Self.requestBuilder.streamVideoRequest(withId: id)
    }

    func deleteRequest(withId id: UUID) throws {
        try Self.requestBuilder.deleteRequest(withId: id)
    }

    func deleteRequests() throws {
        try Self.requestBuilder.deleteRequests()
    }

    func configureTruvideoSdkAppDelegate(_ appDelegate: TruvideoSdkVideoAppDelegate) {
        TruvideoSdkOrientationManager.shared.configureTruvideoSdkAppDelegate(appDelegate)
    }
}

@objc extension TruvideoSdkVideoInterfaceImp: NSTruvideoSdkVideoInterface {
    func getVideoInformationWithCompletion(
        _ input: TruvideoSdkVideoFile,
        completion: @escaping (TruvideoSdkVideoInformation?, NSError?) -> Void
    ) {
        Task {
            do {
                let result = try await getVideoInformation(input: input)
                completion(result, nil)
            } catch let error as NSError {
                completion(nil, error)
            }
        }
    }

    func generateThumbnailWithCompletion(
        _ input: TruvideoSdkVideoFile,
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor,
        position: NSNumber,
        width: NSNumber?,
        height: NSNumber?,
        completion: @escaping (TruvideoSdkVideoThumbnailResult?, NSError?) -> Void
    ) {
        Task {
            do {
                let result = try await generateThumbnail(
                    input: input,
                    output: .instantiate(with: outputPath, fileDescriptor: outputDescriptor),
                    position: position.doubleValue,
                    width: width?.intValue,
                    height: height?.intValue
                )
                completion(result, nil)
            } catch let error as NSError {
                completion(nil, error)
            }
        }
    }

    func canConcatWithCompletion(
        _ input: [TruvideoSdkVideoFile],
        completion: @escaping (NSNumber?, NSError?) -> Void
    ) {
        Task {
            do {
                let result = try await canConcat(input: input)
                completion(NSNumber(value: result), nil)
            } catch let error as NSError {
                completion(nil, error)
            }
        }
    }

    func MergeBuilder(
        input: [TruvideoSdkVideoFile],
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor
    ) -> MergeBuilder {
        MergeBuilder(input: input, output: .instantiate(with: outputPath, fileDescriptor: outputDescriptor))
    }

    func ConcatBuilder(
        input: [TruvideoSdkVideoFile],
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor
    ) -> ConcatBuilder {
        ConcatBuilder(input: input, output: .instantiate(with: outputPath, fileDescriptor: outputDescriptor))
    }

    func EncodingBuilder(
        input: TruvideoSdkVideoFile,
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor
    ) -> EncodingBuilder {
        EncodingBuilder(input: input, output: .instantiate(with: outputPath, fileDescriptor: outputDescriptor))
    }
}

// MARK: - Actor-based serialization for noise cancellation

/// Actor that serializes noise cancellation requests.
/// Requests queue up and are processed one at a time, preventing Krisp SDK crashes from concurrent access.
private actor NoiseCancellationCoordinator {
    /// Processes a noise cancellation request. Only one request runs at a time; others wait in queue.
    func process(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor
    ) async throws -> TruvideoSdkVideoNoiseCancellationResult {
        // Create a fresh engine for each operation (Krisp SDK requires full init/destroy cycle)
        let engine = TruvideoNoiseCancellationEngine()
        return try await engine.clearNoiseForFile(input: input, output: output)
    }
}

/// Engine wrapper that delegates to the actor coordinator.
/// Conforms to the public protocol while ensuring serialized access.
private final class ActorBackedNoiseCancellationEngine: TruvideoSdkVideoNoiseCancellationEngine {
    private let coordinator: NoiseCancellationCoordinator

    init(coordinator: NoiseCancellationCoordinator) {
        self.coordinator = coordinator
    }

    func clearNoiseForFile(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor
    ) async throws -> TruvideoSdkVideoNoiseCancellationResult {
        try await coordinator.process(input: input, output: output)
    }
}
