//
//  TruvideoSdkVideoRequestBuilderImplementation.swift
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
        let localRequestStatus: LocalVideoRequest.Status
        switch status {
        case .idle:
            localRequestStatus = .idle
        case .error:
            localRequestStatus = .error
        case .complete:
            localRequestStatus = .completed
        case .cancelled:
            localRequestStatus = .cancelled
        case .processing:
            localRequestStatus = .processing
        }
        let localRequests = try? store.getRequests(withStatus: localRequestStatus)
        return localRequests?.compactMap(map) ?? []
    }
    
    func streamRequests(
        withStatus status: TruvideoSdkVideoRequest.Status?
    ) -> AnyPublisher<[TruvideoSdkVideoRequest], Never> {
        
        let requests: AnyPublisher<[LocalVideoRequest], Never>
        
        if let status {
            requests = store.streamVideos(withStatus: status)
        } else {
            requests = store.streamVideos()
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
        let requestStatus: TruvideoSdkVideoRequest.Status
        switch localRequest.status {
        case .idle:
            requestStatus = .idle
        case .error:
            requestStatus = .error
        case .completed:
            requestStatus = .complete
        case .cancelled:
            requestStatus = .cancelled
        case .processing:
            requestStatus = .processing
        }
        let requestType: TruvideoSdkVideoRequest.`Type`
        switch localRequest.type {
        case .concat:
            requestType = .concat
        case .merge:
            requestType = .merge
        case .encode:
            requestType = .encode
        }
        let engine: TruvideoSdkVideoRequestEngine
        switch requestType {
        case .merge:
            engine = mergeEngine
        case .encode:
            engine = encodingEngine
        case .concat:
            engine = concatEngine
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
               let frameRate = TruvideoSdkVideoFrameRate(rawValue: requestFrameRate)
            {
                mergeData = .init(
                    videos: localRequest.inputFiles.map { $0.path },
                    width: serializedMergeData?.width,
                    height: serializedMergeData?.height,
                    framesRate: frameRate,
                    videoTracks: serializedMergeData?.videoTracks ?? [],
                    audioTracks: serializedMergeData?.audioTracks ?? []
                )
            }
        case .concat:
            concatData = .init(videos: localRequest.inputFiles.map { $0.path })
        case .encode:
            let serializedEncodingData: TruvideoSdkVideoRequest.VideoEncodingData.SerializableEncodingData? = decode(
                json: localRequest.rawData
            )
            if
                let inputFile = localRequest.inputFiles.first?.path,
                let requestFrameRate = serializedEncodingData?.framesRate,
                let frameRate = TruvideoSdkVideoFrameRate(rawValue: requestFrameRate)
            {
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
    
    private func decode<T:Codable>(json: String?) -> T? {
        guard let json else { return nil }
        return try? JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
