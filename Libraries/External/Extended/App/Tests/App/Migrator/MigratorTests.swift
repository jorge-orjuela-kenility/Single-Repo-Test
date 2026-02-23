//
// Copyright © 2026 TruVideo. All rights reserved.
//

import DI
import StorageKitTesting
import Testing
import TruVideoApiTesting

@testable import TruvideoSdk

struct MigratorTests {
    // MARK: - Tests

    @Test
    func testThatMigrateShouldStoreAuthSessionAndPersistMigrationFlagWhenLegacyDataExists() async throws {
        try await withDependencyValues { dependencies in
            // Given
            let storage = StorageMock()
            let legacyStorage = UserDefaults(suiteName: "truvideo-sdk-tests") ?? .standard
            let sessionManager = SessionManagerMock()
            let sut = SDKMigrator(storage: storage, legacyStorage: legacyStorage)
            let apiKey = "test-api-key"
            let authTokenJSON = """
            {
              "id": "E9C8A3B6-9A3F-4D9B-8E42-3A6D9E1A9F01",
              "accessToken": "access",
              "refreshToken": "refresh"
            }
            """

            // When
            dependencies.sessionManager = sessionManager
            legacyStorage.set(apiKey, forKey: "truvideo-sdk-api-key")
            legacyStorage.set(authTokenJSON, forKey: "truvideo-sdk-authentication")

            try sut.migrate()

            // Then
            #expect(sessionManager.currentSession != nil)
            #expect(sessionManager.currentSession?.apiKey == apiKey)

            let migrated = try storage.readValue(for: SDKMigrator.MigrationStorageKey.self)
            #expect(migrated == true)
        }
    }
}
