//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation
internal import TruVideoApi

/// Implementation used to decouple from the `shared` module
final class AWSS3CredentialProvider: AWSCredentialProvider {
    // MARK: - Private Properties

    private let settingsKey = "truvideo-sdk-settings"
    private let userDefaults: UserDefaults

    // MARK: - Properties

    var accelerate: Bool { false }

    // MARK: - Computed Properties

    var bucket: String {
        s3Configuration?.bucketName ?? ""
    }

    var folder: String {
        guard let configuration = s3Configuration else {
            return ""
        }

        if !configuration.bucketForMedia.isEmpty {
            return configuration.bucketForMedia
        }

        return configuration.newBucketFolderForMedia
    }

    var isUserAuthenticated: Bool {
        s3Configuration != nil
    }

    var poolId: String {
        s3Configuration?.identityPoolId ?? ""
    }

    var region: String {
        s3Configuration?.region ?? ""
    }

    private var s3Configuration: DeviceSetting.S3Configuration? {
        loadSettings()?.s3Configuration
    }

    // MARK: - Initializer

    init(userDefaults: UserDefaults? = UserDefaults(suiteName: "truvideo-sdk-common-settings")) {
        self.userDefaults = userDefaults ?? .standard
    }

    // MARK: - Instance methods

    func awsCredential() -> AWSS3Credential {
        AWSS3Credential(
            accelerate: accelerate,
            bucket: bucket,
            folder: folder,
            isUserAuthenticated: isUserAuthenticated,
            poolId: poolId,
            region: region
        )
    }

    // MARK: - Private methods

    private func loadSettings() -> DeviceSetting? {
        guard
            let rawSettings = userDefaults.string(forKey: settingsKey),
            let data = rawSettings.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(DeviceSetting.self, from: data)
    }
}
