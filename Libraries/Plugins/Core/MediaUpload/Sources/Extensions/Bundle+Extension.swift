//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

extension Bundle {
    /// Returns the bundle containing MediaUpload framework resources.
    ///
    /// This property attempts to locate the `MediaUploadBundle.bundle` resource bundle
    /// within the framework's bundle. If the resource bundle is found, it is returned;
    /// otherwise, the main app bundle is returned as a fallback.
    ///
    /// ## Resource Bundle Location
    ///
    /// The property first locates the framework bundle using `BundleLocator`, then searches
    /// for a resource bundle named "MediaUploadBundle.bundle" within it. This pattern is
    /// commonly used when resources are packaged separately from the framework code.
    ///
    /// ## Fallback Behavior
    ///
    /// If the resource bundle cannot be found (e.g., during development, when resources
    /// are embedded directly in the framework, or when the bundle structure differs),
    /// the property falls back to `Bundle.main`. This ensures that resource access
    /// continues to work even if the expected bundle structure is not present.
    ///
    /// ## Usage
    ///
    /// Use this property to access MediaUpload framework resources such as:
    /// - Core Data model files (`.xcdatamodeld`)
    /// - Localized strings
    /// - Other bundled resources
    ///
    /// ```swift
    /// let bundle = Bundle.mediaUpload
    /// let modelURL = bundle.url(forResource: "Model", withExtension: "momd")
    /// ```
    ///
    /// - Returns: The MediaUpload resource bundle if found, otherwise the main app bundle.
    static var module: Bundle {
        Bundle(for: BundleLocator.self)
    }
}

/// A helper class used to instantiate the current bundle.
private final class BundleLocator {}
