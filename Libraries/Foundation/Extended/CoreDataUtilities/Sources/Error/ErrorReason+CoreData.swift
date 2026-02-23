//
// Copyright © 2025 TruVideo. All rights reserved.
//

import TruVideoFoundation

extension ErrorReason {
    /// A struct that defines common core-data-related error reasons.
    public enum CoreDataKitErrorReason {
        /// Represents an error when an entity cannot be found in the system.
        ///
        /// This error reason is used when a requested entity (such as a user, record, or resource)
        /// does not exist or cannot be located based on the provided criteria.
        public static let entityNotFound = ErrorReason(rawValue: "ENTITY_NOT_FOUND")

        /// This error occurs when attempting to work with an invalid or non-existent Core Data entity name.
        public static let invalidEntityName = ErrorReason(rawValue: "INVALID_ENTITY_NAME")
    }
}
