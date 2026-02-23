//
// Copyright © 2025 TruVideo. All rights reserved.
//

import Testing

@testable import Telemetry

struct DataInterceptorTests {
    private struct MockEvent: Codable, Equatable {
        let name: String
        let email: String?
        let phone: String?
        let token: String?
        let metadata: [String: String]?
        let tags: [String]?
        var index = 0
    }

    private struct ComplexEvent: Codable {
        let user: MockEvent
        let history: [MockEvent]
    }

    // MARK: - Tests

    @Test
    func testInterceptRedactsEmail() {
        // Given
        let interceptor = SensitiveDataInterceptor(patterns: [.email])
        let event = MockEvent(
            name: "User Login",
            email: "john.doe@example.com",
            phone: nil,
            token: nil,
            metadata: nil,
            tags: nil
        )

        // When
        let result = interceptor.intercept(event)

        // Then
        #expect(result.email == "****")
        #expect(result.name == "User Login")
    }

    @Test
    func testInterceptRedactsPhone() {
        // Given
        let interceptor = SensitiveDataInterceptor(patterns: [.phone])
        let event = MockEvent(
            name: "Call Event",
            email: nil,
            phone: "+1-555-010-9988",
            token: nil,
            metadata: nil,
            tags: nil
        )

        // When
        let result = interceptor.intercept(event)

        // Then
        #expect(result.phone == "****")
    }

    @Test
    func testInterceptRedactsToken() {
        // Given
        let interceptor = SensitiveDataInterceptor(patterns: [.token])
        let event = MockEvent(
            name: "API Request",
            email: nil,
            phone: nil,
            token: "Bearer abc123xyz",
            metadata: nil,
            tags: nil
        )

        // When
        let result = interceptor.intercept(event)

        // Then
        #expect(result.token == "****")
    }

    @Test
    func testInterceptRedactsNestedDictionary() {
        // Given
        let interceptor = SensitiveDataInterceptor(patterns: [.email])
        let event = MockEvent(
            name: "Metadata Event",
            email: nil,
            phone: nil,
            token: nil,
            metadata: ["contact": "test@truvideo.com", "other": "safe"],
            tags: nil
        )

        // When
        let result = interceptor.intercept(event)

        // Then
        #expect(result.metadata?["contact"] == "****")
        #expect(result.metadata?["other"] == "safe")
    }

    @Test
    func testInterceptRedactsArray() {
        // Given
        let interceptor = SensitiveDataInterceptor(patterns: [.email])
        let event = MockEvent(
            name: "Tags Event",
            email: nil,
            phone: nil,
            token: nil,
            metadata: nil,
            tags: ["safe_tag", "admin@example.com"]
        )

        // When
        let result = interceptor.intercept(event)

        // Then
        #expect(result.tags?[0] == "safe_tag")
        #expect(result.tags?[1] == "****")
    }

    @Test
    func testInterceptWithCustomPattern() {
        // Given
        let customPattern = PIIRedactionRule(regex: #"secret_\w+"#, replacement: { _ in "REDACTED" })
        let interceptor = SensitiveDataInterceptor(patterns: [customPattern])
        let event = MockEvent(
            name: "Custom Secret",
            email: nil,
            phone: nil,
            token: nil,
            metadata: ["key": "secret_value123"],
            tags: nil
        )

        // When
        let result = interceptor.intercept(event)

        // Then
        #expect(result.metadata?["key"] == "REDACTED")
    }

    @Test
    func testInterceptDoesNotModifySafeData() {
        // Given
        let interceptor = SensitiveDataInterceptor()
        let event = MockEvent(
            name: "Safe Event",
            email: "safe_string",
            phone: "123",
            token: "hello world",
            metadata: ["key": "value"],
            tags: ["tag1", "tag2"]
        )

        // When
        let result = interceptor.intercept(event)

        // Then
        #expect(result == event)
    }

    @Test
    func testInterceptHandlesComplexNestedStructure() {
        // Given
        let interceptor = SensitiveDataInterceptor(patterns: [.email])
        let user = MockEvent(name: "User", email: "user@example.com", phone: nil, token: nil, metadata: nil, tags: nil)
        let historyItem = MockEvent(
            name: "History",
            email: "history@example.com",
            phone: nil,
            token: nil,
            metadata: nil,
            tags: nil
        )

        let complex = ComplexEvent(user: user, history: [historyItem])

        // When
        let result = interceptor.intercept(complex)

        // Then
        #expect(result.user.email == "****")
        #expect(result.history.first?.email == "****")
    }
}
