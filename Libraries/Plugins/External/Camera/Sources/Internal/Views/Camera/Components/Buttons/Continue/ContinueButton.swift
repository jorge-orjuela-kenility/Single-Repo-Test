//
// Copyright © 2025 TruVideo. All rights reserved.
//

import SwiftUI

/// A styled continue button that dismisses the current view when tapped.
///
/// This view displays a primary-styled button with the text "Continue" that
/// automatically dismisses the current view presentation context when tapped.
/// The button features a rounded border overlay that provides visual emphasis
/// and maintains consistent theming with the app's design system.
struct ContinueButton: View {
    // MARK: - Environment Properties

    @Environment(\.theme)
    var theme

    // MARK: - StateObject Properties

    @StateObject var viewModel = OrientationViewModel()

    // MARK: - Properties

    let onTap: () -> Void

    // MARK: - Computed Properties

    var alignment: Alignment {
        guard viewModel.deviceOrientation.source == .sensors, UIDevice.current.orientation.isPortrait else {
            return .topTrailing
        }

        return viewModel.deviceOrientation.orientation == .landscapeLeft ? .bottomTrailing : .topLeading
    }

    var buttonTheme: ButtonTheme {
        theme.buttonTheme.copyWith(minimunSize: CGSize(width: theme.sizeTheme.x(30), height: theme.sizeTheme.xxxl))
    }

    var offset: CGPoint {
        guard viewModel.deviceOrientation.orientation.isLandscape, UIDevice.current.orientation.isPortrait else {
            return CGPoint.zero
        }

        let originX = theme.spacingTheme.x(10) * (viewModel.deviceOrientation.orientation == .landscapeLeft ? 1 : -1)
        let originY = theme.spacingTheme.x(12) * (viewModel.deviceOrientation.orientation == .landscapeLeft ? -1 : 1)

        return CGPoint(x: originX, y: originY)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Button(Localizations.continueText, action: onTap)
                .buttonStyle(.primary)
                .fixedSize()
                .theme(theme.copyWith(buttonTheme: buttonTheme))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radiusTheme.xs)
                        .stroke(theme.colorScheme.onPrimary, lineWidth: 1)
                )
                .padding(.trailing, theme.spacingTheme.xs)
                .if(viewModel.deviceOrientation.source == .sensors) { view in
                    view
                        .rotationEffect(viewModel.rotationAngle)
                        .offset(x: offset.x, y: offset.y)
                }
                .id(viewModel.deviceOrientation)
                .transition(.opacity.animation(.linear(duration: 0.25)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}
