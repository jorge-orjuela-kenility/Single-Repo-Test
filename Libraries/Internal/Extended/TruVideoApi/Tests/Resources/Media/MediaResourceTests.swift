//
// Copyright © 2026 TruVideo. All rights reserved.
//

import DI
import Foundation
import Networking
import NetworkingTesting
import Testing
import TruVideoFoundation

@testable import TruVideoApi

struct MediaResourceTests {
    // MARK: - Private Properties

    private let session = SessionMock()
    private let dataRequest = DataRequestMock()

    // MARK: - Tests

    @Test
    func testThatMediaResourceCreateShouldReturnMediaWhenRequestSucceeds() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()
            let parameters = SaveMediaParameters(
                size: 200,
                title: "foo-bar",
                type: .image,
                url: "https://test.com",
                includeInReport: true
            )

            // When
            dependencies.session = session
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<Media, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .success(Media.mock),
                type: .networkLoad
            )
            let media = try await sut.create(parameters)

            // Then
            #expect(media.active)
            #expect(media.title == "foo-bar")
            #expect(media.type == .image)
            #expect(media.includeInReport == true)
            #expect(media.isLibrary == true)
            #expect(media.tags == ["category": "test"])
            #expect(media.thumbnailUrl == URL(string: "https://example.com/thumbnail.jpg"))
        }
    }

    @Test
    func testThatMediaResourceCreateShouldThrowErrorWhenRequestFails() async throws {
        await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()
            let parameters = SaveMediaParameters(
                size: 200,
                title: "foo-bar",
                type: .image,
                url: "https://test.com",
                includeInReport: true
            )

            // When
            dependencies.session = session
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<Media, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .failure(NetworkingError(kind: .invalidURL, failureReason: "")),
                type: .networkLoad
            )

            // Then
            await #expect {
                try await sut.create(parameters)
            } throws: { error in
                (error as? UtilityError)?.kind == .MediaResourceErrorReason.createMediaFailed
            }
        }
    }

    @Test
    func testThatMediaResourceFindShouldReturnMediaWhenMediaExists() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()
            let media = Media.mock

            // When
            dependencies.session = session
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<Media, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .success(media),
                type: .networkLoad
            )
            let result = try await sut.find(for: media.id)

            // Then
            #expect(result.id == media.id)
        }
    }

    @Test
    func testThatMediaResourceFindShouldThrowErrorWhenMediaIsNotFound() async {
        await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()
            let id = UUID()

            // Then
            dependencies.environment = .beta
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<PaginatedResponse<Media>, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .success(
                    .mock(content: [])
                ),
                type: .networkLoad
            )
            await #expect {
                try await sut.find(for: id)
            } throws: { error in
                (error as? UtilityError)?.kind == .MediaResourceErrorReason.findMediaFailed
            }
        }
    }

    @Test
    func testThatMediaResourceFindShouldThrowErrorWhenRequestFails() async {
        await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()

            // Then
            dependencies.environment = .beta
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<PaginatedResponse<Media>, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .failure(
                    NetworkingError(kind: .requestRetryFailed, failureReason: "500")
                ),
                type: .networkLoad
            )

            await #expect {
                try await sut.find(for: UUID())
            } throws: { error in
                (error as? UtilityError)?.kind == .MediaResourceErrorReason.findMediaFailed
            }
        }
    }

    @Test
    func testThatMediaResourceSearchShouldReturnResultsWhenRequestSucceeds() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()
            let media = Media.mock

            // When
            dependencies.session = session
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<PaginatedResponse<Media>, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .success(.mock(content: [media])),
                type: .networkLoad
            )
            let result = try await sut.search(with: SearchMediaParameters())

            // Then
            #expect(result != nil)
        }
    }

    @Test
    func testThatMediaResourceSearchShouldThrowErrorWhenRequestFails() async {
        await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()

            // Then
            dependencies.environment = .beta
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<PaginatedResponse<Media>, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .failure(
                    NetworkingError(kind: .requestRetryFailed, failureReason: "500")
                ),
                type: .networkLoad
            )

            await #expect {
                try await sut.search(with: SearchMediaParameters())
            } throws: { error in
                (error as? UtilityError)?.kind == .MediaResourceErrorReason.searchMediaFailed
            }
        }
    }

    @Test
    func testThatMediaResourceUpdateShouldReturnUpdatedMediaWhenRequestSucceeds() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()
            let parameters = SaveMediaParameters(
                size: 200,
                title: "foo-bar",
                type: .image,
                url: "https://test.com",
                includeInReport: true
            )
            let media = Media.mock

            // When
            dependencies.session = session
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<Media, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .success(Media.mock),
                type: .networkLoad
            )
            let result = try await sut.update(for: media.id.uuidString, with: parameters)

            // Then
            #expect(result != nil)
        }
    }

    @Test
    func testThatMediaResourceUpdateShouldThrowErrorWhenRequestFails() async throws {
        await withDependencyValues { dependencies in
            // Given
            let sut = MediaResourceImpl()
            let parameters = SaveMediaParameters(
                size: 200,
                title: "foo-bar",
                type: .image,
                url: "https://test.com",
                includeInReport: true
            )
            let media = Media.mock

            // When
            dependencies.session = session
            session.dataRequest = dataRequest
            dataRequest.mockResponse = Response<Media, NetworkingError>(
                data: Data(),
                metrics: nil,
                request: nil,
                response: nil,
                result: .failure(NetworkingError(kind: .invalidURL, failureReason: "")),
                type: .networkLoad
            )

            // Then
            await #expect {
                try await sut.update(for: media.id.uuidString, with: parameters)
            } throws: { error in
                (error as? UtilityError)?.kind == .MediaResourceErrorReason.updateMediaFailed
            }
        }
    }
}
