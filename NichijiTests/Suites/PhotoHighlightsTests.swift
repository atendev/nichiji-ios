import CoreGraphics
import Foundation
import Testing
@testable import Nichiji

/*-------------------------photo-highlights-tests-------------------------*/

@Suite("Photo Highlights Geometry Tests")
struct PhotoHighlightsGeometryTests {
    @Test("A wide photo fills the view's height and crops the sides")
    func wideImageCropsSides() {
        let frame = PhotoFit.filledFrame(imageSize: CGSize(width: 400, height: 200), in: CGSize(width: 100, height: 100))

        #expect(frame == CGRect(x: -50, y: 0, width: 200, height: 100))
    }

    @Test("A tall photo fills the view's width and crops top and bottom")
    func tallImageCropsEnds() {
        let frame = PhotoFit.filledFrame(imageSize: CGSize(width: 200, height: 400), in: CGSize(width: 100, height: 100))

        #expect(frame == CGRect(x: 0, y: -50, width: 100, height: 200))
    }

    @Test("A photo with the view's own aspect fills it exactly")
    func matchingAspectFillsExactly() {
        let frame = PhotoFit.filledFrame(imageSize: CGSize(width: 1_024, height: 2_048), in: CGSize(width: 512, height: 1_024))

        #expect(frame == CGRect(x: 0, y: 0, width: 512, height: 1_024))
    }

    @Test("An empty image or view has no frame")
    func emptySizesHaveNoFrame() {
        #expect(PhotoFit.filledFrame(imageSize: .zero, in: CGSize(width: 100, height: 100)) == .zero)
        #expect(PhotoFit.filledFrame(imageSize: CGSize(width: 100, height: 100), in: .zero) == .zero)
    }

    @Test("A normalized box maps through the cropped frame")
    func boxMapsUnderAspectFill() {
        // Image 400 x 200 in a 100 x 100 view: drawn 200 x 100, shifted left by 50.
        let rect = PhotoFit.viewRect(
            forNormalized: CGRect(x: 0.5, y: 0.25, width: 0.25, height: 0.5),
            imageSize: CGSize(width: 400, height: 200),
            in: CGSize(width: 100, height: 100)
        )

        #expect(rect == CGRect(x: 50, y: 25, width: 50, height: 50))
    }

    @Test("A box in the cropped-off part lands outside the view")
    func croppedBoxLandsOutside() {
        let rect = PhotoFit.viewRect(
            forNormalized: CGRect(x: 0, y: 0, width: 0.1, height: 0.1),
            imageSize: CGSize(width: 400, height: 200),
            in: CGSize(width: 100, height: 100)
        )

        #expect(rect.minX < 0)
    }
}

@Suite("Photo Highlights Box Tests")
struct PhotoHighlightsBoxTests {
    private func rect(_ x: Double, _ y: Double = 0.1) -> CGRect {
        CGRect(x: x, y: y, width: 0.1, height: 0.1)
    }

    @Test("Each box is red when the kanji is new and green once it has started")
    func colorsFollowLearnerState() {
        let scanned = [
            ScannedKanji(id: "日", boxes: [rect(0.1)]),
            ScannedKanji(id: "語", boxes: [rect(0.3)])
        ]

        let boxes = PhotoHighlights.boxes(scanned: scanned, startedIDs: ["日"])

        #expect(boxes.map(\.kanji) == ["日", "語"])
        #expect(boxes.map(\.isNew) == [false, true])
    }

    @Test("A kanji that appears twice gets two boxes with their own ids")
    func repeatedKanjiGetsEveryBox() {
        let scanned = [
            ScannedKanji(id: "日", boxes: [rect(0.1), rect(0.5)]),
            ScannedKanji(id: "本", boxes: [rect(0.2)])
        ]

        let boxes = PhotoHighlights.boxes(scanned: scanned, startedIDs: [])

        #expect(boxes.map(\.kanji) == ["日", "日", "本"])
        #expect(boxes.map(\.id) == [0, 1, 2])
    }

    @Test("A kanji with no boxes adds none")
    func boxlessKanjiAddsNone() {
        let boxes = PhotoHighlights.boxes(scanned: [ScannedKanji(id: "日", boxes: [])], startedIDs: [])

        #expect(boxes.isEmpty)
    }

    @Test("A small box grows to a 44 x 44 pt tap region about its centre")
    func smallBoxGrowsToMinimumTarget() {
        let region = PhotoHighlights.tapRegion(for: CGRect(x: 100, y: 100, width: 20, height: 30))

        #expect(region == CGRect(x: 88, y: 93, width: 44, height: 44))
    }

    @Test("A box already past 44 pt keeps its size")
    func largeBoxKeepsSize() {
        let region = PhotoHighlights.tapRegion(for: CGRect(x: 0, y: 0, width: 80, height: 60))

        #expect(region == CGRect(x: 0, y: 0, width: 80, height: 60))
    }

    @Test("A tap inside a box picks it")
    func tapInsideBox() {
        let rects = [CGRect(x: 0, y: 0, width: 60, height: 60), CGRect(x: 200, y: 0, width: 60, height: 60)]

        #expect(PhotoHighlights.index(at: CGPoint(x: 230, y: 30), in: rects) == 1)
    }

    @Test("A tap just outside a small box still lands within its 44 pt region")
    func tapInGrownRegion() {
        let rects = [CGRect(x: 100, y: 100, width: 20, height: 20)]

        #expect(PhotoHighlights.index(at: CGPoint(x: 90, y: 110), in: rects) == 0)
        #expect(PhotoHighlights.index(at: CGPoint(x: 60, y: 110), in: rects) == nil)
    }

    @Test("Where two regions overlap the nearer box wins")
    func overlappingRegionsPickNearest() {
        // Two 20 pt boxes 10 pt apart: their 44 pt regions overlap from x 118 to 132.
        let rects = [CGRect(x: 100, y: 100, width: 20, height: 20), CGRect(x: 130, y: 100, width: 20, height: 20)]

        #expect(PhotoHighlights.index(at: CGPoint(x: 124, y: 110), in: rects) == 0)
        #expect(PhotoHighlights.index(at: CGPoint(x: 127, y: 110), in: rects) == 1)
    }

    @Test("A tap inside a box beats a neighbour's grown region")
    func insideBeatsNeighbourRegion() {
        let rects = [CGRect(x: 100, y: 100, width: 20, height: 20), CGRect(x: 126, y: 100, width: 20, height: 20)]

        // x 116 is inside the first box and inside the second's grown region (from 114).
        #expect(PhotoHighlights.index(at: CGPoint(x: 116, y: 110), in: rects) == 0)
        #expect(PhotoHighlights.index(at: CGPoint(x: 130, y: 110), in: rects) == 1)
    }

    @Test("A tap away from every box picks nothing")
    func tapOnEmptySpace() {
        #expect(PhotoHighlights.index(at: CGPoint(x: 5, y: 5), in: [CGRect(x: 100, y: 100, width: 50, height: 50)]) == nil)
        #expect(PhotoHighlights.index(at: CGPoint(x: 5, y: 5), in: []) == nil)
    }
}

@Suite("Scan Sweep Tests")
struct ScanSweepTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    private func at(_ seconds: Double) -> Date {
        start.addingTimeInterval(seconds)
    }

    @Test("The line loops down the photo every 1.6 s while the read runs")
    func lineLoopsWhileReading() throws {
        let sweep = ScanSweep(readStart: start)
        let first = try #require(sweep.linePosition(at: at(0)))
        let half = try #require(sweep.linePosition(at: at(0.8)))
        let secondPass = try #require(sweep.linePosition(at: at(2.4)))
        let sixthPass = try #require(sweep.linePosition(at: at(10)))

        #expect(first == 0)
        #expect(abs(half - 0.5) < 0.0001)
        #expect(abs(secondPass - 0.5) < 0.0001)
        #expect(abs(sixthPass - 0.25) < 0.0001)
    }

    @Test("A read that ends mid-pass lets the line finish that pass, then it goes")
    func lineEndsAtTheBottomOfTheCurrentPass() throws {
        var sweep = ScanSweep(readStart: start)
        sweep.finishRead(at: at(0.4))

        let nearBottom = try #require(sweep.linePosition(at: at(1.5)))

        #expect(nearBottom > 0.9)
        #expect(sweep.linePosition(at: at(1.7)) == nil)
        #expect(sweep.linePosition(at: at(5)) == nil)
    }

    @Test("A late read finishes the pass in progress, not a whole new one")
    func lateReadWaitsOnlyForThePassInProgress() {
        var sweep = ScanSweep(readStart: start)
        sweep.finishRead(at: at(4.0))

        // Phase 0.8 s: 0.8 s of line left, plus the box fade.
        #expect(abs(sweep.settleTime(reduceMotion: false) - (0.8 + ScanSweep.boxFade)) < 0.0001)
    }

    @Test("The line fades over the last 8% of a pass")
    func lineFadesAtTheBottom() {
        #expect(ScanSweep.lineOpacity(at: 0.5) == 1)
        #expect(ScanSweep.lineOpacity(at: 0.92) == 1)
        #expect(abs(ScanSweep.lineOpacity(at: 0.96) - 0.5) < 0.0001)
        #expect(ScanSweep.lineOpacity(at: 1) == 0)
    }

    @Test("No box shows before the results land")
    func noBoxBeforeResults() {
        let sweep = ScanSweep(readStart: start)

        #expect(sweep.boxProgress(at: at(1), normalizedY: 0.1, reduceMotion: false) == 0)
    }

    @Test("A box above the line when the results land fades in at once")
    func boxAboveTheLineFadesInAtOnce() {
        var sweep = ScanSweep(readStart: start)
        sweep.finishRead(at: at(1.0))

        // The line is at 1.0 s of 1.6 s; a box at 25% down was passed.
        #expect(sweep.boxProgress(at: at(1.0), normalizedY: 0.25, reduceMotion: false) == 0)
        #expect(abs(sweep.boxProgress(at: at(1.0 + ScanSweep.boxFade / 2), normalizedY: 0.25, reduceMotion: false) - 0.5) < 0.0001)
        #expect(sweep.boxProgress(at: at(1.0 + ScanSweep.boxFade), normalizedY: 0.25, reduceMotion: false) >= 0.9999)
    }

    @Test("A box below the line waits for the line to reach it")
    func boxBelowTheLineWaitsForIt() {
        var sweep = ScanSweep(readStart: start)
        sweep.finishRead(at: at(0.4))

        // Line at 0.4 s; a box at 75% down is reached at 1.2 s, 0.8 s after the results.
        #expect(sweep.boxProgress(at: at(1.2), normalizedY: 0.75, reduceMotion: false) < 0.001)
        #expect(sweep.boxProgress(at: at(1.2 + ScanSweep.boxFade), normalizedY: 0.75, reduceMotion: false) >= 0.9999)
    }

    @Test("Every box is in by the settle time")
    func everyBoxIsInBySettleTime() {
        var sweep = ScanSweep(readStart: start)
        sweep.finishRead(at: at(0.7))
        let settled = at(0.7 + sweep.settleTime(reduceMotion: false))

        for y in stride(from: 0.0, through: 1.0, by: 0.1) {
            #expect(sweep.boxProgress(at: settled, normalizedY: y, reduceMotion: false) >= 0.9999)
        }
    }

    @Test("Under Reduce Motion the boxes crossfade together in 0.2 s")
    func reduceMotionCrossfades() {
        var sweep = ScanSweep(readStart: start)
        sweep.finishRead(at: at(0.4))

        #expect(abs(sweep.boxProgress(at: at(0.5), normalizedY: 0.9, reduceMotion: true) - 0.5) < 0.0001)
        #expect(sweep.boxProgress(at: at(0.6), normalizedY: 0.1, reduceMotion: true) >= 0.9999)
        #expect(sweep.settleTime(reduceMotion: true) == ScanSweep.reducedFade)
    }

    @Test("A second finish does not move the results time")
    func secondFinishIsIgnored() {
        var sweep = ScanSweep(readStart: start)
        sweep.finishRead(at: at(0.4))
        sweep.finishRead(at: at(1.4))

        #expect(sweep.resultsAt == at(0.4))
    }
}
