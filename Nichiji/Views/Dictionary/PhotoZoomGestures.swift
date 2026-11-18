import SwiftUI

/*--------------------------------gestures--------------------------------*/

/// Pinch, drag and double-tap on the frozen photo. All three act on one `PhotoZoom`; a tap that is not a double-tap goes to `onTap`, after the double-tap window has passed.
private struct PhotoZoomGestures: ViewModifier {
    @Binding var zoom: PhotoZoom
    let viewSize: CGSize
    let contentSize: CGSize
    let isEnabled: Bool
    let onTap: (CGPoint) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pinchBase: PhotoZoom?
    @State private var panBase: PhotoZoom?
    @State private var panOrigin: CGSize = .zero
    @State private var isDragging = false
    /// Set when a pinch begins under a finger that is already dragging, so that drag restarts from where the pinch left off.
    @State private var panNeedsRebase = false

    private var mask: GestureMask { isEnabled ? .all : .none }

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(taps, including: mask)
            .simultaneousGesture(pinch, including: mask)
            .simultaneousGesture(pan, including: mask)
    }

    /// A double-tap takes priority; a single tap waits to see whether a second one follows.
    private var taps: some Gesture {
        SpatialTapGesture(count: 2).exclusively(before: SpatialTapGesture(count: 1))
            .onEnded { value in
                switch value {
                case .first(let tap):
                    toggle(at: tap.location)
                case .second(let tap):
                    onTap(tap.location)
                }
            }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let base = pinchBase ?? zoom
                pinchBase = base
                panBase = nil
                panNeedsRebase = isDragging
                zoom = base.pinched(by: value.magnification, about: value.startLocation, in: viewSize, content: contentSize)
            }
            .onEnded { _ in
                pinchBase = nil
                let next = zoom.settled()
                guard next != zoom else { return }
                animate { zoom = next }
            }
    }

    /// A drag moves the photo only while it is zoomed, and not while a pinch is in progress. A drag that outlives a pinch starts again from where the pinch left off.
    private var pan: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                isDragging = true
                guard pinchBase == nil, zoom.isZoomed else {
                    panBase = nil
                    return
                }
                if panBase == nil {
                    panBase = zoom
                    panOrigin = panNeedsRebase ? value.translation : .zero
                    panNeedsRebase = false
                }
                let base = panBase ?? zoom
                zoom = base.panned(
                    by: CGSize(width: value.translation.width - panOrigin.width, height: value.translation.height - panOrigin.height),
                    in: viewSize,
                    content: contentSize
                )
            }
            .onEnded { _ in
                isDragging = false
                panBase = nil
                panNeedsRebase = false
            }
    }

    private func toggle(at point: CGPoint) {
        let next = zoom.toggled(at: point, in: viewSize, content: contentSize)
        animate { zoom = next }
    }

    /// Fingers drive the pinch and pan directly; only the double-tap and the snap back animate, and not under Reduce Motion.
    private func animate(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25), change)
    }
}

extension View {
    /// Lets the learner pinch, drag and double-tap to change `zoom`. `contentSize` is the photo's size at 1x, which bounds the pan. While `isEnabled` is off the gestures do nothing, and a single tap goes to `onTap` in this view's coordinates.
    func photoZoomGestures(
        _ zoom: Binding<PhotoZoom>,
        viewSize: CGSize,
        contentSize: CGSize,
        isEnabled: Bool,
        onTap: @escaping (CGPoint) -> Void
    ) -> some View {
        modifier(PhotoZoomGestures(zoom: zoom, viewSize: viewSize, contentSize: contentSize, isEnabled: isEnabled, onTap: onTap))
    }
}
