//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import TruVideoFoundation

@testable import TruVideoApi

/// A mock implementation of `TokenRefresher` for testing.
public final class TokenRefresherMock: TokenRefresher {
    // MARK: - Properties

    /// Error to throw when `refreshToken()` is called.
    public var error: UtilityError?

    // MARK: - Call Tracking

    /// Tracks how many times `refreshToken()` was called.
    public private(set) var refreshTokenCallCount = 0

    /// Indicates whether `refreshToken()` was called at least once.
    public var refreshTokenCalled: Bool { refreshTokenCallCount > 0 }

    // MARK: - Initializer

    /// Creates a new instance of `TokenRefresherMock`.
    public init() {}

    // MARK: - TokenRefresher

    /// Simulates refreshing the authentication token.
    ///
    /// - Throws: `error` when configured.
    public func refreshToken() async throws(UtilityError) {
        refreshTokenCallCount += 1

        if let error {
            throw error
        }
    }
}
