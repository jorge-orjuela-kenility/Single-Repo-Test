//
// Copyright © 2025 TruVideo. All rights reserved.
//

/// Accessibility identifiers used throughout the `GalleryView`.
///
/// These constants serve two main purposes:
/// - **UI Testing:** Provide stable identifiers for automated tests that remain consistent regardless of localization.
extension GalleryView {
    /// Accessibility labels and identifiers used throughout the camera gallery UI.
    ///
    /// This enumeration centralizes all accessibility-related strings for the
    /// gallery experience, ensuring consistency across views and enabling
    /// reliable UI testing and VoiceOver support.
    ///
    /// Static string properties represent fixed UI elements, while helper
    /// functions generate dynamic identifiers for media tiles based on their
    /// position in the gallery grid.
    enum AccessibilityLabel {
        /// Button that closes the current gallery or media viewer and returns to the previous screen.
        static let closeButton = "Close button"

        /// Button that deletes the currently selected or displayed media item.
        static let deleteButton = "Delete button"

        /// Grid or collection view displaying all photo and video thumbnails available in the gallery.
        static let galleryGrid = "Gallery grid"

        /// Main container wrapping the entire gallery interface.
        static let galleryView = "Gallery Container"

        /// Accessibility identifier for the main container that wraps the entire
        /// media preview interface.
        static let mediaPreview = "Media Preview"

        // MARK: - Media Tiles

        /// Accessibility identifier for an image tile in the gallery grid.
        static func capturedImage(index: Int) -> String {
            "capturedImage\(index)"
        }

        /// Accessibility identifier for a video tile in the gallery grid.
        static func capturedVideo(index: Int) -> String {
            "capturedVideo\(index)"
        }
    }
}
