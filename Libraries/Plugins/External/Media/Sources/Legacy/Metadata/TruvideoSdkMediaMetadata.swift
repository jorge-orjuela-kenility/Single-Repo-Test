//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoFoundation

/// A class representing metadata for the Truvideo SDK, encapsulating key-value pairs in a structured manner.
public final class TruvideoSdkMediaMetadata {
    // MARK: - Properties

    /// An internal representation of the metadata, stored as a `Metadata` object.
    let metadata: Metadata

    // MARK: - Computed Properties

    /// A  dictionary representing the metadata as key-value pairs of type `[String: Any]`.
    public var dictionary: [String: Any] {
        metadata.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.value.rawValue
        }
    }

    // MARK: - Public Methods

    /// Creates and returns a `TruvideoSdkMediaMetadataBuilder` object to construct a `TruvideoSdkMediaMetadata`
    /// instance.
    ///
    /// This builder allows for the progressive addition or modification of metadata.
    ///
    /// - Parameter dictionary: An optional dictionary of key-value pairs to initialize the builder with (default is an
    /// empty dictionary).
    /// - Returns: A new `TruvideoSdkMediaMetadataBuilder` instance.
    public static func builder(dictionary: [String: Any] = [:]) -> TruvideoSdkMediaMetadataBuilder {
        TruvideoSdkMediaMetadataBuilder(metadata: buildMetadata(from: dictionary))
    }

    // MARK: - Initializer

    /// Creates a new instance of `TruvideoSdkMediaMetadata`.
    ///
    /// - Parameter metadata: A `Metadata` object containing the structured key-value pairs.
    init(metadata: Metadata) {
        self.metadata = metadata
    }

    // MARK: - Private methods

    private static func buildMetadata(from dictionary: [String: Any]) -> Metadata {
        dictionary.reduce(into: Metadata()) { result, entry in
            switch entry.value {
            case let array as [String]:
                result[entry.key] = .array(array.map(MetadataValue.string))

            case let dictionary as [String: Any]:
                result[entry.key] = .dictionary(buildMetadata(from: dictionary))

            case let metadataValue as MetadataValue:
                result[entry.key] = metadataValue

            case let string as String:
                result[entry.key] = .string(string)

            default:
                break
            }
        }
    }
}

extension TruvideoSdkMediaMetadata: Equatable {
    // MARK: - Equatable

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: TruvideoSdkMediaMetadata, rhs: TruvideoSdkMediaMetadata) -> Bool {
        lhs.metadata == rhs.metadata
    }
}
