//
//  TruvideoSdkVideoEditorView.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 26/12/23.
//

import SwiftUI

struct PresentVideoEditorModifier: ViewModifier {
    let isPresented: Binding<Bool>
    let input: TruvideoSdkVideoFile
    let completion: (TruvideoSdkVideoEditorResult) -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: isPresented) {
                TruvideoSdkVideoEditorView(
                    viewModel: .init(
                        editor: TruvideoSdkVideoEditorImplementation(),
                        videosInformationGenerator: TruvideoSdkVideoInterfaceImp.videosInformationGenerator,
                        input: input,
                        completion: completion
                    )
                )
            }
    }
}

public extension UIViewController {
    /// Present the camera view over the full screen
    /// - Parameter onComplete: A callback with the recording result
    func presentTruvideoSdkVideoEditorView(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor,
        onComplete: @escaping (TruvideoSdkVideoEditorResult) -> Void
    ) {
        let onCompleteDecorator: (TruvideoSdkVideoEditorResult) -> Void = { [weak self] result in
            self?.presentedViewController?.dismiss(animated: true) {
                onComplete(result)
            }
        }
        let viewController = TruvideoSdkVideoEditorViewController(
            input: input,
            output: output,
            onComplete: onCompleteDecorator
        )
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
}

@objc public extension UIViewController {
    func presentTruvideoSdkVideoEditorView(
        input: TruvideoSdkVideoFile,
        outputPath: String,
        outputDescriptor: NSTruvideoSdkVideoFileDescriptor,
        onComplete: @escaping (TruvideoSdkVideoEditorResult) -> Void
    ) {
        let onCompleteDecorator: (TruvideoSdkVideoEditorResult) -> Void = { [weak self] result in
            self?.presentedViewController?.dismiss(animated: true) {
                onComplete(result)
            }
        }
        let viewController = TruvideoSdkVideoEditorViewController(
            input: input,
            output: .instantiate(with: outputPath, fileDescriptor: outputDescriptor),
            onComplete: onCompleteDecorator
        )
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
}

public extension View {
    /// Present the editor view
    /// - Parameters:
    ///   - isPresented: Binding to present and hide the screen
    ///   - videoURL: the URL of the video to be edited
    ///   - completion: a completion handler when the edition is completed
    /// - Returns: The view
    func presentTruvideoSdkVideoEditorView(
        isPresented: Binding<Bool>,
        input: TruvideoSdkVideoFile,
        completion: @escaping (TruvideoSdkVideoEditorResult) -> Void
    ) -> some View {
        modifier(
            PresentVideoEditorModifier(
                isPresented: isPresented,
                input: input,
                completion: completion
            )
        )
    }
}

/// Support for `UIKit` compatibility
private class TruvideoSdkVideoEditorViewController: UIViewController {
    /// Preset configuration
    private var input: TruvideoSdkVideoFile?
    private var output: TruvideoSdkVideoFileDescriptor?
    private var onComplete: ((TruvideoSdkVideoEditorResult) -> Void)?
    private var child: UIViewController?

    convenience init(
        input: TruvideoSdkVideoFile,
        output: TruvideoSdkVideoFileDescriptor,
        onComplete: @escaping (TruvideoSdkVideoEditorResult) -> Void
    ) {
        self.init()
        self.input = input
        self.output = output
        self.onComplete = onComplete
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let newSize = CGRect(origin: .zero, size: size)
        coordinator.animate(alongsideTransition: { context in
            UIView.animate(withDuration: context.transitionDuration, animations: {
                self.child?.view.frame = newSize
            })
        }, completion: { _ in })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChildren()
    }

    private func addChildren() {
        guard let onComplete, let input, let output else { return }

        let viewModel = TruvideoSdkVideoEditorViewModel(
            input: input,
            output: output,
            completion: onComplete
        )

        let videoEditorView = UIHostingController(
            rootView: TruvideoSdkVideoEditorView(viewModel: viewModel)
        )
        videoEditorView.modalPresentationStyle = .fullScreen
        addChild(videoEditorView)
        videoEditorView.view.frame = view.frame

        view.addSubview(videoEditorView.view)

        videoEditorView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoEditorView.view.topAnchor.constraint(equalTo: view.topAnchor),
            videoEditorView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoEditorView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoEditorView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        videoEditorView.didMove(toParent: self)
        child = videoEditorView
    }
}

struct TruvideoSdkVideoEditorView: View {
    @ObservedObject var viewModel: TruvideoSdkVideoEditorViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: TruvideoSdkVideoEditorViewModel) {
        Logger.addLog(event: .initEditVideoScreen, eventMessage: .initEditVideoScreen)
        self.viewModel = viewModel
    }

    var body: some View {
        if let error = viewModel.error {
            ErrorView(error: error) {
                viewModel.error = nil
            }
        } else if viewModel.isAuthenticated {
            videoEditorView()
        } else {
            UnauthenticatedView {
                viewModel.closeTrimmer {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func videoEditorView() -> some View {
        GeometryReader { proxy in
            VStack(alignment: .center, spacing: 4) {
                controlButtons()
                    .padding(.horizontal)

                videoPlayer()

                switch (viewModel.isTrimmerVisible, viewModel.isRotationVisible) {
                case (true, false):
                    trimmer()
                case (false, true):
                    rotation()
                default:
                    EmptyView()
                }

                editionButtons()
            }
            .animation(.spring(), value: viewModel.isTrimmerVisible)
            .animation(.spring(), value: viewModel.isRotationVisible)
            .background(Color.black)
            .onAppear {
                viewModel.setupTrimmer(forScreenSize: proxy.size)
            }
        }
    }

    @ViewBuilder
    private func videoPlayer() -> some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { proxy in
                ZStack {
                    Rectangle()
                        .foregroundStyle(Color.black)
                    TruvideoSdkVideoPlayer(
                        videoPlayer: viewModel.videoPlayer,
                        isPlaying: $viewModel.isPlaying,
                        didFinishPlaying: $viewModel.didFinishPlaying,
                        stopAt: $viewModel.stopAt
                    )
                    .aspectRatio(viewModel.videoAspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 32.0))
                    .rotationEffect(viewModel.videoRotation)
                    .frame(
                        maxWidth: viewModel.videoIsInPortraitMode ? proxy.size.width : proxy.size.height,
                        maxHeight: viewModel.videoIsInPortraitMode ? proxy.size.height : proxy.size.width
                    )

                    if !viewModel.isPlaying {
                        playButton()
                    }
                }
                .onTapGesture {
                    viewModel.handleAction()
                }
            }

            if viewModel.isSoundVisible {
                soundDragger()
            }
        }
        .animation(.spring(), value: viewModel.videoRotation)
        .animation(.spring(), value: viewModel.isSoundVisible)
    }

    @ViewBuilder
    func soundDragger() -> some View {
        VStack {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .foregroundStyle(TruvideoColor.gray)
                        .frame(height: 192)
                    Rectangle()
                        .frame(height: viewModel.volumeHeight)
                        .foregroundStyle(Color.white)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            viewModel.changeVolume(to: value, soundProxy: proxy)
                        }
                )
            }
            .frame(width: 48, height: 192)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Button(action: {
                viewModel.muteVideo()
            }, label: {
                viewModel.soundIcon
                    .frame(width: 24)
                    .foregroundStyle(viewModel.soundIconColor)
                    .padding()
                    .background(viewModel.soundBackgroundColor)
                    .clipShape(Circle())
            })
        }
        .padding([.top, .trailing], 32)
        .animation(.spring(), value: viewModel.soundBackgroundColor)
    }

    @ViewBuilder
    private func trimmer() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.isTrimmerRangeVisible {
                trimmerRange()
            }

            ThumbnailsListView(
                thumbnails: $viewModel.thumbnails,
                trimmerSize: $viewModel.trimmerSize,
                trimmerXOffset: $viewModel.trimmerXOffset,
                leftSpaceSize: $viewModel.leftSpaceSize,
                rightSpaceSize: $viewModel.rightSpaceSize,
                thumbnailSize: viewModel.thumbnailSize,
                totalHorizontalPadding: viewModel.totalTrimmerHorizontalPadding,
                trimmerBorderColor: $viewModel.trimmerBorderColor,
                showRightWhiteSpace: $viewModel.showRightWhiteSpace,
                applyTrimming: { [weak viewModel] value, proxy in
                    viewModel?.applyTrimming(value: value, trimmerProxy: proxy)
                }
            )
            .frame(
                width: viewModel.trimmerInitialWidth,
                height: CGFloat(viewModel.trimmerHeight + 6)
            )
        }
        .animation(.spring(), value: viewModel.isTrimmerRangeVisible)
    }

    @ViewBuilder
    func rotation() -> some View {
        HStack(spacing: 12.0) {
            Spacer()
            HStack(spacing: 32) {
                grayButton(withIcon: TruvideoImage.rotateLeft) {
                    viewModel.rotateLeft()
                }
                grayButton(withIcon: TruvideoImage.rotateRight) {
                    viewModel.rotateRight()
                }
            }
            Spacer()
        }
        .foregroundStyle(Color.white)
        .font(.title)
        .padding(.horizontal)
    }

    // new
    @ViewBuilder
    func playButton() -> some View {
        Button(action: {
            viewModel.handleAction()
        }, label: {
            ZStack {
                Circle()
                    .frame(width: 40)
                    .foregroundStyle(TruvideoColor.gray)
                TruvideoImage.play
                    .foregroundStyle(.white)
            }
        })
    }

    @ViewBuilder
    private func controlButtons() -> some View {
        HStack {
            grayButton(withIcon: TruvideoImage.close) {
                viewModel.closeTrimmer {
                    dismiss()
                }
            }

            Spacer()

            if viewModel.isTrimming {
                ProgressView()
            } else {
                Button(action: {
                    viewModel.trimVideo {
                        dismiss()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .foregroundStyle(Color.black.opacity(0.7))
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(.white, lineWidth: 1)
                        Text("CONTINUE")
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                }
                .fixedSize()
            }
        }
    }

    @ViewBuilder
    func trimmerRange() -> some View {
        Text(viewModel.trimmerRange)
            .foregroundStyle(.white)
            .padding(8)
            .background(TruvideoColor.gray)
            .clipShape(RoundedRectangle(cornerRadius: 4.0))
    }

    @ViewBuilder
    private func editionButtons() -> some View {
        HStack(spacing: 32) {
            Button(action: {
                viewModel.showTrimmer()
            }, label: {
                VStack(spacing: 4) {
                    TruvideoImage.trim
                    Text("Trim")
                }
                .opacity(viewModel.isTrimmerVisible ? 1.0 : 0.5)
            })
            Button(action: {
                viewModel.showSound()
            }, label: {
                VStack(spacing: 4) {
                    TruvideoImage.sound
                    Text("Sound")
                }
                .opacity(viewModel.isSoundVisible ? 1.0 : 0.5)
            })
            Button(action: {
                viewModel.showRotation()
            }, label: {
                VStack(spacing: 4) {
                    TruvideoImage.rotate
                    Text("Rotation")
                }
                .opacity(viewModel.isRotationVisible ? 1.0 : 0.5)
            })
            Spacer()
        }
        .font(.body)
        .foregroundStyle(Color.white)
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .background(TruvideoColor.gray)
    }

    @ViewBuilder
    private func grayButton(withIcon icon: Image, _ action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            ZStack {
                Circle()
                    .frame(width: 48)
                    .foregroundStyle(TruvideoColor.gray)
                icon
                    .foregroundStyle(.white)
                    .font(.body)
            }
        })
    }
}
