//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoApi
@_spi(Internal) import TruvideoSdk

/// A protocol that defines the interface for providing authentication tokens.
///
/// `AuthTokenProvider` abstracts the mechanism for retrieving authentication tokens
/// used to authorize API requests. Implementations of this protocol are responsible for
/// fetching, caching, and managing authentication tokens, which may involve:
/// - Retrieving tokens from secure storage
/// - Refreshing expired tokens
/// - Obtaining new tokens through authentication flows
///
/// This protocol is typically used in dependency injection systems to allow different
/// token retrieval strategies to be swapped without changing the consuming code.
///
/// ## Usage
///
/// ```swift
/// struct BearerTokenProvider: AuthTokenProvider {
///     func retrieveToken() async throws -> String {
///         // Retrieve token from secure storage or refresh if needed
///         return try await tokenManager.getAccessToken()
///     }
/// }
/// ```
public protocol AuthTokenProvider {
    /// Retrieves an authentication token asynchronously.
    ///
    /// This method fetches the current authentication token, which may involve:
    /// - Reading from secure storage
    /// - Refreshing an expired token
    /// - Obtaining a new token through authentication
    ///
    /// The returned token should be ready for immediate use in API requests,
    /// typically as a bearer token in the `Authorization` header.
    ///
    /// - Returns: A valid authentication token string, typically a JWT or bearer token.
    /// - Throws: An error if token retrieval fails, such as:
    ///   - Network errors when refreshing tokens
    ///   - Authentication errors when obtaining new tokens
    ///   - Storage errors when reading from secure storage
    func retrieveToken() async throws -> String?
}

/// A concrete `AuthTokenProvider` backed by `TruVideoSDK`.
///
/// `BearerTokenProvider` reads the current bearer token from `TruVideoSDK` through
/// its internal SPI surface (`authToken`). It does not perform network calls,
/// trigger refresh operations, or mutate session state.
///
/// This provider is intended for SDK-internal wiring where MediaUpload needs the
/// latest authenticated token managed by the SDK runtime.
struct BearerTokenProvider: AuthTokenProvider {
    // MARK: - Private Properties

    private let truvideoSdk: TruVideoSDK

    // MARK: - Initializer

    /// Creates a token provider backed by a `TruVideoSDK` instance.
    ///
    /// - Parameter truvideoSdk: SDK instance that exposes the current auth token.
    ///   Defaults to the shared `TruvideoSdk` instance.
    init(truvideoSdk: TruVideoSDK = TruvideoSdk) {
        self.truvideoSdk = truvideoSdk
    }

    // MARK: - AuthTokenProvider

    /// Retrieves the current bearer token from the SDK runtime.
    ///
    /// The token is returned as-is from `truvideoSdk.authToken`. This call is read-only
    /// and has no side effects such as refresh, re-authentication, or persistence updates.
    ///
    /// - Returns: The current access token, or `nil` when the SDK has no active session.
    /// - Throws: This implementation does not throw directly; the `throws` signature is
    ///   preserved to satisfy `AuthTokenProvider`.
    func retrieveToken() async throws -> String? {
        truvideoSdk.authToken
    }
}
