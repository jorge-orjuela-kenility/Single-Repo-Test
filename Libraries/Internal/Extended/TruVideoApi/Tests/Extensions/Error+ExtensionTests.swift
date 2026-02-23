//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
import Networking
import Testing
import TruVideoFoundation

@testable import TruVideoApi

struct ErrorAsUtilityErrorTests {
    @Test
    func testThatAsUtilityErrorShouldReturnFallbackKindWhenErrorIsNotNetworking() {
        // Given
        let error = NSError(domain: "test", code: 1)
        let fallbackKind: ErrorReason = .unknown

        // When
        let utilityError = error.asUtilityError(or: fallbackKind)

        // Then
        #expect(utilityError.kind == fallbackKind)
        #expect((utilityError.underlyingError as NSError?) == error)
    }

    @Test
    func testThatAsUtilityErrorShouldUseFallbackKindWhenNetworkingErrorHasNoResponseError() {
        // Given
        let underlying = NSError(domain: "network", code: -1)
        let networkingError = NetworkingError(kind: .unknown, underlyingError: underlying)
        let fallbackKind: ErrorReason = .unknown

        // When
        let utilityError = networkingError.asUtilityError(or: fallbackKind)

        // Then
        #expect(utilityError.kind == fallbackKind)
        #expect((utilityError.underlyingError as NSError?) == networkingError as NSError)
    }

    @Test
    func testThatAsUtilityErrorShouldFallbackToUnknownKindWhenResponseErrorHasNoMessage() {
        // Given
        let responseError = RequestValidator.ResponseError(
            detail: "Something went wrong",
            message: nil
        )
        let networkingError = NetworkingError(kind: .unknown, underlyingError: responseError)

        // When
        let utilityError = networkingError.asUtilityError(or: .unknown)

        // Then
        #expect(utilityError.kind == .unknown)
        #expect(utilityError.failureReason == "Something went wrong")
    }

    @Test
    func testThatAsUtilityErrorShouldMapMessageToKindAndDetailToFailureReasonWhenResponseErrorIsValid() {
        // Given
        let responseError = RequestValidator.ResponseError(
            detail: "Invalid parameters",
            message: ErrorReason.TruVideoApiErrorReason.authenticationFailed.rawValue
        )
        let networkingError = NetworkingError(kind: .unknown, underlyingError: responseError)

        // When
        let utilityError = networkingError.asUtilityError(or: "")

        // Then
        #expect(utilityError.kind.rawValue == ErrorReason.TruVideoApiErrorReason.authenticationFailed.rawValue)
        #expect(utilityError.failureReason == "Invalid parameters")
    }
}
