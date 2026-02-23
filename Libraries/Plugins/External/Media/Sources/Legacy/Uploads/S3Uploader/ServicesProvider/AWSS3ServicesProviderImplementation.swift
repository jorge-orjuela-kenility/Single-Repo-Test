//
// Copyright © 2026 TruVideo. All rights reserved.
//

import Foundation

@_implementationOnly import AWSS3

/// An implementation to decouple from AWSS3
final class AWSS3ServicesProviderImplementation: AWSS3ServicesProvider {
    // MARK: Private Properties

    private let credentialProvider: AWSCredentialProvider

    // MARK: - S3 Dependencies

    /// S3 transfer utility
    private var transferUtility: AWSS3TransferUtility?

    /// S3 transfer task
    private var s3UploadTask: AWSS3TransferUtilityUploadTask?

    // MARK: Initializer

    /// Creates a new instance of `AWSS3ServicesProviderImplementation`
    ///
    /// - Parameter credentialsProvider: The credentials provider to authenticate with AWS.
    init(credentialProvider: AWSCredentialProvider) {
        self.credentialProvider = credentialProvider
    }

    // MARK: - AWSS3ServicesProvider

    func registerServicesIfNeeded() {
        let credential = credentialProvider.awsCredential()
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: credential.region.s3Region,
            identityPoolId: credential.poolId
        )
        let serviceConfiguration = AWSServiceConfiguration(
            region: credential.region.s3Region,
            credentialsProvider: credentialsProvider
        )

        let poolId = credential.poolId
        let region = credential.region
        let accelerate = credential.accelerate
        let transferUtilityKey = "\(poolId)_\(region)_\(accelerate)"

        let transferUtilityConfigurationWithRetry = AWSS3TransferUtilityConfiguration()
        transferUtilityConfigurationWithRetry.retryLimit = 1
        transferUtilityConfigurationWithRetry.timeoutIntervalForResource = 15 * 60
        transferUtilityConfigurationWithRetry.isAccelerateModeEnabled = credential.accelerate

        guard AWSS3TransferUtility.s3TransferUtility(forKey: transferUtilityKey) == nil else {
            transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: transferUtilityKey)
            return
        }

        // swiftlint:disable force_unwrapping
        AWSS3TransferUtility.register(
            with: serviceConfiguration!,
            transferUtilityConfiguration: transferUtilityConfigurationWithRetry,
            forKey: transferUtilityKey
        )

        transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: transferUtilityKey)
    }

    func uploadedFile(
        uploadData: AWSS3UploadData,
        onProgressChange: @escaping (Double) -> Void,
        onTaskStarted: @escaping (String) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let credential = credentialProvider.awsCredential()

        guard let transferUtility else {
            return completion(
                .failure(TruvideoSdkMediaError.uploadError(message: "Error registering services"))
            )
        }

        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { task, error in
            if let error {
                completion(
                    .failure(error)
                )
            } else {
                guard let uploadedFileURL = task.response?.url else {
                    return completion(.failure(TruvideoSdkMediaError.generic))
                }

                completion(.success(uploadedFileURL))
            }
        }

        let expression = AWSS3TransferUtilityUploadExpression()
        expression.setValue("public-read", forRequestHeader: "x-amz-acl")
        expression.progressBlock = { _, progress in
            onProgressChange(progress.fractionCompleted)
        }
        transferUtility.uploadFile(
            uploadData.fileURL,
            bucket: credential.bucket,
            key: uploadData.fileKey,
            contentType: uploadData.mimeType,
            expression: expression,
            completionHandler: completionHandler
        ).continueWith { [weak self] task -> Any? in
            self?.s3UploadTask = task.result
            if let task = task.result {
                onTaskStarted(task.transferID)
            }
            if let error = task.error {
                return completion(.failure(error))
            }
            return nil
        }
    }

    func cancelUpload() {
        s3UploadTask?.cancel()
        s3UploadTask = nil
    }

    func pause() {
        s3UploadTask?.suspend()
    }

    func resume() {
        s3UploadTask?.resume()
    }
}

private extension String {
    var s3Region: AWSRegionType {
        self.aws_regionTypeValue()
    }
}
