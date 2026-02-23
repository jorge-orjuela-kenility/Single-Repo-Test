//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// A class representing media tags as a dictionary of key-value pairs.
///
/// `TruvideoSdkMediaTags` provides a read-only dictionary of tags and includes functionality for
/// equality and hashing. This class can be constructed directly via its initializer or
/// through the use of the associated `TruvideoSdkMediaTagsBuilder`.
public final class TruvideoSdkMediaTags: Hashable {
    // MARK: Public Properties

    /// A dictionary containing media tags as key-value pairs of type `[String: String]`.
    public let dictionary: [String: String]

    // MARK: Initializer

    /// Creates a new instance of `TruvideoSdkMediaTags`
    ///
    /// - Parameter dictionary: A dictionary of media tags.
    init(dictionary: [String: String]) {
        self.dictionary = dictionary
    }

    // MARK: Public Methods

    /// Creates and returns a `TruvideoSdkMediaTagsBuilder` object to construct a `TruvideoSdkMediaTags` instance.
    ///
    /// This builder allows you to progressively add or modify tags before building the final `TruvideoSdkMediaTags`
    /// object.
    ///
    /// - Parameter dictionary: An optional initial dictionary of key-value pairs (default is an empty dictionary).
    public static func builder(dictionary: [String: String] = [:]) -> TruvideoSdkMediaTagsBuilder {
        TruvideoSdkMediaTagsBuilder(dictionary: dictionary)
    }

    // MARK: Hashable

    public static func == (lhs: TruvideoSdkMediaTags, rhs: TruvideoSdkMediaTags) -> Bool {
        lhs.dictionary == rhs.dictionary
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(dictionary)
    }
}
