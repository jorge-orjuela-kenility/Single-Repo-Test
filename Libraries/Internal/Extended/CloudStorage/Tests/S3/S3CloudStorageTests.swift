//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AWSS3
import CloudStorageKitTesting
import DI
import Foundation
import Networking
import NetworkingTesting
import Testing
import Utilities

@testable import CloudStorageKit

struct S3CloudStorageTests {
    // MARK: - Properties

    let monitor = S3TaskMonitorMock()
    let transferUtility = S3TransferUtilityProtocolMock()
    let session = SessionMock()
    let uploadTaskMock = UploadTaskMock()

    // MARK: - Tests

    @Test
    func testThatInitializerSucceedsWithValidConfiguration() throws {
        // Given
        let sut = try S3CloudStorage(
            region: .usWest2,
            bucketName: "bucketName_test",
            poolId: "poolId-test",
            isAccelerateModeEnabled: false
        )

        // When, Then
        #expect(sut.transferUtility is AWSS3TransferUtility)
    }

    // MARK: - UploadTask

    @Test
    func testThatUploadTaskCreatedNewTask() async throws {
        // Given
        let sut = S3CloudStorage(
            bucketName: "bucketName_test",
            transferUtility: transferUtility,
            monitor: monitor
        )

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())
        let task = sut.upload(Data("fake".utf8), fileName: "fileName", contentType: .jpeg) as? S3UploadDataTask

        try await Task.sleep(nanoseconds: 5_000_000)

        // Then
        #expect(sut.activeUploadTasks.count == 1)
        #expect(task?.state == .initialized)
    }

    @Test
    func testThatUploadTaskDidCompleteRemovesTaskFromActiveUploadTasks() async throws {
        // Given
        let sut = S3CloudStorage(
            bucketName: "bucketName_test",
            transferUtility: transferUtility,
            monitor: monitor
        )

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())

        let task = sut.upload(Data("fake".utf8), fileName: "fileName", contentType: .jpeg) as? S3UploadDataTask

        try await Task.sleep(nanoseconds: 5_000_000)

        transferUtility.completionHandler?(AWSS3TransferUtilityUploadTask(), nil)

        try await Task.sleep(nanoseconds: 5_000_000)

        // Then
        #expect(sut.activeUploadTasks.count == 0)
        #expect(monitor.didFinishUploadTaskCallCount == 1)
        #expect(task?.state == .finished)
    }

    @Test
    func testThatUploadTaskOnCompleteFailsWhenURLIsMissing() async throws {
        // Given
        let sut = S3CloudStorage(
            bucketName: "bucket_test",
            transferUtility: transferUtility,
            monitor: monitor
        )
        var capturedResult: Result<URL, UtilityError>?

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())

        let dataTask = sut.upload(Data("file".utf8), fileName: "test.png", contentType: .png) as? S3UploadDataTask

        dataTask?.response = nil
        dataTask?.error = nil

        dataTask?.onComplete { result in
            capturedResult = result
        }

        dataTask?.completions.forEach { $0() }

        // Then
        if case let .failure(error) = capturedResult {
            #expect(error.kind == .CloudStorageErrorReason.missingUploadURL)
            #expect(error.failureReason == "Upload finished but no URL returned.")
        }
    }

    @Test
    func testThatDidCreateUploadTaskShouldSucceedWhenStateIsResumed() async throws {
        // Given
        let sut = S3CloudStorage(bucketName: "bucket_test", transferUtility: transferUtility, monitor: monitor)
        let aWSS3Mock = AWSS3TransferUtilityUploadTaskMock()

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())
        let dataTask = sut.upload(Data("file".utf8), fileName: "test.png", contentType: .png) as? S3UploadDataTask

        dataTask?.state = .resumed

        await dataTask?.didCreate(task: aWSS3Mock)

        // Then
        #expect(aWSS3Mock.didResumeCallCount == 1)
    }

    @Test
    func testThatDidCreateUploadTaskShouldSucceedWhenStateIsCancelled() async throws {
        // Given
        let sut = S3CloudStorage(bucketName: "bucket_test", transferUtility: transferUtility, monitor: monitor)
        let aWSS3Mock = AWSS3TransferUtilityUploadTaskMock()

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())
        let dataTask = sut.upload(Data("file".utf8), fileName: "test.png", contentType: .png) as? S3UploadDataTask

        dataTask?.state = .cancelled

        await dataTask?.didCreate(task: aWSS3Mock)

        // Then
        #expect(aWSS3Mock.didCancelCallCount == 1)
    }

    @Test
    func testThatDidCreateUploadTaskShouldSucceedWhenStateIsSuspended() async throws {
        // Given
        let sut = S3CloudStorage(bucketName: "bucket_test", transferUtility: transferUtility, monitor: monitor)
        let aWSS3Mock = AWSS3TransferUtilityUploadTaskMock()

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())
        let dataTask = sut.upload(Data("file".utf8), fileName: "test.png", contentType: .png) as? S3UploadDataTask

        dataTask?.state = .suspended

        await dataTask?.didCreate(task: aWSS3Mock)

        // Then
        #expect(aWSS3Mock.didSuspendCallCount == 1)
    }

    @Test
    func testThatUploadTaskOnCompleteSucceedsWhenURLIsPresent() async throws {
        // Given
        let sut = S3CloudStorage(
            bucketName: "bucket_test",
            transferUtility: transferUtility,
            monitor: monitor
        )
        var capturedResult: Result<URL, UtilityError>?
        let expectedURL = URL(string: "https://bucket_test.s3.amazonaws.com/test.png")!

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())

        let dataTask = sut.upload(Data("file".utf8), fileName: "test.png", contentType: .png) as? S3UploadDataTask

        dataTask?.response = HTTPURLResponse(
            url: expectedURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        dataTask?.onComplete { result in
            capturedResult = result
        }

        dataTask?.completions.forEach { $0() }

        // Then
        if case let .success(url) = capturedResult {
            #expect(url == expectedURL)
        }
    }

    @Test
    func testThatUploadTaskFailsWhenCompletionReturnsError() async throws {
        // Given
        let sut = S3CloudStorage(
            bucketName: "bucketName_test",
            transferUtility: transferUtility,
            monitor: monitor
        )

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())

        let task = sut.upload(Data("fake".utf8), fileName: "file-error", contentType: .jpeg) as? S3UploadDataTask

        try await Task.sleep(nanoseconds: 5_000_000)

        transferUtility.completionHandler?(AWSS3TransferUtilityUploadTask(), NSError(domain: "tests", code: 1))

        try await Task.sleep(nanoseconds: 5_000_000)

        // Then
        #expect(task?.error?.kind == .CloudStorageErrorReason.failedToUploadData)
        #expect(task?.state == .finished)
        #expect(monitor.didFinishUploadTaskCallCount == 1)
    }

    @Test
    func testThatUploadTaskDidCreateWhenStateIsInitializedDoesNotChangeTaskState() async throws {
        // Given
        let sut = S3CloudStorage(
            bucketName: "bucketName_test",
            transferUtility: transferUtility,
            monitor: monitor
        )

        // When
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())

        let task = sut.upload(Data("fake".utf8), fileName: "file-init", contentType: .jpeg) as? S3UploadDataTask

        try await Task.sleep(nanoseconds: 5_000_000)

        // Then
        #expect(task?.state == .initialized)
    }

    @Test
    func testThatUploadTaskPauseShouldSucceeds() async throws {
        // Given
        let sut = S3CloudStorage(bucketName: "bucket", transferUtility: transferUtility, monitor: monitor)
        let awsTask = AWSS3TransferUtilityUploadTask()

        // When, then
        transferUtility.result = AWSTask(result: awsTask)
        let task = sut.upload(Data("data".utf8), fileName: "file", contentType: .jpeg) as? S3UploadDataTask

        #expect(task?.state == .initialized)

        try await Task.sleep(nanoseconds: 2_000_000)

        task?.pause()
        try await Task.sleep(nanoseconds: 5_000_000)

        #expect(task?.state == .suspended)
        #expect(monitor.taskDidSuspendCallCount == 1)
    }

    @Test
    func testThatUploadTaskCancelShouldSucceeds() async throws {
        // Given
        let sut = S3CloudStorage(bucketName: "bucket", transferUtility: transferUtility, monitor: monitor)
        let awsTask = AWSS3TransferUtilityUploadTask()

        // When, then
        transferUtility.result = AWSTask(result: awsTask)
        let task = sut.upload(Data("data".utf8), fileName: "file", contentType: .jpeg) as? S3UploadDataTask

        #expect(task?.state == .initialized)

        try await Task.sleep(nanoseconds: 2_000_000)

        task?.cancel()
        try await Task.sleep(nanoseconds: 5_000_000)

        #expect(task?.state == .cancelled)
        #expect(monitor.taskDidCancelCallCount == 1)
    }

    @Test
    func testThatUploadTaskPausesAndResumesShouldSucceeds() async throws {
        // Given
        let sut = S3CloudStorage(bucketName: "bucket", transferUtility: transferUtility, monitor: monitor)

        // When, Then
        transferUtility.result = AWSTask(result: AWSS3TransferUtilityUploadTask())

        let task = sut.upload(Data("data".utf8), fileName: "file", contentType: .jpeg) as? S3UploadDataTask
        #expect(task?.state == .initialized)

        try await Task.sleep(nanoseconds: 2_000_000)

        task?.pause()
        try await Task.sleep(nanoseconds: 5_000_000)
        #expect(task?.state == .suspended)

        task?.resume()
        try await Task.sleep(nanoseconds: 5_000_000)
        #expect(task?.state == .resumed)

        #expect(monitor.taskDidSuspendCallCount == 1)
        #expect(monitor.taskDidResumeCallCount == 1)
    }

    @Test
    func testThatUploadFailsWhenAWSTaskHasNoResultShouldSucceeds() async throws {
        // Given
        let sut = S3CloudStorage(
            bucketName: "bucketName_test",
            transferUtility: transferUtility,
            monitor: monitor
        )

        // When
        transferUtility.result = AWSTask(error: NSError(domain: "test", code: 1))

        let task = sut.upload(Data("fake".utf8), fileName: "file", contentType: .jpeg) as? S3UploadDataTask

        try await Task.sleep(nanoseconds: 5_000_000)

        // Then
        #expect(task?.state == .finished)
        #expect(task?.error?.kind == .CloudStorageErrorReason.uploadTaskCreationFailed)
        #expect(sut.activeUploadTasks.count == 0)
        #expect(monitor.didFailToCreateUploadTaskCallCount == 1)
        #expect(monitor.taskDidFinishCallCount == 1)
    }

    // MARK: - UploadTaskState Tests

    @Test
    func testThatTransitionToInitializedIsInvalidFromResumed() async throws {
        // Given, When, Then
        #expect(UploadTaskState.resumed.canTransition(to: .initialized) == false)
    }

    @Test
    func testThatTransitionToInitializedIsInvalidFromSuspended() async throws {
        // Given, When, Then
        #expect(UploadTaskState.suspended.canTransition(to: .initialized) == false)
    }

    @Test
    func testThatTransitionToInitializedIsInvalidFromCancelled() async throws {
        // Given, When, Then
        #expect(UploadTaskState.cancelled.canTransition(to: .initialized) == false)
    }
}
