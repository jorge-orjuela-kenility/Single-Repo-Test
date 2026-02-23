//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Testing

@testable import TruVideoFoundation

struct UtilityErrorTests {
    // MARK: - Tests

    @Test
    func testThatErrorReasonShouldSucceedWhenPassedARawValue() {
        // Given, When
        let reason = ErrorReason(rawValue: "SOME_REASON")

        // Then
        #expect(reason.rawValue == "SOME_REASON")
    }

    @Test
    func testThatErrorReasonShouldSucceedWhenPassedAUnknown() {
        // Given, When
        let reason = ErrorReason.unknown

        // Then
        #expect(reason.rawValue == "unknown")
    }

    @Test
    func testErrorReasonStringLiteral() {
        // Given, When
        let reason: ErrorReason = "NETWORK_FAILED"

        // Then
        #expect(reason.rawValue == "NETWORK_FAILED")
    }

    @Test
    func testUtilityErrorInitialization() {
        // Given, When
        let error = UtilityError(kind: "INVALID_STATE")

        // Then
        #expect(error.kind.rawValue == "INVALID_STATE")
        #expect(error.failureReason == nil)
        #expect(error.underlyingError == nil)
    }

    @Test
    func testUtilityErrorErrorDescriptionUsesFailureReason() {
        // Given, When
        let error = UtilityError(kind: "INVALID_INPUT", failureReason: "Input is not valid")

        // Then
        #expect(error.errorDescription == "Input is not valid")
    }

    @Test
    func testUtilityErrorErrorDescriptionUsesUnderlyingError() {
        // Given, When
        let underlying = NSError(
            domain: "Test",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Underlying failure"]
        )
        let error = UtilityError(
            kind: "INTERNAL_ERROR",
            underlyingError: underlying
        )

        // Then
        #expect(error.errorDescription == "Underlying failure")
    }

    @Test
    func testUtilityErrorDebugDescriptionWithoutUnderlyingError() {
        // Given
        let error = UtilityError(
            kind: "DEBUG_TEST",
            failureReason: "Something failed",
            column: 10,
            line: 20
        )

        let description = error.debugDescription

        // Then
        #expect(description.contains("UtilityError"))
        #expect(description.contains("kind: DEBUG_TEST"))
        #expect(description.contains("line: 20"))
        #expect(description.contains("column: 10"))
        #expect(description.contains("reason: Something failed"))
    }

    @Test
    func testUtilityErrorDebugDescriptionWithUnderlyingError() {
        // Given
        let underlying = NSError(domain: "Test", code: 1)
        let error = UtilityError(
            kind: "UNDERLYING_ERROR",
            underlyingError: underlying
        )

        let description = error.debugDescription

        // Then
        #expect(description.contains("underlying:"))
        #expect(description.contains("Test"))
    }

    @Test
    func testUtilityErrorDebugDescriptionWithDebuggableUnderlyingError() {
        // Given
        let underlying = DebuggableErrorMock()
        let error = UtilityError(
            kind: "CUSTOM_DEBUG",
            underlyingError: underlying
        )

        let description = error.debugDescription

        // Then
        #expect(description.contains("DEBUGGABLE_ERROR"))
    }
}

struct DebuggableErrorMock: Error, CustomDebugStringConvertible {
    var debugDescription: String { "DEBUGGABLE_ERROR" }
}
