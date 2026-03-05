//
// Copyright © 2026 TruVideo. All rights reserved.
//

internal import DI
import Foundation
internal import InternalUtilities
@_spi(Internal) import TruVideoRuntime

/// C-callable entry point for ObjC +load to avoid importing the generated -Swift.h (fixes ScanDependencies).
@_cdecl("truVideoMediaLibraryRegistry")
func truVideoMediaLibraryRegistry() {
    LibraryRegistry.register(MediaLibrary())
}

private struct MediaLibrary: Library {
    /// The unique name of the library.
    var name: String {
        "TruVideoSdkMedia"
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
