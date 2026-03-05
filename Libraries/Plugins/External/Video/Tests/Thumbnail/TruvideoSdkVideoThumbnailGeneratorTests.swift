//
//  TruvideoSdkVideoThumbnailGeneratorTests.swift
//  TruvideoSdkVideoTests
//
//  Created by Victor Arana on 12/6/23.
//

@testable import TruvideoSdkVideo
import XCTest

final class TruvideoSdkVideoThumbnailGeneratorTests: XCTestCase {
    private var sut: TruvideoSdkVideoThumbnailGenerator!
    private var inputURL: URL!
    private var outputURL: String!
    private var position: TimeInterval!

    // MARK: - Test Constants

    private let videoWidht = 20
    private let videoHeight = 20
    private let videoDuration: TimeInterval = 4

    override func setUp() {
        super.setUp()

        sut = makeSUT()
        outputURL = generateOutputURL()
        position = videoDuration / 2.0
    }

    override func tearDown() async throws {
        try await super.tearDown()

        sut = nil
        position = nil
        try deleteFile(at: inputURL)
        inputURL = nil
        outputURL = nil
    }

    func test_cannotGenerateThumbailIfNotAuthenticated() async {
        sut = makeSUT(isAuthenticated: false)
        inputURL = URL(string: "file://not-found.mp4")!
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        await expect(input,
                     toCompleteWith: .userNotAuthenticated,
                     "Should not create a thumbnail if not authenticated")
    }

    func test_cannotGenerateThumbailFromNotExistingVideo() async {
        inputURL = URL(string: "file://not-found.mp4")!
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        await expect(input,
                     toCompleteWith: .notFoundVideo,
                     "Should not create a thumbnail from not existing video")
    }

    func test_cannotGenerateThumbailWithNegativeWidth() async throws {
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position,
                                                        width: -1, height: 100)

        await expect(input,
                     toCompleteWith: .invalidThumbnailWidth,
                     "Should not create a thumbnail with negative width")
    }

    func test_cannotGenerateThumbailWithNegativeHeight() async throws {
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position,
                                                        width: 100, height: -1)

        await expect(input,
                     toCompleteWith: .invalidThumbnailHeight,
                     "Should not create a thumbnail with negative height")
    }

    func test_cannotGenerateThumbailForNegativePosition() async throws {
        position = videoDuration * -1.0 * 1000
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        await expect(input,
                     toCompleteWith: .invalidPositionInVideo,
                     "Should not create a thumbnail for negative position")
    }

    func test_cannotGenerateThumbailForPositionBiggerThanDuration() async throws {
        position = videoDuration * 2 * 1000
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        await expect(input,
                     toCompleteWith: .invalidPositionInVideo,
                     "Should not create a thumbnail for negative position")
    }

    func test_canGenerateThumbailForFirstPosition() async throws {
        position = 0
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        try await expectSucceesFor(input)
    }

    func test_canGenerateThumbailForPreviousPostionToLastOne() async throws {
        position = videoDuration * 0.99 * 1000
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        try await expectSucceesFor(input)
    }

    func test_cannotGenerateThumbailForLastPosition() async throws {
        position = videoDuration * 1000
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        await expect(input,
                     toCompleteWith: .invalidPositionInVideo,
                     "Should not create a thumbnail for last position")
    }

    func test_canGenerateThumbailWithDefaultDimensions() async throws {
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        try await expectSucceesFor(input)
    }

    func test_canGenerateThumbailWithCustomDimensions() async throws {
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position,
                                                        width: 500, height: 500)

        try await expectSucceesFor(input)
    }

    func test_canOverrideExistingThumbnailImage() async throws {
        inputURL = try await getExistingVideoURL()
        let input = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                        output: .files(fileName: outputURL), position: position)

        try await expectSucceesFor(input)

        let input2 = TruvideoSdkVideoThumbnailInputVideo(input: .init(url: inputURL),
                                                         output: .files(fileName: outputURL), position: position,
                                                         width: 100, height: 300)

        try await expectSucceesFor(input2)
    }

    // MARK: - Helpers

    private func makeSUT(isAuthenticated: Bool = true) -> TruvideoSdkVideoThumbnailGenerator {
        let manager = TruvideoCredentialsManagerSpy(isUserAuthenticated: isAuthenticated)
        return TruvideoSdkVideoThumbnailGeneratorImplementation(credentialsManager: manager)
    }

    private func expect(_ input: TruvideoSdkVideoThumbnailInputVideo,
                        toCompleteWith expectedErrror: TruvideoSdkVideoError, _ detail: String,
                        file: StaticString = #file, line: UInt = #line) async {
        do {
            _ = try await sut.generateThumbnail(for: input)
            XCTFail(detail, file: file, line: line)
        } catch {
            XCTAssertEqual(error as! TruvideoSdkVideoError, expectedErrror, file: file, line: line)
        }
    }

    private func expectSucceesFor(_ input: TruvideoSdkVideoThumbnailInputVideo, file: StaticString = #file,
                                  line: UInt = #line) async throws {
        let result = try await sut.generateThumbnail(for: input)
        if !FileManager.default.fileExists(atPath: result.generatedThumbnailURL.path) {
            XCTFail("Thumbnail was not correctly generated", file: file, line: line)
        }
        try deleteFile(at: result.generatedThumbnailURL)
    }

    private func getExistingVideoURL() async throws -> URL {
        let outputURL = TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: "mp4")
        try await generateTestVideo(in: outputURL, width: videoWidht, height: videoHeight, duration: videoDuration)
        return outputURL
    }

    private func deleteFile(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(atPath: url.path)
        }
    }

    private func generateOutputURL() -> String {
        UUID().uuidString
    }
}
