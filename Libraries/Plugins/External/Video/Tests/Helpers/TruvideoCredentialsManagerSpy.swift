//
//  TruvideoCredentialsManagerSpy.swift
//  TruvideoSdkVideoTests
//
//  Created by Victor Arana on 12/8/23.
//

import Foundation
@testable import TruvideoSdkVideo

final class TruvideoCredentialsManagerSpy: TruvideoCredentialsManager {
    let isAuthenticated: Bool

    init(isUserAuthenticated: Bool = true) {
        self.isAuthenticated = isUserAuthenticated
    }

    func isUserAuthenticated() -> Bool {
        isAuthenticated
    }
}
