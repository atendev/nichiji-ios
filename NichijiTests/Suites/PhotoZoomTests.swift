import CoreGraphics
import Foundation
import Testing
@testable import Nichiji

/*---------------------------photo-zoom-tests-----------------------------*/

@Suite("Photo Zoom Tests")
struct PhotoZoomTests {
    private let view = CGSize(width: 200, height: 400)
    private var centre: CGPoint { CGPoint(x: 100, y: 200) }

    @Test("A photo starts at 1x with no pan")
    func startsAtIdentity() {
        #expect(PhotoZoom.identity.scale == 1)
        #expect(PhotoZoom.identity.offset == .zero)
        #expect(!PhotoZoom.identity.isZoomed)
    }

    @Test("Pinching in past the cap stops at 4x")
    func pinchStopsAtCap() {
        let zoom = PhotoZoom.identity.pinched(by: 10, about: centre, in: view)

        #expect(zoom.scale == PhotoZoom.maxScale)
    }

    @Test("Pinching out past 1x stops at 1x with no pan")
    func pinchStopsAtFit() {
        let start = PhotoZoom(scale: 2, offset: CGSize(width: 40, height: -60))

        let zoom = start.pinched(by: 0.1, about: centre, in: view)

        #expect(zoom == .identity)
    }

    @Test("A pinch multiplies the scale it began with")
    func pinchIsRelative() {
        let zoom = PhotoZoom(scale: 2, offset: .zero).pinched(by: 1.5, about: centre, in: view)

        #expect(zoom.scale == 3)
    }

    @Test("The photo point under the pinch stays under it")
    func pinchHoldsAnchor() {
        let anchor = CGPoint(x: 50, y: 100)

        let zoom = PhotoZoom.identity.pinched(by: 2, about: anchor, in: view)

        #expect(zoom.apply(to: anchor, in: view) == anchor)
    }

    @Test("A pinch near a corner is held by the clamp so no edge pulls inside")
    func pinchAtCornerKeepsCorner() {
        let zoom = PhotoZoom.identity.pinched(by: 2, about: .zero, in: view)

        #expect(zoom.offset == CGSize(width: 100, height: 200))
        #expect(zoom.apply(to: CGPoint.zero, in: view) == CGPoint.zero)
    }

    @Test("A drag pans a zoomed photo")
    func dragPans() {
        let zoom = PhotoZoom(scale: 2, offset: .zero).panned(by: CGSize(width: 30, height: -40), in: view)

        #expect(zoom.offset == CGSize(width: 30, height: -40))
        #expect(zoom.scale == 2)
    }

    @Test("A drag cannot take an edge of the photo inside the view")
    func dragIsClamped() {
        let zoom = PhotoZoom(scale: 2, offset: .zero).panned(by: CGSize(width: 500, height: -900), in: view)

        #expect(zoom.offset == CGSize(width: 100, height: -200))
    }

    @Test("The pan limit grows with the zoom")
    func limitGrowsWithScale() {
        let limit = PhotoZoom.maxOffset(scale: 4, in: view)

        #expect(limit == CGSize(width: 300, height: 600))
        #expect(PhotoZoom.maxOffset(scale: 1, in: view) == .zero)
    }

    @Test("A photo at 1x does not pan")
    func fitDoesNotPan() {
        let zoom = PhotoZoom.identity.panned(by: CGSize(width: 50, height: 50), in: view)

        #expect(zoom == .identity)
    }

    @Test("A stray offset is pulled back inside the limit")
    func clampPullsOffsetIn() {
        let zoom = PhotoZoom(scale: 2, offset: CGSize(width: 500, height: -500)).clamped(in: view)

        #expect(zoom.offset == CGSize(width: 100, height: -200))
    }

    @Test("A pinch that ends just above 1x closes back to it")
    func settleSnapsToFit() {
        #expect(PhotoZoom(scale: 1.04, offset: .zero).settled() == .identity)
        #expect(PhotoZoom(scale: 1.2, offset: .zero).settled().scale == 1.2)
    }

    @Test("A double-tap from 1x zooms to 2.5x about the tap")
    func doubleTapZoomsIn() {
        let point = CGPoint(x: 50, y: 100)

        let zoom = PhotoZoom.identity.toggled(at: point, in: view)

        #expect(zoom.scale == PhotoZoom.doubleTapScale)
        #expect(zoom.apply(to: point, in: view) == point)
    }

    @Test("A double-tap on a zoomed photo returns to 1x")
    func doubleTapZoomsOut() {
        let zoom = PhotoZoom(scale: 3, offset: CGSize(width: 20, height: 20)).toggled(at: centre, in: view)

        #expect(zoom == .identity)
    }

    @Test("A point maps through the scale about the view's centre, then the pan")
    func pointMapping() {
        let zoom = PhotoZoom(scale: 2, offset: CGSize(width: 10, height: 20))

        #expect(zoom.apply(to: centre, in: view) == CGPoint(x: 110, y: 220))
        #expect(zoom.apply(to: CGPoint(x: 0, y: 0), in: view) == CGPoint(x: -90, y: -180))
    }

    @Test("A box follows the zoom in position and size")
    func boxMapping() {
        let zoom = PhotoZoom(scale: 2, offset: CGSize(width: 10, height: 20))

        let rect = zoom.apply(to: CGRect(x: 100, y: 200, width: 20, height: 40), in: view)

        #expect(rect == CGRect(x: 110, y: 220, width: 40, height: 80))
    }

    @Test("A box stays on its kanji at every zoom")
    func boxStaysOnItsKanji() {
        // The kanji sits at the photo point (150, 300); the box is drawn around it.
        let box = CGRect(x: 140, y: 290, width: 20, height: 20)
        let zoom = PhotoZoom.identity.pinched(by: 3, about: CGPoint(x: 150, y: 300), in: view)

        let moved = zoom.apply(to: box, in: view)

        #expect(zoom.apply(to: CGPoint(x: 150, y: 300), in: view) == CGPoint(x: 150, y: 300))
        #expect(moved.midX == 150)
        #expect(moved.midY == 300)
    }

    @Test("An empty view allows no pan")
    func emptyViewHasNoPan() {
        let zoom = PhotoZoom(scale: 2, offset: CGSize(width: 10, height: 10)).clamped(in: .zero)

        #expect(zoom.offset == .zero)
    }
}
