//
// Copyright © 2025 TruVideo. All rights reserved.
//

@testable import TruvideoSdk

struct TruvideoSDKMock: TruVideoSDK {
    /// Indicates whether the user is currently authenticated with the TruVideo service.
    var isAuthenticated = true

    /// The configuration options used to initialize the TruVideo SDK.
    var options: TruvideoSdk.TruVideoOptions = .init()

    /// Authenticates the user with the TruVideo service.
    func authenticate(apiKey: String, secretKey: String, externalId: String?) async throws {}

    /// Signs out the current authenticated session and clears stored credentials.
    func signOut() throws {}

    /// Returns the currently configured API key.
    func apiKey() throws -> String { "" }

    /// Performs client authentication using the given payload and signature.
    func authenticate(apiKey: String, payload: String, signature: String, externalId: String?) async throws {}

    /// Clears the current authentication session.
    func clearAuthentication() throws {}

    /// Generates a JSON string from the current device context.
    func generatePayload() throws -> String { "" }

    /// Initializes the authentication process.
    func initAuthentication() async throws {}

    /// Checks if the current authentication token is expired.
    func isAuthenticationExpired() throws -> Bool {
        true
    }

    /// Configures the TruVideo SDK with the specified options.
    func configure(with options: TruvideoSdk.TruVideoOptions) {}
}
