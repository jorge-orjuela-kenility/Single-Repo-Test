//
//  TruvideoSdkVideoPlayer.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 26/12/23.
//

import AVKit
import SwiftUI

struct TruvideoSdkVideoPlayer: UIViewControllerRepresentable {
    var videoPlayer: AVPlayer
    var isPlaying: Binding<Bool>
    var didFinishPlaying: Binding<Bool>
    var stopAt: Binding<Double>

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = videoPlayer
        playerViewController.showsPlaybackControls = false

        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(
            videoPlayer: videoPlayer,
            isPlaying: isPlaying,
            didFinishPlaying: didFinishPlaying,
            stopAt: stopAt
        )
        coordinator.registerForNotifications()
        return coordinator
    }

    final class Coordinator: NSObject {
        private var videoPlayer: AVPlayer
        private var isPlaying: Binding<Bool>
        private var didFinishPlaying: Binding<Bool>
        private var stopAt: Binding<Double>

        init(
            videoPlayer: AVPlayer,
            isPlaying: Binding<Bool>,
            didFinishPlaying: Binding<Bool>,
            stopAt: Binding<Double>
        ) {
            self.videoPlayer = videoPlayer
            self.isPlaying = isPlaying
            self.didFinishPlaying = didFinishPlaying
            self.stopAt = stopAt
        }

        @objc func onDidFinishPlaying() {
            didFinishPlaying.wrappedValue = true
            isPlaying.wrappedValue = false
            videoPlayer.pause()
        }

        func registerForNotifications() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: videoPlayer.currentItem
            )
            self.videoPlayer.addPeriodicTimeObserver(
                forInterval: .init(seconds: 1, preferredTimescale: 1),
                queue: .main
            ) { [weak self] time in
                guard let self else {
                    return
                }
                if time.seconds >= self.stopAt.wrappedValue {
                    self.onDidFinishPlaying()
                }
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
