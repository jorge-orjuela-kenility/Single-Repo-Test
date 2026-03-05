//
//  MockVideoStore.swift
//  TruvideoSdkVideoTests
//
//  Created by Luis Francisco Piura Mejia on 23/2/24.
//

import Combine
@testable import TruvideoSdkVideo

final class MockVideoStore: VideoStore {
    var request: LocalVideoRequest?
    var status: TruvideoSdkVideo.TruvideoSdkVideoRequest.Status?
    func resetPendingRequests() {}
    private var localRequests = [LocalVideoRequest]()

    func insert(request: LocalVideoRequest) throws {
        localRequests.append(request)
    }

    func updateRequest(withId id: UUID, data: TruvideoSdkVideo.UpdateRequestData) throws {
        var request = localRequests.first { $0.id == id }
        let index = localRequests.firstIndex { $0.id == id }
        for field in data.fields {
            if case let .error(value) = field {
                request?.error = value
            }
            if case let .processId(value) = field {
                request?.processId = value
            }
            if case let .status(value) = field {
                request?.status = value
            }
        }
        if let request, let index {
            localRequests[index] = request
        }
    }

    func deleteRequest(withId id: UUID) throws {
        localRequests.removeAll { $0.id == id }
    }

    func getRequest(withId id: UUID) throws -> LocalVideoRequest? {
        localRequests.first { $0.id == id }
    }

    func getRequests(withStatus status: LocalVideoRequest.Status) throws -> [LocalVideoRequest] {
        localRequests.filter { $0.status == status }
    }

    func streamVideo(with id: UUID) throws -> AnyPublisher<LocalVideoRequest, Never> {
        if let request = localRequests.first(where: { $0.id == id }) {
            Just(request)
                .eraseToAnyPublisher()
        } else {
            Empty()
                .eraseToAnyPublisher()
        }
    }

    func streamVideos() -> AnyPublisher<[LocalVideoRequest], Never> {
        Just(localRequests)
            .eraseToAnyPublisher()
    }

    func streamVideos(withStatus status: TruvideoSdkVideo.TruvideoSdkVideoRequest
        .Status) -> AnyPublisher<[LocalVideoRequest], Never> {
        self.status = status

        return Just(localRequests)
            .eraseToAnyPublisher()
    }
}
