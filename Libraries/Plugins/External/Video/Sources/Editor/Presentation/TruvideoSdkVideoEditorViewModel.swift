//
//  TruvideoSdkVideoEditorViewModel.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 26/12/23.
//

import AVKit
import Combine
import SwiftUI
import TruvideoSdk
import UIKit

final class TruvideoSdkVideoEditorViewModel: ObservableObject {
    @Published var trimmerSize = CGSize.zero
    @Published var thumbnailSize = CGSize.zero
    @Published var trimmerXOffset = CGFloat.zero
    @Published var leftSpaceSize = CGFloat.zero
    @Published var rightSpaceSize = CGFloat.zero {
        didSet {
            showRightWhiteSpace = rightSpaceSize == thumbnailHorizontalPadding
        }
    }

    @Published var showRightWhiteSpace = false
    @Published var trimmerBorderColor = TruvideoColor.gray
    @Published var isTrimming = false
    @Published var isAuthenticated = true
    @Published var error: TruvideoSdkVideoError?
    @Published var stopAt = Double.zero {
        didSet {
            updateRange()
        }
    }

    @Published var didFinishPlaying = false
    @Published var isPlaying = false
    @Published var thumbnails: [UIImage] = .init(repeating: .init(), count: 8)
    @Published var trimmerRange = ""
    @Published private(set) var trimmerStart: Double = 0 {
        didSet {
            updateRange()
        }
    }

    @Published var isTrimmerRangeVisible = false
    @Published var isTrimmerVisible = true
    @Published var isSoundVisible = false
    @Published var isRotationVisible = false
    @Published var videoIsInPortraitMode = true
    @Published var soundIcon = Image(systemName: "speaker.wave.3")
    @Published var soundIconColor = Color.white
    @Published var soundBackgroundColor = TruvideoColor.gray
    @Published var videoRotation = Angle.degrees(0)
    @Published var videoAspectRatio: CGFloat = 0.5
    @Published private(set) var volumeHeight: CGFloat = 192 {
        didSet {
            videoPlayer.volume = Float(volumeHeight / initialVolumeHeight)
            soundIcon = volumeHeight == 0 ? Image(systemName: "speaker.slash") : Image(systemName: "speaker.wave.3")
            soundIconColor = volumeHeight == 0 ? .black : .white
            soundBackgroundColor = volumeHeight == 0 ? TruvideoColor.ambar : TruvideoColor.gray
        }
    }

    private var screenWidth = CGFloat.zero
    private let initialVolumeHeight: CGFloat = 192
    private var previousVolumeHeight = CGFloat.zero
    let spacing: CGFloat = 20
    let tabOptionsHeight: CGFloat = 20
    let spacersMinimumHeight: CGFloat = 20
    let playerActionButtonSize: CGFloat = 50
    private let thumbnailCount = 8
    let trimmerHeight = 64
    let trimmerHorizontalPadding = 16
    let thumbnailListHorizontalPadding: CGFloat = 24
    let thumbnailHorizontalPadding: CGFloat = 24
    var totalTrimmerHorizontalPadding: CGFloat {
        CGFloat(trimmerHorizontalPadding * 2)
    }

    var totalThumbnailListHorizontalPadding: CGFloat {
        thumbnailListHorizontalPadding * 2
    }

    private let editor: TruvideoSdkVideoEditor
    private let videoURL: URL
    private let outputURL: URL
    private let videosInformationGenerator: VideosInformationGenerator
    private let completion: (TruvideoSdkVideoEditorResult) -> Void
    private(set) var videoPlayer: AVPlayer
    private var trimmerRightEdgePosition = CGFloat.zero
    private var videoDuration: Double = 0
    private var currentRotation = 0

    private enum TrimEdge {
        case right
        case left
        case center
        case none
    }

    var trimmerInitialWidth: CGFloat {
        screenWidth - totalTrimmerHorizontalPadding
    }

    private var trimmerCenter: CGFloat {
        trimmerXOffset + (trimmerSize.width / 2)
    }

    private var leftEdgePosition: CGFloat = .zero {
        didSet {
            trimmerXOffset = leftEdgePosition - 12
        }
    }

    private var rightEdgePosition: CGFloat = .zero {
        didSet {
            trimmerRightEdgePosition = rightEdgePosition + 12
        }
    }

    /// An object used for indicating whether the app supports portrait mode to rotate and adjust the UI
    private let orientationManager: TruvideoOrientationInterface

    init(
        truVideoSdk: TruVideoSDK = TruvideoSdk,
        editor: TruvideoSdkVideoEditor = TruvideoSdkVideoEditorImplementation(),
        videosInformationGenerator: VideosInformationGenerator = TruvideoSdkVideoInterfaceImp
            .videosInformationGenerator,
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor? = nil,
        completion: @escaping (TruvideoSdkVideoEditorResult) -> Void
    ) {
        self.orientationManager = TruvideoSdkOrientationManager.shared
        orientationManager.lockToTruvideoOrientation()

        self.editor = editor
        self.videosInformationGenerator = videosInformationGenerator
        self.videoURL = input.url
        self.outputURL = output?.url(fileExtension: FileExtension.mp4.rawValue)
            ?? TruvideoSdkVideoUtils.outputURL(for: UUID().uuidString, fileExtension: FileExtension.mp4.rawValue)
        self.completion = completion
        self.videoPlayer = AVPlayer(url: videoURL)
        self.isAuthenticated = truVideoSdk.isAuthenticated
    }

    func setupTrimmer(forScreenSize screenSize: CGSize) {
        if screenSize.width < screenSize.height {
            screenWidth = screenSize.width
        } else {
            screenWidth = screenSize.height - 64
        }

        configureUI()

        configureVideo()
    }

    func handleAction() {
        isPlaying ? pause() : play()
    }

    private func configureUI() {
        trimmerSize = CGSize(
            width: trimmerInitialWidth,
            height: CGFloat(trimmerHeight)
        )
        thumbnailSize = CGSize(
            width: (trimmerInitialWidth - totalThumbnailListHorizontalPadding) / CGFloat(thumbnailCount),
            height: CGFloat(trimmerHeight)
        )
        leftEdgePosition = 12
        rightEdgePosition = trimmerInitialWidth - 12
    }

    private func configureVideo() {
        Task { @MainActor in
            let videoInformation = try await videosInformationGenerator.getVideoInformation(video: videoURL)
            let resolution = videoInformation.videoSize

            videoAspectRatio = resolution.width / resolution.height
            videoDuration = try await AVAsset(url: videoURL).load(.duration).seconds
            stopAt = videoDuration
            generateThumbnails(orientation: videoInformation.orientation)
            currentRotation = videoInformation.rotation
        }
    }

    private func updateUIforTrimmingIfNeeded() {
        guard trimmerBorderColor == TruvideoColor.gray else { return }
        trimmerBorderColor = TruvideoColor.ambar
        isTrimmerRangeVisible = true
    }

    private func getTrimEdge(location: CGPoint) -> TrimEdge {
        let minimumDistanceFromEdge: CGFloat = 48
        let centerDistanceFromEdge: CGFloat = 16
        if abs(location.x - trimmerCenter) <= centerDistanceFromEdge {
            return .center
        } else if abs(location.x - rightEdgePosition) <= minimumDistanceFromEdge {
            return .right
        } else if abs(location.x - leftEdgePosition) <= minimumDistanceFromEdge {
            return .left
        }
        return .none
    }

    func applyTrimming(value: DragGesture.Value, trimmerProxy: GeometryProxy) {
        let location = value.location
        let viewFrame = trimmerProxy.frame(in: .local)
        guard viewFrame.contains(location) else {
            return
        }

        let minimumEdgesSeparation: CGFloat = 64
        updateUIforTrimmingIfNeeded()
        let trimEdge = getTrimEdge(location: location)
        switch trimEdge {
        case .left:
            guard rightEdgePosition - location.x > minimumEdgesSeparation, location.x > 12 else {
                return
            }
            leftSpaceSize = calculateLeftSpaceSize(for: location.x)
            leftEdgePosition = location.x
            trimmerSize.width = trimmerRightEdgePosition - trimmerXOffset
            trimmerStart = videoDuration * (trimmerXOffset / trimmerInitialWidth)
            seek(to: trimmerStart)
        case .right:
            guard location.x - leftEdgePosition > minimumEdgesSeparation, location.x < trimmerInitialWidth - 12 else {
                return
            }
            rightSpaceSize = calculateRightSpaceSize(for: location.x)
            rightEdgePosition = location.x
            trimmerSize.width = trimmerRightEdgePosition - trimmerXOffset
            stopAt = videoDuration * (trimmerRightEdgePosition / trimmerInitialWidth)
        case .center:
            moveTrimmerCenter(to: location.x)
        default:
            break
        }
    }

    private func moveTrimmerCenter(to x: Double) {
        let diff = x - trimmerCenter
        guard
            leftEdgePosition + diff >= 12,
            trimmerXOffset + trimmerSize.width + diff <= trimmerInitialWidth
        else {
            return
        }
        leftEdgePosition += diff
        leftSpaceSize = calculateLeftSpaceSize(for: x)
        rightSpaceSize = calculateRightSpaceSize(for: x)

        trimmerStart = videoDuration * (trimmerXOffset / trimmerInitialWidth)
        seek(to: trimmerStart)

        rightEdgePosition += diff
        stopAt = videoDuration * (trimmerRightEdgePosition / trimmerInitialWidth)
    }

    private func calculateLeftSpaceSize(for x: Double) -> CGFloat {
        x > thumbnailHorizontalPadding ? thumbnailHorizontalPadding : x
    }

    private func calculateRightSpaceSize(for x: Double) -> CGFloat {
        trimmerInitialWidth - x > thumbnailHorizontalPadding ?
            thumbnailHorizontalPadding : trimmerInitialWidth - x
    }

    func trimVideo(handler: @escaping () -> Void) {
        isTrimming = true
        Task { @MainActor in
            do {
                let result = try await editor.edit(
                    video: .init(
                        videoURL: videoURL,
                        outputURL: outputURL,
                        startPosition: trimmerStart,
                        endPosition: stopAt,
                        rotationAngle: Int(videoRotation.degrees) + currentRotation,
                        volumen: videoPlayer.volume
                    )
                )
                orientationManager.unlockAppOrientation()
                completion(result)
                handler()
            } catch {
                self.error = .trimFailed
            }
            isTrimming = false
        }
    }

    func closeTrimmer(handler: @escaping () -> Void) {
        if isTrimming { return }
        Logger.addLog(event: .editVideo, eventMessage: .closeEditVideoScreen)
        Task { @MainActor in
            orientationManager.unlockAppOrientation()
            completion(.init(editedVideoURL: nil))
            handler()
        }
    }

    private func generateThumbnails(orientation: TruvideoSdkVideoInformation.Orientation) {
        Task { @MainActor in
            let thumbnailInterval = videoDuration / Double(thumbnailCount)

            for index in 0 ..< thumbnailCount {
                let time = videoDuration - Double(index) * thumbnailInterval
                async let result = editor.getThumbnailForVideo(
                    at: videoURL,
                    interval: time,
                    width: (Int(screenWidth) - Int(totalTrimmerHorizontalPadding - thumbnailListHorizontalPadding)) /
                        thumbnailCount,
                    height: trimmerHeight
                )
                guard let image = try await UIImage(contentsOfFile: result.path) else {
                    return
                }

                DispatchQueue.main.async { [weak self] in
                    self?.thumbnails[index] = image
                }
            }
        }
    }

    private func play() {
        if didFinishPlaying {
            seek(to: videoDuration * (trimmerXOffset / trimmerInitialWidth))
        }
        isPlaying = true
        didFinishPlaying = false
        videoPlayer.play()
    }

    private func pause() {
        isPlaying = false
        videoPlayer.pause()
    }

    private func seek(to second: Double) {
        videoPlayer.seek(
            to: CMTime(
                seconds: second,
                preferredTimescale: 1
            )
        )
    }

    private func updateRange() {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        let formattedStart = formatter.string(from: trimmerStart) ?? "00:00"
        let formattedEnd = formatter.string(from: stopAt) ?? "00:00"
        trimmerRange = "\(formattedStart) - \(formattedEnd)"
    }

    func showTrimmer() {
        isTrimmerVisible = true
        isSoundVisible = false
        isRotationVisible = false
    }

    func showSound() {
        isTrimmerVisible = false
        isSoundVisible = true
        isRotationVisible = false
    }

    func showRotation() {
        isTrimmerVisible = false
        isSoundVisible = false
        isRotationVisible = true
    }

    func changeVolume(to value: DragGesture.Value, soundProxy: GeometryProxy) {
        let location = value.location
        let viewFrame = soundProxy.frame(in: .local)
        guard viewFrame.contains(location) else {
            return
        }

        let isDraggingUp = value.translation.height < 0
        let isDraggingDown = value.translation.height > 0

        if location.y <= 4, isDraggingUp {
            volumeHeight = initialVolumeHeight
        } else if location.y >= 180, isDraggingDown {
            volumeHeight = 0
        } else {
            volumeHeight = initialVolumeHeight - location.y
        }
    }

    func muteVideo() {
        if volumeHeight > 0 {
            previousVolumeHeight = volumeHeight
            volumeHeight = 0
        } else {
            if previousVolumeHeight > 0 {
                volumeHeight = previousVolumeHeight
            } else {
                volumeHeight = initialVolumeHeight
            }
        }
    }

    func rotateLeft() {
        if videoRotation == .degrees(-270) {
            videoRotation = .degrees(0)
        } else {
            videoRotation += .degrees(-90)
        }
        checkVideoOrientation()
    }

    func rotateRight() {
        if videoRotation == .degrees(270) {
            videoRotation = .degrees(0)
        } else {
            videoRotation += .degrees(90)
        }
        checkVideoOrientation()
    }

    private func checkVideoOrientation() {
        videoIsInPortraitMode = Int(videoRotation.degrees) % 180 == 0
    }
}
