//
// Copyright © 2025 TruVideo. All rights reserved.
//

import UIKit

/// Provides a snapshot view for use during custom view controller transitions.
protocol SnapshotProvider {
    // MARK: - Properties

    /// A snapshot view of the current content.
    var snapshot: UIView { get }
}

/// A custom animated transition that zooms a view from a given origin frame
/// into full screen and back to its original position.
///
/// This animator handles both the presentation and dismissal transitions.
class ZoomAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning {
    // MARK: - Properties

    /// Duration of the animation in seconds.
    let duration = 0.3

    // MARK: - Private Properties

    private let isPresenting: Bool
    private let originFrame: CGRect
    private let onTransitionAction: (() -> Void)?
    private let snapshotProvider: SnapshotProvider?

    // MARK: - Initializer

    /// Creates a new zoom animator.
    ///
    /// - Parameters:
    ///   - isPresenting: Whether the animation is for presenting (`true`) or dismissing (`false`).
    ///   - originFrame: The starting or ending frame of the zoom animation.
    ///   - snapshotProvider: Optional provider for supplying a snapshot view.
    ///   - onTransitionAction: A closure executed during the transition animation.
    init(
        isPresenting: Bool,
        originFrame: CGRect = .zero,
        snapshotProvider: SnapshotProvider? = nil,
        onTransitionAction: (() -> Void)? = nil
    ) {
        self.isPresenting = isPresenting
        self.originFrame = originFrame
        self.snapshotProvider = snapshotProvider
        self.onTransitionAction = onTransitionAction
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    // MARK: - Private Methods

    private func aspectFitFrame(for view: UIView, in rect: CGRect) -> CGRect {
        var contentSize = view.bounds.size

        if let imageView = view as? UIImageView, let image = imageView.image {
            contentSize = image.size
        }

        let imageRatio = contentSize.width / contentSize.height
        let rectRatio = rect.width / rect.height

        if imageRatio > rectRatio {
            let width = rect.width
            let height = width / imageRatio
            return CGRect(x: rect.minX, y: rect.minY + (rect.height - height) / 2, width: width, height: height)
        } else {
            let height = rect.height
            let width = height * imageRatio
            return CGRect(x: rect.minX + (rect.width - width) / 2, y: rect.minY, width: width, height: height)
        }
    }

    private func makeSnapshot(view: UIView, frame: CGRect) -> UIView {
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.frame = frame
        return view
    }

    // MARK: - Presentation

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from)
        else {
            transitionContext.completeTransition(true)
            return
        }

        guard let image = snapshotProvider?.snapshot ?? fromVC.view.snapshotView(afterScreenUpdates: true) else {
            transitionContext.completeTransition(true)
            return
        }

        let container = transitionContext.containerView
        let backgroundView = UIView(frame: container.bounds)
        let originRect = container.convert(originFrame, from: nil)
        let snapshot = makeSnapshot(view: image, frame: originRect)

        backgroundView.backgroundColor = .black
        backgroundView.alpha = 0
        container.addSubview(backgroundView)
        container.addSubview(snapshot)
        toVC.view.frame = container.bounds
        toVC.view.alpha = 0
        container.addSubview(toVC.view)

        UIView.animate(withDuration: duration) {
            backgroundView.alpha = 1
            self.onTransitionAction?()
            snapshot.frame = self.aspectFitFrame(for: image, in: container.bounds)
        } completion: { _ in
            toVC.view.alpha = 1
            snapshot.removeFromSuperview()
            backgroundView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(true)
            return
        }

        let container = transitionContext.containerView
        let snapshotProvider = fromVC as? SnapshotProvider

        guard let image = snapshotProvider?.snapshot ?? fromVC.view.snapshotView(afterScreenUpdates: true) else {
            transitionContext.completeTransition(true)
            return
        }

        let startFrame = aspectFitFrame(for: image, in: container.bounds)
        let snapshot = makeSnapshot(view: image, frame: startFrame)

        container.addSubview(snapshot)

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            snapshot.frame = self.originFrame
        } completion: { _ in
            snapshot.removeFromSuperview()
            self.onTransitionAction?()
            fromVC.view.isHidden = false
            transitionContext.completeTransition(true)
        }
    }
}
