//
// Copyright © 2025 TruVideo. All rights reserved.
//

import AVKit
import SwiftUI
import UIKit

/// A view controller that displays a single video clip.
///
/// Used inside `MediaPreviewPageViewController` for full-screen video preview.
final class ClipViewController: UIViewController {
    // MARK: - Properties

    /// The video clip to display.
    let clip: VideoClip

    /// The image view used to present the video.
    let imageView = UIImageView()

    /// The index of the clip in the media array.
    var index = 0

    // MARK: - Private Properties

    /// The player for playback control.
    private let player: AVPlayer

    // MARK: - Initializer

    /// Initializes the view controller with a video clip.
    ///
    /// - Parameter clip: The video to display.
    init(clip: VideoClip) {
        self.clip = clip
        self.player = AVPlayer(url: clip.url)

        imageView.image = UIImage(contentsOfFile: clip.thumbnailURL.path)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lyfecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerViewController = AVPlayerViewController()
        let topAnchorConstant: CGFloat = UIDevice.current.isPad ? 40 : 100

        playerViewController.player = player
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(playerViewController)

        view.backgroundColor = .black
        view.addSubview(playerViewController.view)

        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: topAnchorConstant),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        playerViewController.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        player.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        player.pause()
        player.seek(to: .zero)
    }
}
