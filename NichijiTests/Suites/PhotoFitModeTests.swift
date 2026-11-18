import CoreGraphics
import Foundation
import Testing
@testable import Nichiji

/*--------------------------photo-fit-mode-tests--------------------------*/

@Suite("Photo Fit Mode Tests")
struct PhotoFitModeTests {
    private let view = CGSize(width: 200, height: 400)

    @Test("A camera shot fills the screen; a library photo or a crop is fitted")
    func originPicksTheMode() {
        #expect(PhotoOrigin.camera.fitMode == .fill)
        #expect(PhotoOrigin.library.fitMode == .fit)
        #expect(PhotoOrigin.cropped.fitMode == .fit)
    }

    @Test("A portrait photo of the view's shape is the same in both modes")
    func portraitMatchingAspect() {
        let image = CGSize(width: 100, height: 200)

        let fill = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fill)
        let fit = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fit)

        #expect(fill == CGRect(x: 0, y: 0, width: 200, height: 400))
        #expect(fit == fill)
    }

    @Test("A narrow portrait photo is cut top and bottom when filled and pillarboxed when fitted")
    func narrowPortrait() {
        let image = CGSize(width: 100, height: 400)

        let fill = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fill)
        let fit = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fit)

        #expect(fill == CGRect(x: 0, y: -200, width: 200, height: 800))
        #expect(fit == CGRect(x: 50, y: 0, width: 100, height: 400))
    }

    @Test("A square photo is cut at the sides when filled and letterboxed when fitted")
    func squarePhoto() {
        let image = CGSize(width: 1_000, height: 1_000)

        let fill = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fill)
        let fit = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fit)

        #expect(fill == CGRect(x: -100, y: 0, width: 400, height: 400))
        #expect(fit == CGRect(x: 0, y: 100, width: 200, height: 200))
    }

    @Test("A landscape photo fitted shows whole across the width")
    func landscapePhoto() {
        let image = CGSize(width: 4_000, height: 3_000)

        let fit = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fit)

        let fill = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fill)

        #expect(fit == CGRect(x: 0, y: 125, width: 200, height: 150))
        #expect(fill.height == 400)
        #expect(abs(fill.width - 400 * 4 / 3) < 0.001)
    }

    @Test("A box maps through the fitted frame so it stays on its kanji")
    func boxFollowsFittedFrame() {
        let image = CGSize(width: 1_000, height: 1_000)
        let box = CGRect(x: 0.5, y: 0.25, width: 0.1, height: 0.1)

        let fit = PhotoFit.viewRect(forNormalized: box, imageSize: image, in: view, mode: .fit)
        let fill = PhotoFit.viewRect(forNormalized: box, imageSize: image, in: view, mode: .fill)

        #expect(fit == CGRect(x: 100, y: 150, width: 20, height: 20))
        #expect(fill == CGRect(x: 100, y: 100, width: 40, height: 40))
    }

    @Test("A box mapped without a mode is filled, as before")
    func defaultModeIsFill() {
        let image = CGSize(width: 1_000, height: 1_000)
        let box = CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)

        #expect(
            PhotoFit.viewRect(forNormalized: box, imageSize: image, in: view)
                == PhotoFit.viewRect(forNormalized: box, imageSize: image, in: view, mode: .fill)
        )
    }

    @Test("A fitted box lies inside the photo, never on a bar")
    func fittedBoxesStayOnPhoto() {
        let image = CGSize(width: 4_000, height: 3_000)
        let photo = PhotoFit.photoFrame(imageSize: image, in: view, mode: .fit)
        let corner = CGRect(x: 0.8, y: 0.8, width: 0.1, height: 0.1)

        let rect = PhotoFit.viewRect(forNormalized: corner, imageSize: image, in: view, mode: .fit)

        #expect(photo.contains(rect))
    }

    @Test("The sweep runs down the whole view for a filled shot and only the photo for a fitted one")
    func sweepFollowsThePhoto() {
        let image = CGSize(width: 4_000, height: 3_000)

        let fill = PhotoFit.sweepFrame(imageSize: image, in: view, mode: .fill)
        let fit = PhotoFit.sweepFrame(imageSize: image, in: view, mode: .fit)

        #expect(fill == CGRect(x: 0, y: 0, width: 200, height: 400))
        #expect(fit == CGRect(x: 0, y: 125, width: 200, height: 150))
    }

    @Test("The sweep has no frame for an empty image or view")
    func sweepEmptySizes() {
        #expect(PhotoFit.sweepFrame(imageSize: .zero, in: view, mode: .fit) == CGRect.zero)
        #expect(PhotoFit.sweepFrame(imageSize: CGSize(width: 10, height: 10), in: .zero, mode: .fill) == CGRect.zero)
    }

    @Test("An empty image or view has no frame in either mode")
    func emptySizes() {
        #expect(PhotoFit.photoFrame(imageSize: .zero, in: view, mode: .fit) == CGRect.zero)
        #expect(PhotoFit.photoFrame(imageSize: CGSize(width: 10, height: 10), in: .zero, mode: .fill) == CGRect.zero)
    }
}

/*-----------------------photo-zoom-content-tests-------------------------*/

@Suite("Photo Zoom Content Tests")
struct PhotoZoomContentTests {
    private let view = CGSize(width: 200, height: 400)
    /// A landscape photo fitted in the view: full width, with bars above and below.
    private let letterboxed = CGSize(width: 200, height: 100)
    /// A square photo filled in the view: full height, cut at the sides.
    private let filled = CGSize(width: 400, height: 400)

    @Test("A letterboxed photo cannot be panned off its bars at 2x")
    func letterboxedLimit() {
        let limit = PhotoZoom.maxOffset(scale: 2, in: view, content: letterboxed)

        #expect(limit == CGSize(width: 100, height: 0))
    }

    @Test("A letterboxed photo can pan vertically once it outgrows the height")
    func letterboxedLimitAtMaxZoom() {
        let limit = PhotoZoom.maxOffset(scale: 4, in: view, content: letterboxed)

        #expect(limit == CGSize(width: 300, height: 0))
        #expect(PhotoZoom.maxOffset(scale: 4, in: view, content: CGSize(width: 200, height: 150)) == CGSize(width: 300, height: 100))
    }

    @Test("A drag on a letterboxed photo moves it sideways only")
    func letterboxedDrag() {
        let zoom = PhotoZoom(scale: 2, offset: .zero).panned(by: CGSize(width: 500, height: 500), in: view, content: letterboxed)

        #expect(zoom.offset == CGSize(width: 100, height: 0))
    }

    @Test("A stray offset on a letterboxed photo is pulled back to the centre line")
    func letterboxedClamp() {
        let zoom = PhotoZoom(scale: 2, offset: CGSize(width: 10, height: 80)).clamped(in: view, content: letterboxed)

        #expect(zoom.offset == CGSize(width: 10, height: 0))
    }

    @Test("A filled photo's cut-off sides can be panned into")
    func filledLimitReachesCutEdges() {
        let limit = PhotoZoom.maxOffset(scale: 2, in: view, content: filled)

        #expect(limit == CGSize(width: 300, height: 200))
        #expect(PhotoZoom.maxOffset(scale: 1.5, in: view, content: filled) == CGSize(width: 200, height: 100))
    }

    @Test("A filled photo at 1x has no pan, though it is wider than the view")
    func filledAtOneHasNoPan() {
        let zoom = PhotoZoom(scale: 1, offset: CGSize(width: 50, height: 50)).clamped(in: view, content: filled)

        #expect(zoom == PhotoZoom.identity)
    }

    @Test("Pinching out to 1x on a fitted photo returns to the identity")
    func pinchOutReturnsToIdentity() {
        let start = PhotoZoom(scale: 2, offset: CGSize(width: 40, height: 0))

        let zoom = start.pinched(by: 0.1, about: CGPoint(x: 100, y: 200), in: view, content: letterboxed)

        #expect(zoom == PhotoZoom.identity)
    }

    @Test("A double-tap on a letterboxed photo keeps it centred vertically")
    func doubleTapKeepsLetterboxCentred() {
        let zoom = PhotoZoom.identity.toggled(at: CGPoint(x: 20, y: 10), in: view, content: letterboxed)

        #expect(zoom.scale == PhotoZoom.doubleTapScale)
        #expect(zoom.offset.height == 0)
    }

    @Test("Leaving the content out treats the whole view as the photo")
    func defaultContentIsTheView() {
        #expect(PhotoZoom.maxOffset(scale: 3, in: view) == PhotoZoom.maxOffset(scale: 3, in: view, content: view))
    }

    @Test("A box stays on its kanji in a fitted photo at every zoom")
    func boxStaysOnItsKanjiWhenFitted() {
        let image = CGSize(width: 1_000, height: 500)
        let box = PhotoFit.viewRect(forNormalized: CGRect(x: 0.5, y: 0.4, width: 0.1, height: 0.2), imageSize: image, in: view, mode: .fit)
        let anchor = CGPoint(x: box.midX, y: box.midY)

        let zoom = PhotoZoom.identity.pinched(by: 3, about: anchor, in: view, content: PhotoFit.photoFrame(imageSize: image, in: view, mode: .fit).size)

        let moved = zoom.apply(to: box, in: view)
        #expect(abs(moved.midX - anchor.x) < 0.001)
        #expect(abs(moved.midY - anchor.y) < 0.001)
    }
}
