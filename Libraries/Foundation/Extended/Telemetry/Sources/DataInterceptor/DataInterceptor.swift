//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Foundation

/// A protocol that defines a data–interception mechanism for transforming
/// `Codable` values before they are stored, logged, or transmitted.
///
/// Conforming types can inspect, redact, hash, encrypt, or otherwise modify
/// the input value. This makes the protocol ideal for building data–processing
/// pipelines such as:
///
/// - PII redaction (emails, phone numbers, tokens, etc.)
/// - Hashing identifiers for anonymization
/// - Encryption of sensitive payloads
/// - Debug-only transformations
/// - Filtering or masking fields before exporting logs
///
/// Implementations should behave as pure functions: calling `intercept(_:)`
/// with the same input should always return an equivalent output, without
/// producing side effects.
///
/// ### Example
///
/// ```swift
/// struct SensitiveDataInterceptor: DataInterceptor {
///     func intercept<T: Codable>(_ value: T) -> T {
///         // sanitize sensitive data here
///         return value
///     }
/// }
/// ```
///
/// ### Usage
///
/// ```swift
/// let interceptor: DataInterceptor = PIIRedactor()
/// let cleanedEvent = interceptor.intercept(event)
/// ```
protocol DataInterceptor {
    /// Intercepts and transforms a `Codable` value.
    ///
    /// - Parameter value: The value to inspect and potentially modify.
    ///   This value must conform to `Codable`.
    ///
    /// - Returns: A transformed version of the original value. The returned
    ///   instance must be the same type as the input, making the interceptor
    ///   suitable for strongly typed pipelines.
    func intercept<T: Codable>(_ value: T) -> T
}

/// An implementation of `DataInterceptor` that detects and sanitizes sensitive
/// information (PII) from `Codable` payloads before they are logged, persisted,
/// or transmitted.
///
/// `SensitiveDataInterceptor` applies a configurable set of `PIIPattern` rules
/// to recursively inspect and transform values inside any `Codable` object.
/// These transformations typically include:
///
/// - Redaction of emails, phone numbers, authentication tokens, etc.
/// - Replacement with masked values (e.g., `"****"`).
/// - Hashing or encrypting sensitive substrings (if configured in the pattern).
///
/// The interceptor converts the input object into a JSON representation,
/// recursively scrubs all nested structures (`String`, `[Any]`, `[String: Any]`),
/// and then decodes the sanitized result back into the original type.
final class SensitiveDataInterceptor: DataInterceptor {
    /// The list of sensitive data patterns used to perform scrubbing operations.
    /// Each `PIIPattern` specifies a PII type, a detection regex, and a
    /// transformation closure for replacing matched substrings.
    private let patterns: [PIIRedactionRule]

    // MARK: - Initializer

    /// Creates a new sensitive data interceptor.
    ///
    /// - Parameter patterns: The list of `PIIRedactionRule` rules used to detect and
    ///   transform sensitive substrings.
    ///
    /// You may supply custom patterns to support additional PII formats or
    /// specific transformation strategies such as hashing or encryption.
    init(patterns: [PIIRedactionRule] = [.email, .phone, .token]) {
        self.patterns = patterns
    }

    // MARK: - DataInterceptor

    /// Intercepts and transforms a `Codable` value.
    ///
    /// - Parameter value: The value to inspect and potentially modify.
    ///   This value must conform to `Codable`.
    ///
    /// - Returns: A transformed version of the original value. The returned
    ///   instance must be the same type as the input, making the interceptor
    ///   suitable for strongly typed pipelines.
    func intercept<T: Codable>(_ value: T) -> T {
        do {
            let data = try JSONEncoder().encode(value)

            var json = try JSONSerialization.jsonObject(with: data)

            json = scrub(json)
            let cleanedData = try JSONSerialization.data(withJSONObject: json)

            return try JSONDecoder().decode(T.self, from: cleanedData)
        } catch {
            return value
        }
    }

    // MARK: - Private methods

    private func scrub(_ value: Any) -> Any {
        switch value {
        case let string as String:
            return patterns.reduce(string) { partial, pattern in
                pattern.apply(to: partial)
            }

        case let dict as [String: Any]:
            var newDict = dict
            for (key, val) in dict {
                newDict[key] = scrub(val)
            }

            return newDict

        case let array as [Any]:
            return array.map { scrub($0) }

        default:
            return value
        }
    }
}

extension PIIRedactionRule {
    /// Applies the pattern’s redaction rule to a given string.
    ///
    /// This method searches the input string for all matches of the pattern's
    /// regular expression. Each match is replaced using the pattern's `replacement`
    /// closure, allowing custom masking, hashing, truncation, or transformation of
    /// sensitive information.
    ///
    /// - Parameter string: The original string to which the redaction rule will be applied.
    /// - Returns: A new string where all occurrences matching the pattern's regex have been
    ///   replaced according to the pattern's replacement logic.
    fileprivate func apply(to string: String) -> String {
        guard let regex = self.regex else { return string }

        var result = string
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))

        for match in matches.reversed() {
            guard let range = Range(match.range, in: result) else { continue }

            let found = String(result[range])
            result.replaceSubrange(range, with: self.replacement(found))
        }

        return result
    }
}
