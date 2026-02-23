//
// Copyright © 2025 TruVideo. All rights reserved.
//

internal import CloudStorageKit
internal import DI
import Foundation
internal import Network
internal import Telemetry
import TruVideoApi
internal import TruVideoFoundation
import UIKit
internal import Utilities

/// A telemetry subscriber that processes and uploads telemetry reports to cloud storage.
///
/// This class implements the TelemetryManagerSubscriber protocol to handle
/// telemetry report processing and cloud upload functionality. It receives
/// telemetry reports from the TelemetryManager, writes them to local storage,
/// and uploads them to cloud storage when network connectivity is available.
///
/// The processor uses a dedicated dispatch queue for background operations
/// and monitors network connectivity to ensure uploads only occur when
/// the device is online. It implements automatic cleanup of local files
/// after successful cloud uploads to prevent storage bloat.
final class UploadProcessor: TelemetryManagerSubscriber {
    // MARK: - Private Properties

    private var fileURL: URL
    private let queue = DispatchQueue(label: "com.truvideo.uploadProcessor.queue")
    private let pathMonitor: any NetworkPathMonitor

    // MARK: - Private Properties

    private var cloudStorage: CloudStorage?

    // MARK: - Dependencies

    @Dependency(\.fileWriter)
    private var fileWriter: FileWriter

    // MARK: - Properties

    /// The AWS S3 upload configuration associated with the current device settings.
    ///
    /// This property contains the S3-related configuration values—such as bucket name,
    /// region, access credentials, and upload parameters—used by the SDK when uploading
    /// media or other resources to Amazon S3.
    ///
    /// If the configuration is unavailable (`nil`), S3 uploads should be considered
    /// disabled or unsupported for the current device context.
    var s3Configuration: DeviceSetting.S3Configuration?

    // MARK: - Initializer

    /// Creates a new upload processor with cloud storage and network monitoring.
    ///
    /// This initializer sets up the upload processor with the necessary
    /// dependencies for cloud storage operations and network connectivity
    /// monitoring. Network monitoring is started immediately to ensure
    /// connectivity changes are detected from the beginning.
    ///
    /// - Parameters:
    ///   - pathMonitor: Network path monitor for connectivity detection.
    ///   - storageURL: Local storage directory for telemetry data
    init(
        pathMonitor: some NetworkPathMonitor = NWPathMonitor(),
        storageURL: URL = FileManager.default.telemetryDirectory
    ) {
        self.fileURL = storageURL.appendingPathComponent("report.json")
        self.pathMonitor = pathMonitor

        pathMonitor.start(queue: queue)
    }

    // MARK: - Deinitializer

    deinit {
        pathMonitor.cancel()
    }

    // MARK: - TelemetryManagerSubscriber

    /// Called whenever a new telemetry report is published by the `TelemetryManager`.
    ///
    /// - Parameter report: A fully structured telemetry report containing contextual metadata, breadcrumbs, and event
    /// details.
    func didReceive(_ report: TelemetryReport) {
        Task {
            do {
                try fileWriter.write(report, to: fileURL)

                let data = try Data(contentsOf: fileURL)

                if
                    /// The folder name where should be located the logs.
                    let folderURL = s3Configuration?.newBucketFolderForLogs,

                    /// `cloudStorage` must be successfully created from the `cloudStorageProvider`.
                    let cloudStorage = try makeStorage(),

                    /// The current network path status must be `.satisfied` (device is online).
                    pathMonitor.currentPath.status == .satisfied,

                    /// The `data` to be uploaded must not be empty.
                    !data.isEmpty {
                    let folderName = String(folderURL.dropFirst())
                    let fileName = "\(folderName)/\(UUID()).json"

                    cloudStorage.upload(data, fileName: fileName, contentType: .json)
                        .onComplete { [weak self] result in
                            guard let self else { return }

                            guard let error = result.failure else {
                                try? self.fileWriter.remove(at: fileURL)
                                return
                            }

                            print("❌ Upload failed with error: \(error)")
                        }
                        .resume()
                }
            } catch {
                print("Failed to process report: \(error)")
            }
        }
    }

    // MARK: - Private methods

    private func makeStorage() throws(UtilityError) -> CloudStorage? {
        guard let s3Configuration else { return nil }

        guard let cloudStorage else {
            do {
                let cloudStorage = try S3CloudStorage(
                    region: .usWest2,
                    bucketName: s3Configuration.bucketName,
                    poolId: s3Configuration.identityPoolId,
                    isAccelerateModeEnabled: false
                )

                self.cloudStorage = cloudStorage
                return cloudStorage
            } catch {
                throw UtilityError(
                    kind: .CloudStorageErrorReason.makeCloudStorageFailed,
                    underlyingError: error
                )
            }
        }

        return cloudStorage
    }
}

extension ErrorReason {
    /// A collection of error reasons related to cloud storage provider operations.
    ///
    /// The `CloudStorageErrorReason` struct provides a set of static constants
    /// representing various errors that can occur during cloud storage provider
    /// initialization and configuration. These error reasons are used to provide
    /// specific error handling and debugging information for cloud storage-related failures.
    struct CloudStorageErrorReason: Sendable {
        /// Error indicating that the creation of a cloud storage instance has failed.
        ///
        /// This error reason is used when the system is unable to initialize or obtain
        /// a valid cloud storage provider instance. This typically occurs during the
        /// `makeStorage()` method execution when the underlying storage service cannot
        /// be properly configured or initialized.
        static let makeCloudStorageFailed = ErrorReason(rawValue: "makeCloudStorageFailed")
    }
}
