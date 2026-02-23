//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import TruVideoFoundation

extension ErrorReason {
    /// A collection of error reasons related to the signer.
    ///
    /// The `MediaResourceErrorReason` struct provides a set of static constants representing various errors that can
    /// occur during interactions with the external storages.
    public struct MediaResourceErrorReason: Sendable {
        /// Failed while creating a media entity.
        public static let createMediaFailed = ErrorReason(rawValue: "CREATE_MEDIA_FAILED")

        /// Failed while finding (fetching) a media entity.
        public static let findMediaFailed = ErrorReason(rawValue: "FIND_MEDIA_FAILED")

        /// Failed while searching media entities.
        public static let searchMediaFailed = ErrorReason(rawValue: "SEARCH_MEDIA_FAILED")

        /// Failed while updating a media entity.
        public static let updateMediaFailed = ErrorReason(rawValue: "UPDATE_MEDIA_FAILED")
    }
}
