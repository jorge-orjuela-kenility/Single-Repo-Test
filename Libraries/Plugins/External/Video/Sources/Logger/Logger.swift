//
//  Logger.swift
//  TruvideoSdkVideo
//
//  Created by Victor Arana on 4/29/24.
//

import Foundation

@_implementationOnly import shared

class Logger {
    private static let sdk = TruvideoSdkCommonKt.sdk_common

    private static var savedModuleVersion: String?

    private static var moduleVersion: String {
        if let savedModuleVersion {
            return savedModuleVersion
        }
        let bundle = Bundle(for: Logger.self)

        guard
            let path = bundle.path(forResource: "version", ofType: "properties"),
            let contents = try? String(contentsOfFile: path)
        else {
            return "unknown"
        }

        let lines = contents.components(separatedBy: .newlines)

        for line in lines {
            let components = line.components(separatedBy: "=")
            if components.count == 2, components[0] == "version" {
                let versionNumber = components[1]
                savedModuleVersion = versionNumber
                return versionNumber
            }
        }
        return "unknown"
    }

    static func addLog(event: Event, eventMessage: EventMessage) {
        sdk.log.add(
            log: TruvideoSdkLog(
                tag: event.name,
                message: eventMessage.message,
                severity: .info,
                module: .video,
                moduleVersion: moduleVersion
            )
        )
    }

    static func logError(event: Event, eventMessage: EventMessage) {
        sdk.log.add(
            log: TruvideoSdkLog(
                tag: event.name,
                message: eventMessage.message,
                severity: .error,
                module: .video,
                moduleVersion: moduleVersion
            )
        )
    }
}
