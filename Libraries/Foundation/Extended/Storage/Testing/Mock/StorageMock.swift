//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

@testable import StorageKit

public final class StorageMock: Storage, @unchecked Sendable {
    // MARK: - Properties

    /// Optional error used to simulate failure scenarios during storage operations.
    public var error: Error?

    // MARK: - Private Properties

    /// Tracks the number of times the `clear` operation has been invoked.
    private(set) var clearCallCount = 0

    /// Tracks the number of times a delete operation has been invoked.
    private(set) var deleteValueCallCount = 0

    /// Tracks the number of times a read operation has been invoked.
    private(set) var readValueCallCount = 0

    /// Tracks the number of times a write operation has been invoked.
    private(set) var writeValueCallCount = 0

    /// In-memory storage used to simulate persistent key-value storage.
    private var storage: [String: Any] = [:]

    // MARK: - Initializer

    public init() {}

    // MARK: - Storage

    /// Removes all stored key-value pairs from the storage.
    ///
    /// - Throws: An error if the clear operation fails.
    public func clear() throws {
        clearCallCount += 1

        if let error {
            throw error
        }

        storage.removeAll()
    }

    /// Deletes the value associated with the specified `StorageKey` type.
    ///
    /// - Parameter key: The type conforming to `StorageKey` whose value should be removed.
    /// - Throws: An error if the delete operation fails.
    public func deleteValue(for key: (some StorageKey).Type) throws {
        deleteValueCallCount += 1

        if let error {
            throw error
        }

        storage.removeValue(forKey: key.name)
    }

    /// Reads the value associated with the given `StorageKey` type.
    ///
    /// - Parameter key: The type conforming to `StorageKey` to read the value for.
    /// - Returns: The decoded value associated with the key, or `nil` if not found.
    /// - Throws: An error if the underlying read operation fails.
    public func readValue<Key: StorageKey>(for key: Key.Type) throws -> Key.Value? {
        readValueCallCount += 1

        if let error {
            throw error
        }

        return storage[key.name] as? Key.Value
    }

    /// Writes the given value to the storage using the specified `StorageKey`.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key type associated with the value.
    /// - Throws: An error if the write operation fails.
    public func write<Key: StorageKey>(_ value: Key.Value, forKey key: Key.Type) throws {
        writeValueCallCount += 1

        if let error {
            throw error
        }

        storage[key.name] = value
    }
}
