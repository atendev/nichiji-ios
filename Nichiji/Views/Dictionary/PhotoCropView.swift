import SwiftUI
import UIKit

/*----------------------------------copy----------------------------------*/

enum PhotoCropCopy {
    static let option = "Crop"
    static let optionHint = "Choose part of the photo and scan only that"
    static let title = "Crop"
    static let hint = "Drag the corners to resize the frame, or drag inside it to move it"
    static let cancel = "Cancel"
    static let done = "Done"
    static let frameLabel = "Crop frame"
    static let moveHint = "Swipe through the actions to move the frame"
    static let handleHint = "Swipe up to shrink the frame from this corner, or down to grow it"

    static func moveLabel(_ direction: PhotoCrop.Direction) -> String {
        switch direction {
        case .left: "Move frame left"
        case .right: "Move frame right"
        case .up: "Move frame up"
        case .down: "Move frame down"
        }
    }

    static func cornerLabel(_ corner: PhotoCrop.Corner) -> String {
        switch corner {
        case .topLeft: "Top left corner"
        case .topRight: "Top right corner"
        case .bottomLeft: "Bottom left corner"
        case .bottomRight: "Bottom right corner"
        }
    }
}

/*---------------------------------layout---------------------------------*/

private enum PhotoCropLayout {
    static let handleArm: CGFloat = 22
    static let handleThickness: CGFloat = 4
    static let frameLine: CGFloat = 1
    static let dim: Double = 0.62
    static let coordinateSpace = "photoCropCanvas"
}

/*---------------------------------entry----------------------------------*/

/// Crop's button among the photo options. It waits for the scan sweep to settle, because the frame needs a still photo.
struct PhotoCropOption: View {
    let isHidden: Bool
    let action: () -> Void

    var body: some View {
        if !isHidden {
            PhotoOptionButton(systemName: "crop", label: PhotoCropCopy.option, hint: PhotoCropCopy.optionHint, action: action)
        }
    }
}

extension View {
    /// Covers the whole screen with the crop screen while `isPresented` is on. A cover lays out against the window, not this view, so the photo fits the screen whatever the host view's size is. Done rescans the frame through the model and calls `onCropped` once the crop replaces the photo; Cancel just closes.
    func photoCrop(
        isPresented: Binding<Bool>,
        image: UIImage?,
        model: PhotoLookupModel,
        onCropped: @escaping () -> Void = {}
    ) -> some View {
        fullScreenCover(
            isPresented: Binding(
                get: { isPresented.wrappedValue && image != nil },
                set: { isPresented.wrappedValue = $0 }
            )
        ) {
            if let image {
                PhotoCropView(
                    image: image,
                    onCancel: { isPresented.wrappedValue = false },
                    onDone: { region in
                        isPresented.wrappedValue = false
                        // A frame that still covers the whole photo has nothing new to read, so it closes like Cancel.
                        guard region != PhotoCrop.fullFrame else { return }
                        Task { if await model.crop(to: region) { onCropped() } }
                    }
                )
            }
        }
    }
}

/*---------------------------------screen---------------------------------*/

/// "Crop": the whole photo, letterboxed to its own shape, with the rest dimmed and a frame that moves when dragged inside and resizes from its four corners. Done hands back the frame; Cancel hands back nothing.
struct PhotoCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onDone: (CGRect) -> Void

    @State private var region = PhotoCrop.fullFrame
    /// The frame as it was when the current drag began, so a drag measures from where it started.
    @State private var dragStart: CGRect?
    /// The frame as it was when the current move began.
    @State private var moveStart: CGRect?

    var body: some View {
        VStack(spacing: LayoutTokens.space16) {
            Text(PhotoCropCopy.title)
                .font(.nichijiHeading)
                .foregroundStyle(Color.cameraText)
                .frame(minHeight: LayoutTokens.minHitTarget)
                .accessibilityAddTraits(.isHeader)

            GeometryReader { proxy in
                canvas(in: proxy.size)
            }

            Text(PhotoCropCopy.hint)
                .font(.nichijiCallout)
                .foregroundStyle(Color.cameraText.opacity(0.8))
                .multilineTextAlignment(.center)

            buttons
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.top, LayoutTokens.space8)
        .padding(.bottom, LayoutTokens.space16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cameraBase.ignoresSafeArea())
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isModal)
        .statusBarHidden()
    }

    /*-----------------------------canvas-------------------------------*/

    private func canvas(in size: CGSize) -> some View {
        let fitted = PhotoFit.fittedFrame(imageSize: image.size, in: size)
        let frame = PhotoCrop.frameRect(for: region, fitted: fitted.size)
        return ZStack(alignment: .topLeading) {
            Image(uiImage: image)
                .resizable()
                .frame(width: fitted.width, height: fitted.height)
                .accessibilityLabel(PhotoLookupCopy.photoLabel)

            DimOutside(hole: frame)
                .fill(Color.cameraBase.opacity(PhotoCropLayout.dim), style: FillStyle(eoFill: true))
                .frame(width: fitted.width, height: fitted.height)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            CropGuides(frame: frame)
                .stroke(Color.cameraText.opacity(0.35), lineWidth: PhotoCropLayout.frameLine)
                .frame(width: fitted.width, height: fitted.height)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            moveArea(frame: frame, fitted: fitted.size)

            ForEach(PhotoCrop.Corner.allCases, id: \.self) { corner in
                handle(corner, frame: frame, fitted: fitted.size)
            }
        }
        .coordinateSpace(.named(PhotoCropLayout.coordinateSpace))
        .frame(width: fitted.width, height: fitted.height)
        .position(x: size.width / 2, y: size.height / 2)
    }

    /// The frame's outline. Dragging inside it moves the whole frame; the corner targets sit above it, so they keep resizing.
    private func moveArea(frame: CGRect, fitted: CGSize) -> some View {
        Rectangle()
            .strokeBorder(Color.cameraText, lineWidth: PhotoCropLayout.frameLine)
            .frame(width: frame.width, height: frame.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(PhotoCropLayout.coordinateSpace))
                    .onChanged { value in
                        let start = moveStart ?? region
                        moveStart = start
                        region = PhotoCrop.translate(start, by: value.translation, fitted: fitted)
                    }
                    .onEnded { _ in moveStart = nil }
            )
            .accessibilityElement()
            .accessibilityLabel(PhotoCropCopy.frameLabel)
            .accessibilityHint(PhotoCropCopy.moveHint)
            .accessibilityActions {
                ForEach(PhotoCrop.Direction.allCases, id: \.self) { direction in
                    Button(PhotoCropCopy.moveLabel(direction)) {
                        region = PhotoCrop.nudge(region, toward: direction)
                    }
                }
            }
            .offset(x: frame.minX, y: frame.minY)
    }

    /// The bracket drawn on a corner, inside a 44 pt target centred on that corner.
    private func handle(_ corner: PhotoCrop.Corner, frame: CGRect, fitted: CGSize) -> some View {
        let anchor = corner.point(on: frame)
        let side = LayoutTokens.minHitTarget
        return CropHandleShape(corner: corner)
            .stroke(Color.cameraText, style: StrokeStyle(lineWidth: PhotoCropLayout.handleThickness, lineCap: .round, lineJoin: .round))
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(PhotoCropLayout.coordinateSpace))
                    .onChanged { value in
                        let start = dragStart ?? region
                        dragStart = start
                        region = PhotoCrop.move(corner, of: start, by: value.translation, fitted: fitted)
                    }
                    .onEnded { _ in dragStart = nil }
            )
            .accessibilityElement()
            .accessibilityLabel(PhotoCropCopy.cornerLabel(corner))
            .accessibilityHint(PhotoCropCopy.handleHint)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: region = PhotoCrop.nudge(corner, of: region, inward: true, fitted: fitted)
                case .decrement: region = PhotoCrop.nudge(corner, of: region, inward: false, fitted: fitted)
                @unknown default: break
                }
            }
            // Position last: it widens the view to the whole canvas, so the target and gesture must be set before it.
            .position(x: anchor.x, y: anchor.y)
    }

    /*-----------------------------buttons------------------------------*/

    private var buttons: some View {
        HStack(spacing: LayoutTokens.space16) {
            Button(action: onCancel) {
                Text(PhotoCropCopy.cancel)
                    .font(.nichijiBody)
                    .foregroundStyle(Color.cameraText)
                    .frame(maxWidth: .infinity, minHeight: LayoutTokens.minHitTarget)
                    .background(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous).fill(Color.cameraInk))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                            .stroke(Color.cameraOutline, lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous))
            }
            .buttonStyle(.plain)

            PrimaryButton(title: PhotoCropCopy.done) {
                onDone(region)
            }
        }
    }
}

/*--------------------------------shapes----------------------------------*/

/// The whole canvas with the crop frame cut out, for an even-odd fill.
private struct DimOutside: Shape {
    let hole: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRect(hole)
        return path
    }
}

/// The thirds lines inside the frame.
private struct CropGuides: Shape {
    let frame: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for step in 1...2 {
            let share = CGFloat(step) / 3
            let x = frame.minX + frame.width * share
            let y = frame.minY + frame.height * share
            path.move(to: CGPoint(x: x, y: frame.minY))
            path.addLine(to: CGPoint(x: x, y: frame.maxY))
            path.move(to: CGPoint(x: frame.minX, y: y))
            path.addLine(to: CGPoint(x: frame.maxX, y: y))
        }
        return path
    }
}

/// An L-shaped bracket whose corner sits at the middle of its 44 pt target and whose arms run along the frame's edges.
struct CropHandleShape: Shape {
    let corner: PhotoCrop.Corner

    func path(in rect: CGRect) -> Path {
        let arm = min(PhotoCropLayout.handleArm, rect.width / 2)
        let origin = CGPoint(x: rect.midX, y: rect.midY)
        let horizontal: CGFloat = corner.isLeft ? 1 : -1
        let vertical: CGFloat = corner.isTop ? 1 : -1
        var path = Path()
        path.move(to: CGPoint(x: origin.x + horizontal * arm, y: origin.y))
        path.addLine(to: origin)
        path.addLine(to: CGPoint(x: origin.x, y: origin.y + vertical * arm))
        return path
    }
}
