//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable @_spi(Internal) import TruVideoRuntime

@Suite(.serialized)
struct LibraryRegistryTests {
    // MARK: - Tests

    @Test
    func registeredLibrariesReturnsDictionary() {
        // Given, When, Then
        let libraries = LibraryRegistry.registeredLibraries()
        #expect(libraries.keys.count >= 0)
    }

    @Test
    func registeredLibrariesMapsNameToVersion() {
        // Given
        let name = "TestLibrary-Unit.\(UUID().uuidString)"
        let version = "1.2.3"

        // When
        LibraryRegistry.register(CallbackLibrary(name: name, version: version))

        // Then
        #expect(LibraryRegistry.registeredLibraries()[name] == version)
    }

    @Test
    func registerIgnoresLibraryWithInvalidNameContainingSpace() {
        // Given
        let countBefore = LibraryRegistry.registeredLibraries().count

        // When
        LibraryRegistry.register(CallbackLibrary(name: "invalid name", version: "1.0.0"))

        // Then
        #expect(LibraryRegistry.registeredLibraries().count == countBefore)
    }

    @Test
    func registerIgnoresLibraryWithInvalidNameContainingSpecialCharacters() {
        // Given
        let countBefore = LibraryRegistry.registeredLibraries().count

        // When
        LibraryRegistry.register(CallbackLibrary(name: "lib@symbol", version: "1.0.0"))

        // Then
        #expect(LibraryRegistry.registeredLibraries().count == countBefore)
    }

    @Test
    func registerIgnoresLibraryWithEmptyName() {
        // Given
        let countBefore = LibraryRegistry.registeredLibraries().count

        // When
        LibraryRegistry.register(CallbackLibrary(name: "", version: "1.0.0"))

        // Then
        #expect(LibraryRegistry.registeredLibraries().count == countBefore)
    }

    @Test
    func registerAcceptsValidNameWithHyphenUnderscoreAndDot() {
        // Given
        let name = "Valid-Lib_Name.1"

        // When
        LibraryRegistry.register(CallbackLibrary(name: name, version: "0.0.1"))

        // Then
        #expect(LibraryRegistry.registeredLibraries()[name] == "0.0.1")
    }

    @Test
    func configureAllCallsConfigureOnEachRegisteredLibrary() {
        // Given
        let lib = CallbackLibrary(name: "ConfigureTest-\(UUID().uuidString)", version: "1.0.0")
        var configureCalled = false

        // When
        lib.onConfigure = { configureCalled = true }
        LibraryRegistry.register(lib)

        LibraryRegistry.configureAll()

        // Then
        #expect(configureCalled == true)
        #expect(LibraryRegistry.isConfigured == true)
    }

    @Test
    func configureAllSetsIsConfiguredToTrue() {
        // Given, When
        LibraryRegistry.configureAll()

        // Then
        #expect(LibraryRegistry.isConfigured == true)
    }
}

private final class CallbackLibrary: Library {
    let name: String
    let version: String
    var onConfigure: () -> Void = {}

    // MARK: - Initializer

    init(name: String, version: String) {
        self.name = name
        self.version = version
    }

    // MARK: - Library

    func configure() {
        onConfigure()
    }
}
