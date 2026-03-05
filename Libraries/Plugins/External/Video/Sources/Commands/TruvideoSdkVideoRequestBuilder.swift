//
//  TruvideoSdkVideoRequestBuilder.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 26/2/24.
//

import Combine

final class TruvideoSdkVideoRequestBuilder {
    private let store: VideoStore
    private let mergeEngine: TruvideoSdkVideoMergeEngine
    private let concatEngine: TruvideoSdkVideoConcatEngine
    private let encodingEngine: TruvideoSdkVideoRequestEngine
    private let credentialsManager: TruvideoCredentialsManager

    init(
        store: VideoStore,
        mergeEngine: TruvideoSdkVideoMergeEngine,
        concatEngine: TruvideoSdkVideoConcatEngine,
        encodingEngine: TruvideoSdkVideoVideoEncoderEngine,
        credentialsManager: TruvideoCredentialsManager = TruvideoCredentialsManagerImp()
    ) {
        self.store = store
        self.mergeEngine = mergeEngine
        self.concatEngine = concatEngine
        self.encodingEngine = encodingEngine
        self.credentialsManager = credentialsManager
    }

    func getRequestsByStatus(status: TruvideoSdkVideoRequest.Status) throws -> [TruvideoSdkVideoRequest] {
        guard credentialsManager.isUserAuthenticated() else {
            throw TruvideoSdkVideoError.userNotAuthenticated
        }
        let localRequestStatus: LocalVideoRequest.Status = switch status {
        case .idle:
            .idle
        case .error:
            .error
        case .complete:
            .completed
        case .cancelled:
            .cancelled
        case .processing:
            .processing
        }
        let localRequests = try? store.getRequests(withStatus: localRequestStatus)
        return localRequests?.compactMap(map) ?? []
    }

    func streamRequests(
        withStatus status: TruvideoSdkVideoRequest.Status?
    ) -> AnyPublisher<[TruvideoSdkVideoRequest], Never> {
        let requests: AnyPublisher<[LocalVideoRequest], Never> = if let status {
            store.streamVideos(withStatus: status)
        } else {
            store.streamVideos()
        }

        return requests.map { $0.map(self.map) }
            .eraseToAnyPublisher()
    }

    func streamVideoRequest(withId id: UUID) throws -> AnyPublisher<TruvideoSdkVideoRequest, Never> {
        try store.streamVideo(with: id)
            .map(map)
            .eraseToAnyPublisher()
    }

    func deleteRequest(withId id: UUID) throws {
        try store.deleteRequest(withId: id)
    }

    func deleteRequests() throws {
        try store.deleteRequests()
    }

    // MARK: - Private methods

    private func map(localRequest: LocalVideoRequest) -> TruvideoSdkVideoRequest {
        let requestStatus: TruvideoSdkVideoRequest.Status = switch localRequest.status {
        case .idle:
            .idle
        case .error:
            .error
        case .completed:
            .complete
        case .cancelled:
            .cancelled
        case .processing:
            .processing
        }
        let requestType: TruvideoSdkVideoRequest.`Type` = switch localRequest.type {
        case .concat:
            .concat
        case .merge:
            .merge
        case .encode:
            .encode
        }
        let engine: TruvideoSdkVideoRequestEngine = switch requestType {
        case .merge:
            mergeEngine
        case .encode:
            encodingEngine
        case .concat:
            concatEngine
        }
        let additionalData = getAdditionalData(localRequest: localRequest)
        return .init(
            id: localRequest.id,
            type: requestType,
            status: requestStatus,
            output: localRequest.output,
            createdAt: localRequest.createdAt,
            updatedAt: localRequest.updatedAt,
            encodingData: additionalData.encodingData,
            mergeData: additionalData.mergeData,
            concatData: additionalData.concatData,
            errorMessage: localRequest.error,
            outputPath: localRequest.outputPath,
            engine: engine
        )
    }

    private func getAdditionalData(localRequest: LocalVideoRequest) -> (
        mergeData: TruvideoSdkVideoRequest.VideoMergeData?,
        concatData: TruvideoSdkVideoRequest.VideoConcatData?,
        encodingData: TruvideoSdkVideoRequest.VideoEncodingData?
    ) {
        var mergeData: TruvideoSdkVideoRequest.VideoMergeData?
        var concatData: TruvideoSdkVideoRequest.VideoConcatData?
        var encodingData: TruvideoSdkVideoRequest.VideoEncodingData?

        switch localRequest.type {
        case .merge:
            let serializedMergeData: TruvideoSdkVideoRequest.VideoMergeData.SerializableMergeData? = decode(
                json: localRequest.rawData
            )
            if let requestFrameRate = serializedMergeData?.framesRate,
               let frameRate = TruvideoSdkVideoFrameRate(rawValue: requestFrameRate) {
                mergeData = .init(
                    videos: localRequest.inputFiles.map(\.path),
                    width: serializedMergeData?.width,
                    height: serializedMergeData?.height,
                    framesRate: frameRate,
                    videoTracks: serializedMergeData?.videoTracks ?? [],
                    audioTracks: serializedMergeData?.audioTracks ?? []
                )
            }
        case .concat:
            concatData = .init(videos: localRequest.inputFiles.map(\.path))
        case .encode:
            let serializedEncodingData: TruvideoSdkVideoRequest.VideoEncodingData.SerializableEncodingData? = decode(
                json: localRequest.rawData
            )
            if
                let inputFile = localRequest.inputFiles.first?.path,
                let requestFrameRate = serializedEncodingData?.framesRate,
                let frameRate = TruvideoSdkVideoFrameRate(rawValue: requestFrameRate) {
                encodingData = .init(
                    inputFileURL: inputFile,
                    width: serializedEncodingData?.width,
                    height: serializedEncodingData?.height,
                    videoTracks: serializedEncodingData?.videoTracks ?? [],
                    audioTracks: serializedEncodingData?.audioTracks ?? [],
                    framesRate: frameRate
                )
            }
        }

        return (mergeData, concatData, encodingData)
    }

    private func decode<T: Codable>(json: String?) -> T? {
        guard let json else { return nil }
        return try? JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
