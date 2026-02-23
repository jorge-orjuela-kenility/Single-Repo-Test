//
// Copyright © 2026 TruVideo. All rights reserved.
//

internal import DI
import Foundation
internal import InternalUtilities
import TruVideoApi
internal import TruVideoRuntime

/// C-callable entry point for ObjC +load to avoid importing the generated -Swift.h (fixes ScanDependencies).
@_cdecl("truVideoSDKLibraryRegistry")
func truVideoSDKLibraryRegister() {
    LibraryRegistry.register(TruVideoSDKLibrary())
}

private struct TruVideoSDKLibrary: Library {
    /// The unique name of the library.
    var name: String {
        "TruVideoSdk"
    }

    /// The current semantic version of the library.
    var version: String {
        SDKVersionNumber
    }

    // MARK: - Library

    /// Configures the library with the provided SDK configuration.
    ///
    /// This method is called during SDK initialization to set up library-specific
    /// dependencies, services, or configurations.
    func configure() {
        DependencyValues.current.environment = Environment(rawValue: SDKEnvironment)
        DependencyValues.current.sessionManager = SecureSessionManager(secretKey: SDKSecretKey)
    }
}
