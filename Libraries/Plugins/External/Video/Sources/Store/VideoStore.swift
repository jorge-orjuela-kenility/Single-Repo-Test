//
//  VideoStore.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 21/2/24.
//

import Combine

protocol VideoStore {
    func insert(request: LocalVideoRequest) throws
    func updateRequest(
        withId id: UUID,
        data: UpdateRequestData
    ) throws
    func deleteRequest(withId id: UUID) throws
    func deleteRequests() throws
    func getRequest(withId id: UUID) throws -> LocalVideoRequest?
    func getRequests(withStatus status: LocalVideoRequest.Status) throws -> [LocalVideoRequest]
    func resetPendingRequests()
    func streamVideo(with id: UUID) throws -> AnyPublisher<LocalVideoRequest, Never>
    func streamVideos() -> AnyPublisher<[LocalVideoRequest], Never>
    func streamVideos(withStatus status: TruvideoSdkVideoRequest.Status) -> AnyPublisher<[LocalVideoRequest], Never>
}

struct UpdateRequestData {
    enum Field: Hashable {
        case error(value: String?)
        case status(value: LocalVideoRequest.Status)
        case processId(value: String?)
    }

    var fields = Set<Field>()
}
