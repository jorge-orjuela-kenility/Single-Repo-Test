//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CoreData
internal import CoreDataUtilities
import DI
import Foundation
internal import InternalUtilities
internal import Networking
@_spi(Internal) internal import TruVideoApi

/// Provides a `DependencyKey` for injecting an `AuthTokenProvider` dependency.
///
/// `AuthTokenProviderDependencyKey` allows consumers to override the default token provider
/// mechanism used in the system.
struct AuthTokenProviderDependencyKey: DependencyKey {
    /// The default file-based storage used if none is explicitly provided.
    static let defaultValue: any AuthTokenProvider = BearerTokenProvider()
}

/// Provides a `DependencyKey` for injecting a `EnvironmentDependencyKey` dependency.
///
/// `EnvironmentDependencyKey` is used by the dependency system to resolve the default `Environment`.
struct EnvironmentDependencyKey: DependencyKey {
    /// The default configuration used if none is explicitly set.
    static let defaultValue = Environment.prod
}

/// Dependency key for resolving an `EventEmitter` implementation.
///
/// This abstracts the event emission system responsible for broadcasting operation events.
/// Override this in `DependencyValues` to swap implementations (e.g., mock vs. production).
struct EventEmitterDependencyKey: DependencyKey {
    /// The default event emitter used if none is explicitly provided.
    static let defaultValue = EventEmitter()
}

/// Provides a `DependencyKey` for injecting a `Session` dependency.
///
/// `SessionDependencyKey` allows consumers to override the default storage
/// mechanism used in the system. By default, this uses `HTTPURLSession`.
struct SessionDependencyKey: DependencyKey {
    /// The default file-based storage used if none is explicitly provided.
    static let defaultValue: any Session = {
        let middleware = Middleware(interceptors: [], retriers: [SessionRequestRetrier()])
        let monitors = [SessionMonitor()]

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        let timeoutInterval = TimeInterval(15 * 60)

        sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
        sessionConfiguration.timeoutIntervalForResource = timeoutInterval

        return HTTPURLSession(
            configuration: sessionConfiguration,
            cache: InMemoryURLCache(),
            middleware: middleware,
            monitors: monitors
        )
    }()
}

// TODO: Temporal until v2 of this module
/// Provides a `DependencyKey` for injecting an `PersistentContainerDependencyKey` dependency.
///
/// `PersistentContainerDependencyKey` allows consumers to override the persistent container
/// mechanism used in the system.
public struct PersistentContainerDependencyKey: DependencyKey {
    /// The default file-based storage used if none is explicitly provided.
    public static let defaultValue = NSPersistentContainer.load("UploadsStore", type: .sqlite, in: .module)
}

extension DependencyValues {
    /// Accessor for resolving or overriding the current `AuthTokenProvider` implementation.
    var authTokenProvider: any AuthTokenProvider {
        get { self[AuthTokenProviderDependencyKey.self] }
        set { self[AuthTokenProviderDependencyKey.self] = newValue }
    }

    /// Accessor for resolving or overriding the current `Environment`.
    var environment: Environment {
        get { self[EnvironmentDependencyKey.self] }
        set { self[EnvironmentDependencyKey.self] = newValue }
    }

    /// Accessor for resolving or overriding the current `EventEmitter` implementation.
    var eventEmitter: EventEmitter {
        get { self[EventEmitterDependencyKey.self] }
        set { self[EventEmitterDependencyKey.self] = newValue }
    }

    /// Accessor for resolving or overriding the current `Session` implementation.
    var session: any Session {
        get { self[SessionDependencyKey.self] }
        set { self[SessionDependencyKey.self] = newValue }
    }

    /// Accessor for resolving or overriding the current `NSPersistentContainer` implementation.
    public var persistentContainer: NSPersistentContainer {
        get { self[PersistentContainerDependencyKey.self] }
        set { self[PersistentContainerDependencyKey.self] = newValue }
    }
}
