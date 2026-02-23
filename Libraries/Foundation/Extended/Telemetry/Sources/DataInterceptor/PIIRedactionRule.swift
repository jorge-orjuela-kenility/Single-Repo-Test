//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// Represents a rule for detecting and transforming sensitive (PII) content
/// within a string. A `PIIRedactionRule` associates:
/// - a specific PII type (`email`, `phone`, `token`, etc.),
/// - a regular expression that matches occurrences of that PII,
/// - a replacement closure that determines how the matched value should be
///   transformed (e.g., redacted, hashed, encrypted).
///
/// This allows fine-grained and dynamic scrubbing of sensitive data before
/// logging, storing, or transmitting a payload.
///
/// `PIIRedactionRule` is intentionally flexible to support multiple privacy strategies
/// (masking, hashing, encryption, removal, etc.).
public struct PIIRedactionRule {
    /// A compiled regular expression used to locate occurrences of the PII
    /// within a string.
    public let regex: NSRegularExpression?

    /// A closure that receives the matched substring and returns the value
    /// that should replace it. This enables dynamic transformations, unlike
    /// static regex templates.
    public let replacement: (String) -> String

    // MARK: - Static Properties

    /// Regular expression pattern used to detect email addresses.
    ///
    /// This pattern matches most standard email formats, including:
    /// - Alphanumeric characters
    /// - Dots (.)
    /// - Underscores (_)
    /// - Percent signs (%)
    /// - Plus (+) and minus (-) symbols
    public static let email = PIIRedactionRule(
        regex: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
    )

    /// Regular expression pattern used to detect phone numbers.
    ///
    /// This pattern supports:
    /// - Optional international prefix (e.g. +1, +57)
    /// - Optional separators such as spaces, dashes, or dots
    /// - Area codes with or without parentheses
    ///
    /// Example matches:
    /// - +1 555 123 4567
    /// - (300) 123-4567
    /// - 300-123-4567
    public static let phone = PIIRedactionRule(
        regex: #"\+?\d{1,4}?[-.\s]??(?:\(\d{1,3}\)|\d{1,3})[-.\s]?\d{3,4}[-.\s]?\d{4}"#
    )

    /// Regular expression pattern used to detect authentication tokens and credentials.
    ///
    /// This pattern matches common authorization headers and token formats, including:
    /// - Bearer tokens
    /// - JWTs
    /// - Generic tokens
    /// - Authorization headers
    ///
    /// Example matches:
    /// - Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    /// - Authorization token abc123xyz
    public static let token = PIIRedactionRule(
        regex: #"(?i)(bearer|token|jwt|authorization)\s+[A-Za-z0-9\-_\.]+"#
    )

    // MARK: - Initializer

    /// Creates a new `PIIRedactionRule` instance used to detect and transform sensitive
    /// information within strings.
    ///
    /// - Parameters:
    ///   - regex: A compiled regular expression used to locate occurrences of the PII
    ///     within a string.
    ///   - replacement: A closure that receives the matched substring and returns the value
    ///     that should replace it.
    public init(
        regex: String,
        replacement: @escaping (String) -> String = { _ in "****" }
    ) {
        self.replacement = replacement
        self.regex = try? NSRegularExpression(
            pattern: regex,
            options: [.caseInsensitive]
        )
    }
}
