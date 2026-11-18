import SwiftUI
import UIKit

/*-------------------------------frozen-photo-------------------------------*/

/// The frozen shot, filling the screen, with the scan line and the kanji boxes over it. Boxes are mapped from the image to the view under aspect-fill, then through the learner's pinch and pan.
struct FrozenPhotoLayer: View {
    let image: UIImage
    let boxes: [HighlightBox]
    let sweep: ScanSweep?
    /// True from the shutter until the last box is in. It runs the timeline and holds taps and zoom back.
    let isSweeping: Bool
    let showsHighlights: Bool
    let onPick: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zoom = PhotoZoom.identity

    /// The design draws each box a little larger than the glyph: 1 pt either side, 3 pt above and below.
    private func drawn(_ box: HighlightBox, in viewSize: CGSize) -> CGRect {
        PhotoFit.viewRect(forNormalized: box.rect, imageSize: image.size, in: viewSize).insetBy(dx: -1, dy: -3)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rects = boxes.map { drawn($0, in: size) }
            let shown = rects.map { zoom.apply(to: $0, in: size) }
            // Only the part of the photo on screen carries boxes, so one cropped off by aspect-fill stays hidden when zoomed in.
            let visible = zoom.apply(to: CGRect(origin: .zero, size: size), in: size)
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .scaleEffect(zoom.scale)
                    .offset(zoom.offset)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .accessibilityLabel(PhotoLookupCopy.photoLabel)

                if showsHighlights, !boxes.isEmpty {
                    HighlightsLayer(
                        boxes: boxes,
                        rects: rects,
                        shown: shown,
                        viewHeight: size.height,
                        sweep: sweep,
                        isSweeping: isSweeping,
                        onPick: onPick
                    )
                    .mask {
                        Rectangle()
                            .frame(width: visible.width, height: visible.height)
                            .position(x: visible.midX, y: visible.midY)
                    }
                    .frame(width: size.width, height: size.height)
                    .clipped()
                }

                if isSweeping, !reduceMotion, let sweep {
                    ScanLine(sweep: sweep, height: size.height)
                }
            }
            .photoZoomGestures($zoom, viewSize: size, isEnabled: !isSweeping) { point in
                guard showsHighlights, !isSweeping, let index = PhotoHighlights.index(at: point, in: shown) else { return }
                onPick(boxes[index].kanji)
            }
        }
        .onChange(of: image) { _, _ in zoom = .identity }
    }
}

/*--------------------------------scan-line---------------------------------*/

/// The line that sweeps down the photo while it is read.
private struct ScanLine: View {
    let sweep: ScanSweep
    let height: CGFloat

    private static let thickness: CGFloat = 3

    var body: some View {
        TimelineView(.animation) { context in
            ZStack(alignment: .top) {
                if let position = sweep.linePosition(at: context.date) {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .cameraNew, location: 0.12),
                            .init(color: .cameraNew, location: 0.88),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: Self.thickness)
                    .shadow(color: Color.cameraNew.opacity(0.5), radius: 9)
                    .padding(.horizontal, LayoutTokens.space24)
                    .offset(y: position * height)
                    .opacity(ScanSweep.lineOpacity(at: position))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/*--------------------------------highlights--------------------------------*/

/// A red or green box on every kanji found. `rects` are the boxes with the photo at 1x, which time the sweep; `shown` are the same boxes under the current zoom, which are drawn and labelled. Taps are read by the zoom gestures, since a single tap must wait out a double-tap.
private struct HighlightsLayer: View {
    let boxes: [HighlightBox]
    let rects: [CGRect]
    let shown: [CGRect]
    let viewHeight: CGFloat
    let sweep: ScanSweep?
    let isSweeping: Bool
    let onPick: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            TimelineView(.animation(paused: !isSweeping)) { context in
                ZStack {
                    ForEach(boxes) { box in
                        let rect = shown[box.id]
                        let progress = sweep?.boxProgress(
                            at: context.date,
                            normalizedY: viewHeight > 0 ? rects[box.id].midY / viewHeight : 0,
                            reduceMotion: reduceMotion
                        ) ?? 1
                        HighlightBoxView(isNew: box.isNew)
                            .frame(width: rect.width, height: rect.height)
                            .scaleEffect(reduceMotion ? 1 : 1.18 - 0.18 * progress)
                            .opacity(progress)
                            .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            ForEach(boxes) { box in
                let region = PhotoHighlights.tapRegion(for: shown[box.id])
                Color.clear
                    .frame(width: region.width, height: region.height)
                    .position(x: region.midX, y: region.midY)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(PhotoLookupCopy.boxLabel(kanji: box.kanji, isNew: box.isNew))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        guard !isSweeping else { return }
                        onPick(box.kanji)
                    }
            }
        }
    }
}

private struct HighlightBoxView: View {
    let isNew: Bool

    private static let radius: CGFloat = 6

    var body: some View {
        let color = isNew ? Color.cameraNew : Color.cameraLearned
        RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
            .fill(color.opacity(0.22))
            .overlay(RoundedRectangle(cornerRadius: Self.radius, style: .continuous).strokeBorder(color, lineWidth: 2))
            .overlay(
                RoundedRectangle(cornerRadius: Self.radius + 1, style: .continuous)
                    .stroke(Color.cameraBase.opacity(0.35), lineWidth: 1)
                    .padding(-1)
            )
    }
}

/*--------------------------------controls----------------------------------*/

/// A labelled option on the frozen photo, in the camera's dark ink: an icon beside its text, 44 pt high.
struct PhotoOptionButton: View {
    let systemName: String
    let label: String
    var hint: String?
    var isOn: Bool?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space8) {
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .regular))
                Text(label)
                    .font(.uiText(size: 14, weight: .medium))
            }
            .foregroundStyle(Color.cameraText)
            .padding(.horizontal, LayoutTokens.space12)
            .frame(minHeight: LayoutTokens.minHitTarget)
            .background(Capsule().fill(Color.cameraInk))
            .overlay(Capsule().stroke(Color.cameraOutline, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(hint ?? "")
        .accessibilityValue(isOn.map { $0 ? "On" : "Off" } ?? "")
    }
}

/// The pill at the bottom while the photo is read.
struct ScanningPill: View {
    var body: some View {
        HStack(spacing: LayoutTokens.space12) {
            ProgressView()
                .controlSize(.small)
                .tint(.cameraNew)
            Text(PhotoLookupCopy.scanning)
                .font(.uiText(size: 14, weight: .medium))
                .foregroundStyle(Color.cameraText)
        }
        .padding(.horizontal, LayoutTokens.space16 + 2)
        .frame(minHeight: LayoutTokens.minHitTarget)
        .background(Capsule().fill(Color.cameraBase.opacity(0.7)))
        .overlay(Capsule().stroke(Color.cameraOutline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
