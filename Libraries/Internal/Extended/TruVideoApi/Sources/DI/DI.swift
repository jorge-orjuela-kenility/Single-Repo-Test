//
// Copyright © 2025 TruVideo. All rights reserved.
//

import DI
internal import Networking
internal import StorageKit

/// Provides a `DependencyKey` for injecting a `Session` dependency.
///
/// `SessionDependencyKey` allows consumers to override the default storage
/// mechanism used in the system. By default, this uses `HTTPURLSession`.
struct SessionDependencyKey: DependencyKey {
    /// The default file-based storage used if none is explicitly provided.
    static let defaultValue: any Session = {
        let cache = InMemoryURLCache()
        let sessionTokenRefresher = SessionTokenRefresher()
        let sessionRequestRetrier = SessionRequestRetrier(tokenRefresher: sessionTokenRefresher)

        let middleware = Middleware(interceptors: [], retriers: [sessionRequestRetrier])
        let monitors = [SessionMonitor()]

        return HTTPURLSession(cache: cache, middleware: middleware, monitors: monitors)
    }()
}

/// Provides a `DependencyKey` for injecting a `Storage` dependency.
///
/// `StorageDependencyKey` allows consumers to override the default storage
/// mechanism used in the system. By default, this uses `KeychainStorage`.
struct SessionManagerDependencyKey: DependencyKey {
    /// The default file-based storage used if none is explicitly provided.
    static let defaultValue: any SessionManager = SecureSessionManager(secretKey: "")
}

extension DependencyValues {
    /// Accessor for resolving or overriding the current `Session` implementation.
    var session: any Session {
        get { self[SessionDependencyKey.self] }
        set { self[SessionDependencyKey.self] = newValue }
    }

    /// Accessor for resolving or overriding the current `SessionManager` implementation.
    public var sessionManager: any SessionManager {
        get { self[SessionManagerDependencyKey.self] }
        set { self[SessionManagerDependencyKey.self] = newValue }
    }
}
