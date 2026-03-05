//
// Copyright © 2025 TruVideo. All rights reserved.
//

import CloudStorageKit
import CloudStorageKitTesting
import Foundation
import Network
import Telemetry
import Testing
import TruVideoFoundation
import TruvideoSdkTesting
import UtilitiesTesting

@testable import TruvideoSdk

struct UploadProcessorTests {
    // MARK: - Private Properties

    private let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
        UUID().uuidString,
        isDirectory: true
    )

    private let report = TelemetryReport(
        events: [
            TelemetryReport.Event(name: "Event1", severity: .info, source: "unit-test")
        ],
        context: Context(
            device: Context.Device(
                battery: Context.Device.Battery(
                    isLowPowerMode: false,
                    level: 0.85,
                    state: "charging"
                ),
                cpuArchitecture: "arm64",
                disk: Context.Device.Disk(free: 128_000_000_000, total: 256_000_000_000),
                manufacturer: "Apple",
                memory: Context.Device.Memory(free: 4_000_000_000, total: 8_000_000_000),
                model: "MacBookPro18,3",
                processorCount: 10,
                thermalState: "nominal",
                uptimeSeconds: 3600
            ),
            osInfo: Context.OsInfo(name: "macOS", version: "14.5"),
            sdks: ["TelemetrySDK": "1.0.0", "Networking": "2.3.1"]
        ),
        session: Session(installationId: UUID())
    )

    // MARK: - Tests

    @Test
    func testThatDidReceisveReportShouldFailsOnTaskError() async throws {
        // Given
        let cloudStorage = CloudStorageMock()
        let pathMonitor = NetworkPathMonitorMock()
        let uploadTask = UploadDataTaskMock()
        let sut = UploadProcessor(pathMonitor: pathMonitor, storageURL: tempURL)

        let fileURL = tempURL.appendingPathComponent("report.json")
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data([1, 2, 3]))

        sut.s3Configuration = .init(
            bucketName: "bucketName",
            bucketForLogs: "bucketForLogs",
            bucketForMedia: "bucketForMedia",
            identityId: "identityId",
            identityPoolId: "identityPoolId",
            newBucketFolderForLogs: "newBucketFolderForLogs",
            newBucketFolderForMedia: "newBucketFolderForMedia",
            region: "region"
        )

        cloudStorage.uploadDataTask = uploadTask

        // When
        sut.didReceive(report)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Simulamos error del upload
        uploadTask.complete(with: .failure(UtilityError(kind: .unknown)))

        // Then
        #expect(FileManager.default.fileExists(atPath: fileURL.path) == true)
    }

    @Test
    func testThatDidReceiveReportDoesNotCrashWhenWriteFails() async throws {
        // Given
        let fileWriter = FileWriterMock()
        let pathMonitor = NetworkPathMonitorMock()
        let cloudStorage = CloudStorageMock()
        let sut = UploadProcessor(pathMonitor: pathMonitor, storageURL: tempURL)

        sut.s3Configuration = .init(
            bucketName: "bucketName",
            bucketForLogs: "bucketForLogs",
            bucketForMedia: "bucketForMedia",
            identityId: "identityId",
            identityPoolId: "identityPoolId",
            newBucketFolderForLogs: "logs",
            newBucketFolderForMedia: "media",
            region: "region"
        )

        // When
        fileWriter.error = UtilityError(kind: .unknown)
        sut.didReceive(report)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        #expect(cloudStorage.uploadDataTask == nil)
    }

    @Test
    func testThatDidReceiveReportDoesNotUploadWhenFileIsEmpty() async throws {
        // Given
        let pathMonitor = NetworkPathMonitorMock()
        let cloudStorage = CloudStorageMock()
        let sut = UploadProcessor(pathMonitor: pathMonitor, storageURL: tempURL)

        sut.s3Configuration = .init(
            bucketName: "bucketName",
            bucketForLogs: "bucketForLogs",
            bucketForMedia: "bucketForMedia",
            identityId: "identityId",
            identityPoolId: "identityPoolId",
            newBucketFolderForLogs: "logs",
            newBucketFolderForMedia: "media",
            region: "us-west-2"
        )

        let fileURL = tempURL.appendingPathComponent("report.json")

        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())

        // When
        sut.didReceive(report)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        #expect(cloudStorage.uploadDataTask == nil)
    }

    @Test
    func testThatDidReceiveReportDoesNotUploadWhenS3ConfigurationIsNil() async throws {
        // Given
        let cloudStorage = CloudStorageMock()
        let pathMonitor = NetworkPathMonitorMock()
        let sut = UploadProcessor(pathMonitor: pathMonitor, storageURL: tempURL)

        sut.s3Configuration = nil

        // When
        sut.didReceive(report)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        #expect(cloudStorage.uploadDataTask == nil)
    }

    @Test
    func testThatDidReceiveReportIsWrittenToFileBeforeUpload() async throws {
        // Given
        let fileWriter = FileWriterMock()
        let cloudStorage = CloudStorageMock()
        let uploadDataTask = UploadDataTaskMock()
        let sut = UploadProcessor()

        // When
        sut.s3Configuration = .init(
            bucketName: "bucketName",
            bucketForLogs: "bucketForLogs",
            bucketForMedia: "bucketForMedia",
            identityId: "identityId",
            identityPoolId: "identityPoolId",
            newBucketFolderForLogs: "newBucketFolderForLogs",
            newBucketFolderForMedia: "newBucketFolderForMedia",
            region: "region"
        )

        cloudStorage.uploadDataTask = uploadDataTask
        fileWriter.writtenReport = report

        sut.didReceive(report)

        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        #expect(fileWriter.writtenReport != nil)
    }

    @Test
    func testThatDidReceiveReportUploadsAndRemoveLocalFile() async throws {
        // Given
        let cloudStorage = CloudStorageMock()
        let expectedURL = URL(string: "https://example.com/file.json")!
        let pathMonitor = NetworkPathMonitorMock()
        let uploadDataTask = UploadDataTaskMock()
        let sut = UploadProcessor(pathMonitor: pathMonitor, storageURL: tempURL)

        // When
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

        sut.s3Configuration = .init(
            bucketName: "bucketName",
            bucketForLogs: "bucketForLogs",
            bucketForMedia: "bucketForMedia",
            identityId: "identityId",
            identityPoolId: "identityPoolId",
            newBucketFolderForLogs: "/newBucketFolderForLogs",
            newBucketFolderForMedia: "newBucketFolderForMedia",
            region: "region"
        )

        cloudStorage.uploadDataTask = uploadDataTask

        sut.didReceive(report)

        try await Task.sleep(nanoseconds: 200_000_000)

        cloudStorage.uploadDataTask?.complete(with: .success(expectedURL))
        _ = cloudStorage.uploadDataTask?.resume()

        // Then
        #expect(cloudStorage.uploadDataTask?.resumeCallCount == 1)
    }

    @Test
    func testThatDidReceiveReportShouldFailsOnTaskError() async throws {
        // Given
        let cloudStorage = CloudStorageMock()
        let pathMonitor = NetworkPathMonitorMock()
        let uploadTask = UploadDataTaskMock()
        let sut = UploadProcessor(pathMonitor: pathMonitor, storageURL: tempURL)
        let fileURL = tempURL.appendingPathComponent("report.json")

        // When
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

        sut.s3Configuration = .init(
            bucketName: "bucketName",
            bucketForLogs: "bucketForLogs",
            bucketForMedia: "bucketForMedia",
            identityId: "identityId",
            identityPoolId: "identityPoolId",
            newBucketFolderForLogs: "newBucketFolderForLogs",
            newBucketFolderForMedia: "newBucketFolderForMedia",
            region: "region"
        )

        cloudStorage.uploadDataTask = uploadTask

        sut.didReceive(report)

        try await Task.sleep(nanoseconds: 200_000_000)

        cloudStorage.uploadDataTask?.onCompleteHandler?(.failure(UtilityError(kind: .unknown)))
        _ = cloudStorage.uploadDataTask?.resume()

        // Then
        #expect(cloudStorage.uploadDataTask?.resumeCallCount == 1)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test
    func testThatDidReceiveReportDoesNotUploadWhenNetworkUnsatisfied() async throws {
        // Given
        let cloudStorage = CloudStorageMock()
        let networkPath = NetworkPathMock(status: .unsatisfied)
        let pathMonitor = NetworkPathMonitorMock(initialPath: networkPath)
        let sut = UploadProcessor(pathMonitor: pathMonitor, storageURL: tempURL)

        // When
        sut.s3Configuration = .init(
            bucketName: "bucketName",
            bucketForLogs: "bucketForLogs",
            bucketForMedia: "bucketForMedia",
            identityId: "identityId",
            identityPoolId: "identityPoolId",
            newBucketFolderForLogs: "newBucketFolderForLogs",
            newBucketFolderForMedia: "newBucketFolderForMedia",
            region: "region"
        )

        sut.didReceive(report)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        #expect(cloudStorage.uploadDataTask == nil)
    }
}
