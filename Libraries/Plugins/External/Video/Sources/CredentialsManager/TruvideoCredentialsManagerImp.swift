//
//  TruvideoCredentialsManagerImp.swift
//  TruvideoSdkNoiseCancelling
//
//  Created by Luis Francisco Piura Mejia on 23/10/23.
//

import Foundation
@_implementationOnly import shared

final class TruvideoCredentialsManagerImp: TruvideoCredentialsManager {
    private let sdk = TruvideoSdkCommonKt.sdk_common

    func isUserAuthenticated() -> Bool {
        do {
            let value = try sdk.auth.isAuthenticated()
            if !value {
                Logger.logError(event: .validateAuth, eventMessage: .notAuthenticated)
            }
            return value
        } catch {
            return false
        }
    }
}
