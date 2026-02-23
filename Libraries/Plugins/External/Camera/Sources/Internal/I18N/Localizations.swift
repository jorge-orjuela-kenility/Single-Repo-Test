//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// A collection of localized strings used throughout the camera module.
///
/// `Localizations` provides a centralized location for all user-facing text strings
/// that need to be localized. Each property represents a specific UI element or
/// message that users will see in the camera interface.
enum Localizations {
    // MARK: - A

    /// Active copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Active */
    ///
    /// - Returns: A localized string.
    static let active = NSLocalizedString("Active", bundle: .module, comment: "")

    /// Error message when another app is using the audio copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Recording is not available because another app is using the microphone. Please close it and try again. */
    ///
    /// - Returns: A localized string.
    static let anotherAppIsUsingMicrophone = NSLocalizedString(
        "AnotherAppIsUsingMicrophone",
        bundle: .module,
        comment: ""
    )

    /// attempts copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* attempts */
    ///
    /// - Returns: A localized string.
    static let attempts = NSLocalizedString("Attempts", bundle: .module, comment: "")

    // MARK: - C

    /// Cancel copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Cancel */
    ///
    /// - Returns: A localized string.
    static let cancel = NSLocalizedString("Cancel", bundle: .module, comment: "")

    /// Cancel Message copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Are you sure you want to cancel? */
    ///
    /// - Returns: A localized string.
    static let cancelMessage = NSLocalizedString("CancelMessage", bundle: .module, comment: "")

    /// Cancel Advise copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* This action cannot be undone. */
    ///
    /// - Returns: A localized string.
    static let cancelAdvise = NSLocalizedString("CancelAdvise", bundle: .module, comment: "")

    /// Creation Date copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Creation Date: */
    ///
    /// - Returns: A localized string.
    static let creationDate = NSLocalizedString("CreationDate", bundle: .module, comment: "")

    /// Close copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Close */
    ///
    /// - Returns: A localized string.
    static let close = NSLocalizedString("Close", bundle: .module, comment: "")

    /// Continue copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Continue */
    ///
    /// - Returns: A localized string.
    static let continueText = NSLocalizedString("Continue", bundle: .module, comment: "")

    // MARK: - D

    /// Trash/Delete label copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Delete */
    ///
    /// - Returns: A localized string.
    static let delete = NSLocalizedString("Delete", bundle: .module, comment: "")

    /// Discard copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Discard */
    ///
    /// - Returns: A localized string.
    static let discard = NSLocalizedString("Discard", bundle: .module, comment: "")

    /// Discard Message copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Would you like to discard all videos and images? */
    ///
    /// - Returns: A localized string.
    static let discardMessage = NSLocalizedString("DiscardMessage", bundle: .module, comment: "")

    // MARK: - E

    /// Edit copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Edit */
    ///
    /// - Returns: A localized string.
    static let edit = NSLocalizedString("Edit", bundle: .module, comment: "")

    /// Exit copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Exit */
    ///
    /// - Returns: A localized string.
    static let exit = NSLocalizedString("Exit", bundle: .module, comment: "")

    // MARK: - F

    /// Failed to set preset copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Failed to set preset. Try a lower resolution or frame rate */
    ///
    /// - Returns: A localized string.
    static let failedToSetPreset = NSLocalizedString("FailedToSetPreset", bundle: .module, comment: "")

    /// FHD copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* FHD */
    ///
    /// - Returns: A localized string.
    static let fhd = NSLocalizedString("FHD", bundle: .module, comment: "")

    // MARK: - H

    // swiftlint:disable identifier_name
    /// HD copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* HD */
    ///
    /// - Returns: A localized string.
    static let hd = NSLocalizedString("HD", bundle: .module, comment: "")
    // swiftlint:enable identifier_name

    // MARK: - I

    /// Include in report copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Include in report */
    ///
    /// - Returns: A localized string.
    static let includeInReport = NSLocalizedString("IncludeInReport", bundle: .module, comment: "")

    /// Include to report copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Include to report */
    ///
    /// - Returns: A localized string.
    static let includeToReport = NSLocalizedString("IncludeToReport", bundle: .module, comment: "")

    /// Info copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Info */
    ///
    /// - Returns: A localized string.
    static let info = NSLocalizedString("Info", bundle: .module, comment: "")

    /// Is library copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Is library */
    ///
    /// - Returns: A localized string.
    static let isLibrary = NSLocalizedString("IsLibrary", bundle: .module, comment: "")

    // MARK: - M

    /// Max clip duration reached copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* You’ve reached the video recording time limit.. */
    ///
    /// - Returns: A localized string.
    static let maxClipDurationReached = NSLocalizedString(
        "MaxClipDurationReached",
        bundle: .module,
        comment: ""
    )

    /// Max file size exceeded copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* The uploaded file exceeds the allowable limit of 600MB */
    ///
    /// - Returns: A localized string.
    static let maxFileSizeExceeded = NSLocalizedString("MaxFileSizeExceeded", bundle: .module, comment: "")

    /// Max number of clips reached copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* You have reached the maximum number of videos for this session. */
    ///
    /// - Returns: A localized string.
    static let maxNumberOfClipsReached = NSLocalizedString("MaxNumberOfClipsReached", bundle: .module, comment: "")

    /// Max number of pictures reached copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* You have reached the maximum number of pictures for this session. */
    ///
    /// - Returns: A localized string.
    static let maxNumberOfPicturesReached = NSLocalizedString(
        "MaxNumberOfPicturesReached",
        bundle: .module,
        comment: ""
    )

    /// Media ID copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Media ID: */
    ///
    /// - Returns: A localized string.
    static let mediaId = NSLocalizedString("MediaId", bundle: .module, comment: "")

    /// Metadata copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Metadata */
    ///
    /// - Returns: A localized string.
    static let metadata = NSLocalizedString("Metadata", bundle: .module, comment: "")

    // MARK: - N

    // swiftlint:disable identifier_name
    /// No copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* No */
    ///
    /// - Returns: A localized string.
    static let no = NSLocalizedString("No", bundle: .module, comment: "")
    // swiftlint:enable identifier_name

    /// No metadata added copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* No metadata added */
    ///
    /// - Returns: A localized string.
    static let noMetadataAdded = NSLocalizedString("NoMetadataAdded", bundle: .module, comment: "")

    /// No Streams Found copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* No streams were found */
    ///
    /// - Returns: A localized string.
    static let noStreamsFound = NSLocalizedString("NoStreamsFound", bundle: .module, comment: "")

    /// No tags added copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* No tags added */
    ///
    /// - Returns: A localized string.
    static let noTagsAdded = NSLocalizedString("NoTagsAdded", bundle: .module, comment: "")

    // MARK: - O

    /// Open Settings copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Open Settings */
    ///
    /// - Returns: A localized string.
    static let openSettings = NSLocalizedString("OpenSettings", bundle: .module, comment: "")

    // MARK: - P

    /// Part copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Part */
    ///
    /// - Returns: A localized string.
    static let part = NSLocalizedString("Part", bundle: .module, comment: "")

    /// Pause copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Pause */
    ///
    /// - Returns: A localized string.
    static let pause = NSLocalizedString("Pause", bundle: .module, comment: "")

    /// Permission Disclaimer copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* This lets you use the camera and microphone to take photos and record videos seamlessly. */
    ///
    /// - Returns: A localized string.
    static let permissionDisclaimer = NSLocalizedString("PermissionDisclaimer", bundle: .module, comment: "")

    /// Permission Message copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Allow the App to access your camera and microphone */
    ///
    /// - Returns: A localized string.
    static let permissionMessage = NSLocalizedString("PermissionMessage", bundle: .module, comment: "")

    /// Preset not supported copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /*  Preset not supported on this device */
    ///
    /// - Returns: A localized string.
    static let presetNotSupported = NSLocalizedString("PresetNotSupported", bundle: .module, comment: "")

    // MARK: - R

    /// Resolutions copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Resolutions */
    ///
    /// - Returns: A localized string.
    static let resolutions = NSLocalizedString("Resolutions", bundle: .module, comment: "")

    /// Resume copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Resume */
    ///
    /// - Returns: A localized string.
    static let resume = NSLocalizedString("Resume", bundle: .module, comment: "")

    /// Retry copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Retry */
    ///
    /// - Returns: A localized string.
    static let retry = NSLocalizedString("Retry", bundle: .module, comment: "")

    // MARK: - S

    // swiftlint:disable identifier_name
    /// SD copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* SD */
    ///
    /// - Returns: A localized string.
    static let sd = NSLocalizedString("SD", bundle: .module, comment: "")
    // swiftlint:enable identifier_name

    /// Sign in to continue copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Sign in to continue */
    ///
    /// - Returns: A localized string.
    static let signInToContinue = NSLocalizedString("SignInToContinue", bundle: .module, comment: "")

    /// Sign in to use camera copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Sign in to use the camera and microphone to take photos and record videos */
    ///
    /// - Returns: A localized string.
    static let signInToUseCamera = NSLocalizedString("SignInToUseCamera", bundle: .module, comment: "")

    /// Stream Details copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Stream Details */
    ///
    /// - Returns: A localized string.
    static let streamDetails = NSLocalizedString("StreamDetails", bundle: .module, comment: "")

    /// Stream title copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Stream Title */
    ///
    /// - Returns: A localized string.
    static let streamTitle = NSLocalizedString("StreamTitle", bundle: .module, comment: "")

    /// Stream prefix label copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Stream: */
    ///
    /// - Returns: A localized string.
    static let stream = NSLocalizedString("Stream", bundle: .module, comment: "")

    /// Status label prefix copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Status: */
    ///
    /// - Returns: A localized string.
    static let status = NSLocalizedString("Status", bundle: .module, comment: "")

    /// Suspend copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Suspend */
    ///
    /// - Returns: A localized string.
    static let suspend = NSLocalizedString("Suspend", bundle: .module, comment: "")

    // MARK: - T

    /// Tags copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Tags */
    ///
    /// - Returns: A localized string.
    static let tags = NSLocalizedString("Tags", bundle: .module, comment: "")

    /// Title copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Title */
    ///
    /// - Returns: A localized string.
    static let title = NSLocalizedString("Title", bundle: .module, comment: "")

    /// Torch not available copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Torch is not available on this device */
    ///
    /// - Returns: A localized string.
    static let torchNotAvailable = NSLocalizedString("TorchNotAvailable", bundle: .module, comment: "")

    // MARK: - U

    /// Unknown copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Unknown */
    ///
    /// - Returns: A localized string.
    static let unknown = NSLocalizedString("Unknown", bundle: .module, comment: "")

    /// Upload Operations copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Upload Operations */
    ///
    /// - Returns: A localized string.
    static let uploadOperations = NSLocalizedString("UploadOperations", bundle: .module, comment: "")

    // MARK: - V

    /// Video duration zero copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Recording is not available because video duration is set to 0 */
    ///
    /// - Returns: A localized string.
    static let videoDurationZero = NSLocalizedString("VideoDurationZero", bundle: .module, comment: "")

    // MARK: - W

    /// We couldn't take photo copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* We couldn’t take the photo. Please try again. */
    ///
    /// - Returns: A localized string.
    static let weCouldNotTakeThePhoto = NSLocalizedString("WeCouldNotTakeThePhoto", bundle: .module, comment: "")

    // MARK: - Y

    /// Yes copy.
    ///
    /// In en, this message translates to:
    ///
    ///     /* Yes */
    ///
    /// - Returns: A localized string.
    static let yes = NSLocalizedString("Yes", bundle: .module, comment: "")
}
