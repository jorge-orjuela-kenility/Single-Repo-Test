//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import DI
internal import TruVideoApi
import UIKit

/// Provides a `DependencyKey` for injecting a `MediaResource` dependency.
///
/// `MediaResourceDependencyKey` defines the default implementation of the
/// `MediaResource` protocol within the dependency injection system. When a caller
/// accesses `Dependency(\.mediaResource)` without explicitly overriding the value,
/// the dependency system resolves to the default instance defined here.
struct MediaResourceDependencyKey: DependencyKey {
    /// The default authenticatable client used if none is explicitly set.
    static let defaultValue: any MediaResource = MediaResourceImpl()
}

/// Provides a `DependencyKey` for injecting a `OrientationMonitor` dependency.
///
/// `OrientationMonitorDependencyKey` is used by the dependency system to resolve the default
/// implementation of `OrientationMonitor`.
struct OrientationMonitorDependencyKey: DependencyKey {
    /// The default orientation monitor used if none is explicitly set.
    static let defaultValue: any OrientationMonitor = DeviceOrientationMonitor()
}

/// Provides a `DependencyKey` for injecting a preferred `UIDeviceOrientation`.
///
/// `PreferredOrientationDependencyKey` is used by the dependency system to resolve
/// or override the currently preferred device orientation when none is explicitly provided.
struct PreferredOrientationDependencyKey: DependencyKey {
    /// The default preferred orientation used if none is explicitly set.
    static let defaultValue: UIDeviceOrientation? = nil
}

extension DependencyValues {
    /// Accessor for resolving or overriding the current `MediaResource`.
    var mediaResource: any MediaResource {
        get { self[MediaResourceDependencyKey.self] }
        set { self[MediaResourceDependencyKey.self] = newValue }
    }

    /// Accessor for resolving or overriding the current `OrientationMonitor`.
    var orientationMonitor: any OrientationMonitor {
        get { self[OrientationMonitorDependencyKey.self] }
        set { self[OrientationMonitorDependencyKey.self] = newValue }
    }

    /// Accessor for resolving or overriding the current preferred `UIDeviceOrientation`.
    var preferredOrientation: UIDeviceOrientation? {
        get { self[PreferredOrientationDependencyKey.self] }
        set { self[PreferredOrientationDependencyKey.self] = newValue }
    }
}
