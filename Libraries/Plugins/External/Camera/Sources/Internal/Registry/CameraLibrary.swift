//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
@_spi(Internal) import TruVideoRuntime

/// C-callable entry point for ObjC +load to avoid importing the generated -Swift.h (fixes ScanDependencies).
@_cdecl("truVideoCameraLibraryRegistry")
func truVideoCameraLibraryRegistry() {
    LibraryRegistry.register(CameraLibrary())
}

private struct CameraLibrary: Library {
    /// The unique name of the library.
    var name: String {
        "TruVideoSdkCamera"
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
    func configure() {}
}
