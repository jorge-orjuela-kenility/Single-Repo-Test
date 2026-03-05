//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

/// A builder class used to construct instances of `TruvideoSdkMediaMetadata`.
///
/// `TruvideoSdkMediaMetadataBuilder` allows for the progressive addition of key-value pairs to construct media metadata
/// in a flexible and structured manner.
public final class TruvideoSdkMediaMetadataBuilder {
    // MARK: - Private Properties

    private(set) var metadata = Metadata()

    // MARK: - Computed Properties

    /// A computed property that converts the internal `metadata` to a `[String: Any]` dictionary format.
    ///
    /// This is useful for external access to the metadata in a more generic format.
    public var dictionary: [String: Any] {
        metadata.dictionary
    }

    // MARK: - Subscript

    /// A subscript method for accessing or modifying metadata values by key.
    ///
    /// If the value is set to `nil`, the key is removed from the dictionary.
    ///
    /// - Parameter key: The key for the metadata entry.
    /// - Returns: The `MetadataValue` associated with the key, or `nil` if no value exists for the key.
    subscript(key: String) -> MetadataValue? {
        get {
            metadata[key]
        }

        set {
            guard let newValue else {
                metadata.removeValue(forKey: key)
                return
            }

            metadata[key] = newValue
        }
    }

    // MARK: - Initializer

    /// Creates a new instance of `TruvideoSdkMediaMetadataBuilder`
    ///
    /// - Parameter metadata: The initial metadata to set in the builder.
    init(metadata: Metadata) {
        self.metadata = metadata
    }

    /// Creates a new instance of `TruvideoSdkMediaMetadataBuilder` with an empty metadata dictionary.
    public convenience init() {
        self.init(metadata: Metadata())
    }

    // MARK: - Public Methods

    /// Adds or updates a key-value pair where the value is a `String`.
    ///
    /// - Parameters:
    ///   - key: The key for the metadata entry.
    ///   - value: The `String` value to associate with the key.
    /// - Returns: The current instance of `TruvideoSdkMediaMetadataBuilder` for method chaining.
    public func set(_ key: String, _ value: String) -> Self {
        self[key] = .string(value)
        return self
    }

    /// Adds or updates a key-value pair where the value is an array of `String`.
    ///
    /// - Parameters:
    ///   - key: The key for the metadata entry.
    ///   - value: The array of `String` values to associate with the key.
    /// - Returns: The current instance of `TruvideoSdkMediaMetadataBuilder` for method chaining.
    public func set(_ key: String, _ value: [String]) -> Self {
        self[key] = .array(value.map { MetadataValue.string($0) })
        return self
    }

    /// Adds or updates a key-value pair where the value is another `TruvideoSdkMediaMetadata` instance.
    ///
    /// This allows for nested metadata structures.
    ///
    /// - Parameters:
    ///   - key: The key for the metadata entry.
    ///   - value: The `TruvideoSdkMediaMetadata` instance to associate with the key.
    /// - Returns: The current instance of `TruvideoSdkMediaMetadataBuilder` for method chaining.
    public func set(_ key: String, _ value: TruvideoSdkMediaMetadata) -> Self {
        self[key] = .dictionary(value.metadata)
        return self
    }

    /// Builds and returns a `TruvideoSdkMediaMetadata` instance from the current state of the builder.
    ///
    /// This method finalizes the builder and returns the constructed metadata object.
    ///
    /// - Returns: A `TruvideoSdkMediaMetadata` instance containing the current key-value pairs.
    public func build() -> TruvideoSdkMediaMetadata {
        TruvideoSdkMediaMetadata(metadata: metadata)
    }

    // MARK: - Instance Methods

    /// Clears all key-value pairs from the builder's metadata.
    ///
    /// This method resets the builder's state, removing all current entries.
    func clear() {
        metadata.removeAll()
    }
}
