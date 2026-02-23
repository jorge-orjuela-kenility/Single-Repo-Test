//
// Created by TruVideo on 5/1/24.
// Copyright © 2024 TruVideo. All rights reserved.
//

import Foundation

@_implementationOnly import shared

class TruvideoSdkMediaLogger {
    // MARK: Static Properties

    /// The shared instance of `TruvideoSdkMediaLogger`.
    ///
    /// This static property provides access to the singleton instance of the logger.
    static let shared = TruvideoSdkMediaLogger()

    // MARK: Private Properties

    private let sdk = TruvideoSdkCommonKt.sdk_common

    private var moduleVersion = "0.0.01"

    // MARK: Initializer

    /// Creates a new instance of  `TruvideoSdkMediaLogger`.
    ///
    /// This initializer is private to enforce the singleton pattern. It retrieves the module version from the bundle.
    init() {
        getModuleVersion()
    }

    // MARK: Private Methods

    private func getModuleVersion() {
        let bundle = Bundle(for: TruvideoSdkMediaLogger.self)
        guard let path = bundle.path(forResource: "version", ofType: "properties"),
              let contents = try? String(contentsOfFile: path) else { return }

        let lines = contents.components(separatedBy: .newlines)

        for line in lines {
            let components = line.components(separatedBy: "=")
            if components.count == 2, components[0] == "version" {
                let versionNumber = components[1]
                moduleVersion = versionNumber
                break
            }
        }
    }

    // MARK: Static Methods

    /// Logs an event with a message and severity.
    ///
    /// This method sends the log to the shared SDK logging system with the event details, message, severity level,
    /// module, and module version.
    ///
    /// - Parameters:
    ///   - event: The event to be logged, typically represented by a name or identifier.
    ///   - eventMessage: The message to be logged, providing context or details about the event.
    ///   - severity: The severity level of the log, defaulting to `.info`. Severity can range from informational logs
    /// to error-level logs.
    func log(event: Event, eventMessage: EventMessage, severity: TruvideoSdkLogSeverity = .info) {
        sdk.log.add(
            log: TruvideoSdkLog(
                tag: event.name,
                message: eventMessage.message,
                severity: severity,
                module: .media,
                moduleVersion: moduleVersion
            )
        )
    }
}
