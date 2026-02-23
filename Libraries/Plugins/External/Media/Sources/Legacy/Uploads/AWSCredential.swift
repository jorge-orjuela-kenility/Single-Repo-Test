//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

/// Abstraction used to provide S3 credentials
protocol AWSCredentialProvider {
    func awsCredential() -> AWSS3Credential
}

/// A struct that provides the necessary credentials and configuration for accessing AWS S3 services.
///
/// `AWSS3Credential` contains essential information
/// such as the AWS region, bucket name, identity pool ID, and specific bucket folder configurations.
/// This struct is used to authenticate and interact with AWS S3.
struct AWSS3Credential {
    /// The accelerate flag
    let accelerate: Bool

    /// The bucket name
    let bucket: String

    /// The remote folder where the file will be stored
    let folder: String

    /// Flag indicating wether the user is authenticated or not
    let isUserAuthenticated: Bool

    /// The authentication pool id
    let poolId: String

    /// The bucket region
    let region: String
}
