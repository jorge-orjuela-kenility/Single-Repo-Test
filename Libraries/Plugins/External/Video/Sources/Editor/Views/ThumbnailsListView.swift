//
//  ThumbnailsListView.swift
//  TruvideoSdkVideo
//
//  Created by Luis Francisco Piura Mejia on 26/12/23.
//

import SwiftUI

struct ThumbnailsListView: View {
    var thumbnails: Binding<[UIImage]>
    var trimmerSize: Binding<CGSize>
    var trimmerXOffset: Binding<CGFloat>
    var leftSpaceSize: Binding<CGFloat>
    var rightSpaceSize: Binding<CGFloat>
    var thumbnailSize: CGSize
    var totalHorizontalPadding: CGFloat
    var trimmerBorderColor: Binding<Color>
    var showRightWhiteSpace: Binding<Bool>
    var applyTrimming: (DragGesture.Value, GeometryProxy) -> Void

    private let edgesSize: CGFloat = 8
    private let edgesAdditionalHeight: CGFloat = 6
    private let edgesAdditionalPadding: CGFloat = 16
    private let edgesCornerRadius: CGFloat = 5
    private let trimmerBorderSize: CGFloat = 4

    var body: some View {
        GeometryReader { trimmerProxy in
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundStyle(Color.black)
                    .frame(height: edgesAdditionalHeight / 2)
                LazyHGrid(
                    rows: [
                        GridItem(
                            .fixed(thumbnailSize.width)
                        )
                    ],
                    spacing: .zero
                ) {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(width: edgesSize + edgesAdditionalPadding)
                    ForEach(thumbnails.wrappedValue, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .frame(
                                width: thumbnailSize.width,
                                height: thumbnailSize.height
                            )
                            .scaledToFit()
                    }
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(width: edgesSize + edgesAdditionalPadding)
                }
                .frame(height: trimmerProxy.size.height - edgesAdditionalHeight)
                Rectangle()
                    .foregroundStyle(Color.black)
                    .frame(height: edgesAdditionalHeight / 2)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        applyTrimming(value, trimmerProxy)
                    }
            )
            .overlay(
                alignment: .leading
            ) {
                HStack(spacing: .zero) {
                    HStack(spacing: .zero) {
                        Rectangle()
                            .frame(width: leftSpaceSize.wrappedValue)
                            .foregroundStyle(.clear)
                        Rectangle()
                            .foregroundStyle(TruvideoColor.gray.opacity(0.8))
                    }
                    .frame(
                        width: trimmerXOffset.wrappedValue,
                        height: trimmerProxy.size.height
                    )
                    HStack(spacing: .zero) {
                        VStack(alignment: .center) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .frame(width: edgesSize, height: edgesSize)
                                .padding(.leading, 2)
                        }
                        .frame(
                            width: edgesSize + edgesAdditionalPadding,
                            height: trimmerProxy.size.height
                        )
                        .foregroundColor(trimmerBorderColor.wrappedValue)
                        .background(trimmerBorderColor.wrappedValue)
                        .cornerRadius(edgesCornerRadius, corners: [.topLeft, .bottomLeft])
                        VStack {
                            Rectangle()
                                .frame(height: trimmerBorderSize)
                                .foregroundStyle(trimmerBorderColor.wrappedValue)
                            Spacer()
                            Rectangle()
                                .frame(height: trimmerBorderSize)
                                .foregroundStyle(trimmerBorderColor.wrappedValue)
                        }
                        VStack(alignment: .center) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .frame(width: edgesSize, height: edgesSize)
                                .padding(.trailing, 2)
                        }
                        .frame(
                            width: edgesSize + edgesAdditionalPadding,
                            height: trimmerProxy.size.height
                        )
                        .foregroundColor(trimmerBorderColor.wrappedValue)
                        .background(trimmerBorderColor.wrappedValue)
                        .cornerRadius(edgesCornerRadius, corners: [.topRight, .bottomRight])
                    }
                    .frame(
                        width: trimmerSize.wrappedValue.width,
                        height: trimmerProxy.size.height
                    )
                    HStack(spacing: .zero) {
                        if showRightWhiteSpace.wrappedValue {
                            Rectangle()
                                .foregroundStyle(TruvideoColor.gray.opacity(0.8))
                        }
                        Rectangle()
                            .frame(width: rightSpaceSize.wrappedValue)
                            .foregroundStyle(.clear)
                    }
                    .frame(
                        height: trimmerProxy.size.height
                    )
                }
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
