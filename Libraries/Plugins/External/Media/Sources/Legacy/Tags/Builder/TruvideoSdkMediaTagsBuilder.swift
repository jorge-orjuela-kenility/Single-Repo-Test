//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// A builder class for creating instances of `TruvideoSdkMediaTags`.
///
/// The `TruvideoSdkMediaTagsBuilder` allows for the dynamic construction of media tags represented as a dictionary of
/// key-value pairs.
/// It supports adding, updating, and removing tags, and provides a method to create an immutable `TruvideoSdkMediaTags`
/// object.
public final class TruvideoSdkMediaTagsBuilder {
    // MARK: - Public Properties

    /// A dictionary containing tags as key-value pairs of type `[String: String]`.
    ///
    /// The dictionary is mutable and can be modified through the builder's methods.
    public private(set) var dictionary: [String: String]

    // MARK: Initializer

    /// Creates a new instance of `TruvideoSdkMediaTagsBuilder`
    ///
    /// - Parameter dictionary: A dictionary containing tags as key-value pairs of type `[String: String]`.
    init(dictionary: [String: String]) {
        self.dictionary = dictionary
    }

    // MARK: - Subscript

    subscript(key: String) -> String? {
        set {
            guard let newValue else {
                dictionary.removeValue(forKey: key)
                return
            }

            dictionary[key] = newValue
        }
        get {
            dictionary[key]
        }
    }

    // MARK: Public Methods

    /// Constructs a `TruvideoSdkMediaTags` object using the current dictionary of key-value pairs.
    ///
    /// - Returns: A `TruvideoSdkMediaTags` instance with the current tags from the dictionary.
    public func build() -> TruvideoSdkMediaTags {
        TruvideoSdkMediaTags(dictionary: dictionary)
    }

    /// Sets or updates a key-value pair in the dictionary.
    ///
    /// - Parameters:
    ///   - key: The key to set or update in the dictionary.
    ///   - value: The value to associate with the given key.
    /// - Returns: The current `TruvideoSdkMediaTagsBuilder` instance to allow method chaining.
    public func set(_ key: String, _ value: String) -> Self {
        self[key] = value
        return self
    }

    // MARK: Instace Methods

    /// Clears all key-value pairs from the dictionary.
    func clear() {
        dictionary.removeAll()
    }
}
