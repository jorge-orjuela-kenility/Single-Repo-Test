//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation
import TruVideoFoundation

extension ErrorReason {
    /// Error reasons that may occur during device settings operations.
    ///
    /// Use these values to classify and handle failures when retrieving
    /// or using device settings (configuration parameters, feature flags, etc.)
    /// from the TruVideo backend.
    public struct DeviceSettingsErrorReason: Sendable {
        /// Error indicating that the device settings retrieval process has failed.
        ///
        /// This error occurs when attempting to fetch device settings from the TruVideo API
        /// but the request fails due to network issues, server errors, or invalid responses.
        /// The device settings contain configuration parameters and feature flags needed
        /// for proper SDK operation.
        public static let deviceSettingsRetrievalFailed = ErrorReason(rawValue: "DEVICE_SETTINGS_RETRIEVAL_FAILED")

        /// Error indicating that the user is not authenticated.
        ///
        /// This error occurs when attempting to access protected resources or perform
        /// operations that require authentication, but no valid authentication session
        /// is available. The user needs to authenticate before proceeding.
        public static let unauthenticated = ErrorReason(rawValue: "UNAUTHENTICATED")
    }
}
