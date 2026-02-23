//
// Copyright © 2025 TruVideo. All rights reserved.
//

import SwiftUI

/// A collection of design system icons used throughout the camera interface.
///
/// `DSIcons` provides centralized access to all icon assets used in the camera design system,
/// including both SF Symbols and custom bundle images. This struct ensures consistency
/// in icon usage across the camera interface and makes it easy to maintain and update
/// icon references in a single location.
///
/// ## Icon Types
///
/// The collection includes:
/// - **SF Symbols**: System-provided icons like bolt, camera, and play controls
/// - **Action Icons**: Play, pause, and navigation controls
/// - **Media Icons**: Camera and photo-related imagery
///
/// ## Usage
///
/// ```swift
/// // Use SF Symbol icons
/// Image(systemName: "bolt.fill")
/// // vs
/// DSIcons.boltFill
///
/// // Use custom bundle icons
/// DSIcons.flipCameraIcon
/// ```
public enum DSIcons {
    /// Represents a filled lightning bolt, typically used for power or energy-related actions.
    static let boltFill = Image(systemName: "bolt.fill")

    /// Represents a crossed-out lightning bolt, used to indicate disabled or unavailable power-related functionality.
    static let boltSlashFill = Image(systemName: "bolt.slash.fill")

    /// Represents a camera device, used for camera-related actions and indicators.
    static let camera = Image(systemName: "camera")

    /// Represents a custom flip-camera icon, loaded from the app's asset bundle.
    static let cameraTrianglehead = Image("flip-camera", bundle: Bundle(for: BundleLocator.self))

    /// Represents a compact right-pointing chevron, typically used for navigation or disclosure actions.
    static let chevronCompactRight = Image(systemName: "chevron.compact.right")

    /// Represents a checkbox with a checkmark, typically used to indicate a selected or confirmed state.
    static let checkmarkSquare = Image(systemName: "checkmark.square")

    /// Represents a list with bullet points, typically used for menu or formatting actions.
    static let listBullet = Image(systemName: "list.bullet")

    /// Represents an ellipsis icon, typically used for more options or overflow menus.
    static let ellipsis = Image(systemName: "ellipsis")

    /// Represents the rear camera of an iPhone device.
    static let iphoneCamera = Image(systemName: "iphone.rear.camera")

    /// Represents a lock icon for security and authentication-related actions.
    static let lock = Image(systemName: "lock")

    /// Represents the pause action, typically used in media playback controls.
    static let pause = Image(systemName: "pause.fill")

    /// Represents a photo or image, used for photo-related actions and indicators.
    static let photo = Image(systemName: "photo.fill")

    /// Represents an outline version of the photo icon.
    static let photoOutline = Image(systemName: "photo")

    /// Represents the play action, typically used for media playback controls.
    static let play = Image(systemName: "play.fill")

    /// Represents a plus symbol, typically used for adding new items or creating content.
    static let plus = Image(systemName: "plus")

    /// Represents an empty square, typically used for unselected checkbox states.
    static let square = Image(systemName: "square")

    /// Represents text formatting tools, typically used for editing or styling text.
    static let textformat = Image(systemName: "textformat")

    /// A system trash icon for delete actions.
    static let trash = Image(systemName: "trash")

    /// Represents a video camera, typically used for video recording or video mode selection.
    static let video = Image(systemName: "video")

    /// Represents a viewfinder image, used for camera focus or scanning UI.
    static let viewFinder = Image("tap-to-focus", bundle: Bundle(for: BundleLocator.self))

    /// Represents a close or cancel action.
    static let xmark = Image(systemName: "xmark")
}
