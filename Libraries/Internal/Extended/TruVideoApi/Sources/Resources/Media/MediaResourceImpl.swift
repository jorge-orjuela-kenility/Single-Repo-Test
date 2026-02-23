//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
import Foundation
import InternalUtilities
internal import Networking
import TruVideoFoundation
internal import Utilities

/// Defines the contract for interacting with the Media API.
///
/// This protocol abstracts the underlying networking layer and exposes a
/// high-level interface for creating, retrieving, searching, and updating
/// media resources.
public protocol MediaResource {
    /// Creates a new media resource.
    ///
    /// - Parameter parameters: The payload used to create the media, including
    ///   metadata such as title, type, URL, resolution, and flags.
    /// - Returns: The created `Media` instance returned by the backend.
    /// - Throws: `UtilityError` with a `.MediaErrorReason.createMediaFailed` kind
    ///   when the request fails, or if response decoding is unsuccessful.
    func create(_ parameters: SaveMediaParameters) async throws(UtilityError) -> Media

    /// Retrieves a single media resource by its identifier.
    ///
    /// - Parameter id: The unique identifier of the media resource.
    /// - Returns: The corresponding `Media` instance if it exists.
    /// - Throws: `UtilityError` with a `.MediaErrorReason.findMediaFailed` kind
    ///   when the request fails or the media cannot be retrieved.
    func find(for id: UUID) async throws(UtilityError) -> Media

    /// Searches for media resources using filters, sorting, and pagination.
    ///
    /// The `SearchMediaParameters` builder encapsulates both:
    /// - **Body parameters**: search filters (e.g. term, type, tags, flags).
    /// - **Query parameters**: sorting and pagination (sortBy, direction, page, size).
    ///
    /// - Parameter parameters: A builder object describing search criteria and result ordering.
    /// - Returns: A paginated list of `Media` objects wrapped in `PaginatedResponse`.
    /// - Throws: `UtilityError` with a `.MediaErrorReason.searchMediaFailed` kind
    ///   when the request fails or the response cannot be decoded.
    func search(with parameters: SearchMediaParameters) async throws(UtilityError) -> PaginatedResponse<Media>

    /// Updates an existing media resource.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the media resource to update.
    ///   - parameters: The payload containing the new media values.
    /// - Returns: The updated `Media` instance returned by the backend.
    /// - Throws: `UtilityError` with a `.MediaErrorReason.updateMediaFailed` kind
    ///   when the request fails or the response cannot be decoded.
    func update(for id: String, with parameters: SaveMediaParameters) async throws(UtilityError) -> Media
}

/// Default implementation of `MediaResource` backed by the networking layer.
public struct MediaResourceImpl: MediaResource {
    // MARK: - Dependencies

    @Dependency(\.environment)
    private var environment: Environment

    @Dependency(\.session)
    private var session: any Session

    // MARK: - Types

    /// An error type representing failures that occur when interacting with media resources.
    ///
    /// `MediaResourceError` defines the specific error conditions that may arise when
    /// requesting, retrieving, or operating on media items. Use this type to signal
    /// well-defined error scenarios within media gateways, repositories, and domain
    /// logic.
    public enum MediaResourceError: Error {
        /// The requested media item does not exist or could not be retrieved.
        case notFound
    }

    // MARK: - Initializer

    /// Creates a new instance of `MediaResourceImpl`.
    public init() {}

    // MARK: - MediaResource

    /// Creates a new media resource.
    ///
    /// - Parameter parameters: The payload used to create the media, including
    ///   metadata such as title, type, URL, resolution, and flags.
    /// - Returns: The created `Media` instance returned by the backend.
    /// - Throws: `UtilityError` with a `.MediaResourceErrorReason.createMediaFailed` kind
    ///   when the request fails, or if response decoding is unsuccessful.
    public func create(_ parameters: SaveMediaParameters) async throws(UtilityError) -> Media {
        do {
            return try await session.request(
                environment.baseURL.appending("/api/media"),
                method: .post,
                parameters: [
                    "title": parameters.title,
                    "type": parameters.type.rawValue,
                    "url": parameters.url,
                    "resolution": parameters.resolution?.rawValue,
                    "size": parameters.size,
                    "metadata": parameters.metadata?.prettify(),
                    "tags": parameters.tags,
                    "duration": parameters.duration,
                    "includeInReport": parameters.includeInReport,
                    "isLibrary": parameters.isLibrary
                ],
                encoder: .json,
                middleware: Middleware(interceptors: [AuthTokenInterceptor()], retriers: [])
            )
            .validate()
            .serializing(Media.self)
            .result
            .get()
        } catch {
            throw UtilityError(kind: .MediaResourceErrorReason.createMediaFailed, underlyingError: error)
        }
    }

    /// Retrieves a single media resource by its identifier.
    ///
    /// - Parameter id: The unique identifier of the media resource.
    /// - Returns: The corresponding `Media` instance if it exists.
    /// - Throws: `UtilityError` with a `.MediaErrorReason.findMediaFailed` kind
    ///   when the request fails or the media cannot be retrieved.
    public func find(for id: UUID) async throws(UtilityError) -> Media {
        do {
            let url = environment.baseURL.appending("/api/media/search")
            let parameters = [
                "ids": [id.uuidString.lowercased()]
            ]

            return try await session.request(
                url,
                method: .post,
                parameters: parameters,
                encoder: .json,
                middleware: Middleware(interceptors: [AuthTokenInterceptor()], retriers: [])
            )
            .validate()
            .serializing(PaginatedResponse<Media>.self)
            .result
            .get()
            .content
            .first
            .unwrap(or: MediaResourceError.notFound)
        } catch {
            throw UtilityError(kind: .MediaResourceErrorReason.findMediaFailed, underlyingError: error)
        }
    }

    /// Searches for media resources using filters, sorting, and pagination.
    ///
    /// The `SearchMediaParameters` builder encapsulates both:
    /// - **Body parameters**: search filters (e.g. term, type, tags, flags).
    /// - **Query parameters**: sorting and pagination (sortBy, direction, page, size).
    ///
    /// - Parameter parameters: A builder object describing search criteria and result ordering.
    /// - Returns: A paginated list of `Media` objects wrapped in `PaginatedResponse`.
    /// - Throws: `UtilityError` with a `.MediaResourceErrorReason.searchMediaFailed` kind
    ///   when the request fails or the response cannot be decoded.
    public func search(with parameters: SearchMediaParameters) async throws(UtilityError) -> PaginatedResponse<Media> {
        do {
            let parameters = parameters.build()

            return try await session.request(
                environment.baseURL.appending("/api/media/search?\(parameters.queryParameters)"),
                method: .post,
                parameters: parameters.bodyParameters,
                encoder: .json,
                middleware: Middleware(interceptors: [AuthTokenInterceptor()], retriers: [])
            )
            .validate()
            .serializing(PaginatedResponse<Media>.self)
            .result
            .get()
        } catch {
            throw UtilityError(kind: .MediaResourceErrorReason.searchMediaFailed, underlyingError: error)
        }
    }

    /// Updates an existing media resource.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the media resource to update.
    ///   - parameters: The payload containing the new media values.
    /// - Returns: The updated `Media` instance returned by the backend.
    /// - Throws: `UtilityError` with a `.MediaResourceErrorReason.updateMediaFailed` kind
    ///   when the request fails or the response cannot be decoded.
    public func update(for id: String, with parameters: SaveMediaParameters) async throws(UtilityError) -> Media {
        do {
            return try await session.request(
                environment.baseURL.appending("/api/media/\(id)"),
                method: .put,
                parameters: [
                    "title": parameters.title,
                    "type": parameters.type,
                    "url": parameters.url,
                    "resolution": parameters.resolution?.rawValue,
                    "size": parameters.size,
                    "metadata": parameters.metadata
                ],
                encoder: .json
            )
            .validate()
            .serializing(Media.self)
            .result
            .get()
        } catch {
            throw UtilityError(kind: .MediaResourceErrorReason.updateMediaFailed, underlyingError: error)
        }
    }
}
