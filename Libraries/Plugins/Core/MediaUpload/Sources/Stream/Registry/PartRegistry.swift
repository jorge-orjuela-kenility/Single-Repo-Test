//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// A registry that maintains a collection of stream part handles for quick lookup and iteration.
///
/// `PartRegistry` provides a thread-safe, in-memory cache of `PartHandle` instances indexed by
/// their unique identifiers. This allows efficient access to parts and their associated
/// operations without requiring database queries. The registry conforms to `Sequence`, enabling
/// iteration over all registered parts.
///
/// ## Thread Safety
///
/// The registry uses `NSLock` to ensure thread-safe access to its internal dictionary.
/// All mutations and reads are synchronized, making it safe to use from multiple threads.
///
/// ## Usage
///
/// Parts are registered when they are created via `register(_:)` and can be looked up by their
/// UUID using `value(forKey:)`. The registry can be iterated using `for...in` loops thanks to
/// its `Sequence` conformance, allowing operations to be performed on all registered parts.
final class PartRegistry: @unchecked Sendable, Sequence {
    // MARK: - Private Properties

    private let lock = NSLock()
    private var parts: [UUID: MUPartHandle] = [:]

    // MARK: - Instance methods

    /// Returns all currently registered part handles.
    ///
    /// Provides a snapshot array containing every `PartHandle` stored in the registry at the
    /// moment of invocation. The returned array is safe to iterate without additional locking.
    ///
    /// - Returns: An array of all registered `PartHandle` instances.
    func registeredParts() -> [MUPartHandle] {
        Array(parts.values)
    }

    /// Registers a part handle in the registry.
    ///
    /// Associates the provided `PartHandle` with the given stream part so it can be retrieved later
    /// by identifier or iterated with the registry. Existing entries with the same identifier are
    /// replaced.
    ///
    /// - Parameters:
    ///   - handle: The part handle that manages operations for the stream part.
    ///   - key: The stream part whose identifier will be used as the lookup key.
    func register(_ handle: MUPartHandle, for key: UUID) {
        lock.withLock {
            parts[key] = handle
        }
    }

    func removeValue(for key: UUID) {
        _ = lock.withLock { parts.removeValue(forKey: key) }
    }

    /// Retrieves a part handle for the given identifier.
    ///
    /// Performs a thread-safe lookup of the part handle associated with the specified UUID.
    /// Returns `nil` if no part with the given identifier is registered.
    ///
    /// - Parameter key: The unique identifier of the stream part to look up.
    /// - Returns: The `PartHandle` associated with the identifier, or `nil` if not found.
    func value(forKey partId: UUID) -> MUPartHandle? {
        lock.withLock { parts[partId] }
    }

    // MARK: - Sequence

    /// Creates an iterator over all registered part handles.
    ///
    /// Enables iteration over the registry using `for...in` loops. The iterator yields
    /// all `PartHandle` instances currently registered in the registry.
    ///
    /// - Returns: An iterator that yields `PartHandle` instances.
    func makeIterator() -> some IteratorProtocol<MUPartHandle> {
        parts.values.makeIterator()
    }
}
