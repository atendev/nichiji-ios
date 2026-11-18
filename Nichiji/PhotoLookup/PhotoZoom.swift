import CoreGraphics

/*---------------------------------zoom-----------------------------------*/

/// How far the frozen photo is zoomed and panned. The photo fills the view at 1x; `offset` moves the view's centre once it is scaled about that centre, so a point `p` lands at `centre + offset + scale * (p - centre)`.
struct PhotoZoom: Equatable, Sendable {
    static let minScale: CGFloat = 1
    static let maxScale: CGFloat = 4
    /// Where a double-tap from 1x lands.
    static let doubleTapScale: CGFloat = 2.5
    /// A pinch that ends below this closes back to 1x.
    static let snapBelow: CGFloat = 1.05

    static let identity = PhotoZoom()

    var scale: CGFloat = 1
    var offset: CGSize = .zero

    var isZoomed: Bool { scale > Self.minScale }

    /*-----------------------------clamping-----------------------------*/

    /// The scale within range, and an offset small enough that the photo still covers the view. At 1x there is no pan.
    func clamped(in viewSize: CGSize) -> PhotoZoom {
        let next = min(max(scale, Self.minScale), Self.maxScale)
        let limit = Self.maxOffset(scale: next, in: viewSize)
        return PhotoZoom(
            scale: next,
            offset: CGSize(
                width: min(max(offset.width, -limit.width), limit.width),
                height: min(max(offset.height, -limit.height), limit.height)
            )
        )
    }

    /// How far the scaled photo can shift each way before an edge pulls inside the view.
    static func maxOffset(scale: CGFloat, in viewSize: CGSize) -> CGSize {
        CGSize(width: max(viewSize.width * (scale - 1) / 2, 0), height: max(viewSize.height * (scale - 1) / 2, 0))
    }

    /*-----------------------------gestures-----------------------------*/

    /// The zoom at `newScale`, with the photo point under `anchor` (view coordinates) held still.
    func zoomed(to newScale: CGFloat, about anchor: CGPoint, in viewSize: CGSize) -> PhotoZoom {
        let target = min(max(newScale, Self.minScale), Self.maxScale)
        guard scale > 0 else { return .identity }
        let ratio = target / scale
        let fromCentre = CGPoint(x: anchor.x - viewSize.width / 2, y: anchor.y - viewSize.height / 2)
        let next = PhotoZoom(
            scale: target,
            offset: CGSize(
                width: fromCentre.x - ratio * (fromCentre.x - offset.width),
                height: fromCentre.y - ratio * (fromCentre.y - offset.height)
            )
        )
        return next.clamped(in: viewSize)
    }

    /// The zoom after a pinch that began at this state: `magnification` is the gesture's factor.
    func pinched(by magnification: CGFloat, about anchor: CGPoint, in viewSize: CGSize) -> PhotoZoom {
        zoomed(to: scale * magnification, about: anchor, in: viewSize)
    }

    /// The zoom after a drag of `translation` from this state. A photo at 1x does not move.
    func panned(by translation: CGSize, in viewSize: CGSize) -> PhotoZoom {
        guard isZoomed else { return .identity }
        return PhotoZoom(
            scale: scale,
            offset: CGSize(width: offset.width + translation.width, height: offset.height + translation.height)
        ).clamped(in: viewSize)
    }

    /// Where a finished pinch rests: a hair above 1x closes back to it.
    func settled() -> PhotoZoom {
        scale < Self.snapBelow ? .identity : self
    }

    /// A double-tap: back to 1x from any zoom, otherwise in to `doubleTapScale` about the tap.
    func toggled(at point: CGPoint, in viewSize: CGSize) -> PhotoZoom {
        isZoomed ? .identity : zoomed(to: Self.doubleTapScale, about: point, in: viewSize)
    }

    /*-----------------------------mapping------------------------------*/

    /// A point in the unzoomed view, where it sits once zoomed.
    func apply(to point: CGPoint, in viewSize: CGSize) -> CGPoint {
        CGPoint(
            x: viewSize.width / 2 + offset.width + scale * (point.x - viewSize.width / 2),
            y: viewSize.height / 2 + offset.height + scale * (point.y - viewSize.height / 2)
        )
    }

    /// A rect in the unzoomed view, where it sits once zoomed.
    func apply(to rect: CGRect, in viewSize: CGSize) -> CGRect {
        let origin = apply(to: rect.origin, in: viewSize)
        return CGRect(x: origin.x, y: origin.y, width: rect.width * scale, height: rect.height * scale)
    }
}
