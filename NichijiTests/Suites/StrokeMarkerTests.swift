import CoreGraphics
import SwiftUI
import Testing
@testable import Nichiji

/*--------------------------stroke-marker-tests---------------------------*/

@Suite("Stroke Marker Tests")
struct StrokeMarkerTests {
    private func parsedMarker(_ data: String) -> StrokeMarker? {
        StrokePathParser.parse(data).marker
    }

    private func expectMarker(_ data: String, start: (CGFloat, CGFloat), direction: (CGFloat, CGFloat), sourceLocation: SourceLocation = #_sourceLocation) {
        guard let marker = parsedMarker(data), let vector = marker.direction else {
            Issue.record("No marker for \(data)", sourceLocation: sourceLocation)
            return
        }
        #expect(abs(marker.start.x - start.0) < 0.001, sourceLocation: sourceLocation)
        #expect(abs(marker.start.y - start.1) < 0.001, sourceLocation: sourceLocation)
        #expect(abs(vector.dx - direction.0) < 0.002, sourceLocation: sourceLocation)
        #expect(abs(vector.dy - direction.1) < 0.002, sourceLocation: sourceLocation)
    }

    // The expected values below were checked by hand against each stroke's shape and computed
    // with an independent script that follows the same 10-unit chord rule.

    @Test("一 stroke 1 starts at the left end and heads right, from M…c")
    func relativeCurveStart() {
        expectMarker(
            "M11,54.25c3.19,0.62,6.25,0.75,9.73,0.5c20.64-1.5,50.39-5.12,68.58-5.24c3.6-0.02,5.77,0.24,7.57,0.49",
            start: (11, 54.25), direction: (0.99882, 0.04848)
        )
    }

    @Test("十 stroke 2 starts at the top and heads down, from M…c")
    func verticalStart() {
        expectMarker(
            "M52.22,11.63c1.4,1.4,2.2,3.96,2.2,6.26c0,1.13-0.03,51.22-0.19,73.41c-0.03,3.96-0.06,6.83-0.08,8.08",
            start: (52.22, 11.63), direction: (0.22605, 0.97412)
        )
    }

    @Test("小 stroke 3 heads down and right, from M…C")
    func absoluteCurveStart() {
        expectMarker("M80.96,47.12C86.62,52,95.25,64.62,97,72", start: (80.96, 47.12), direction: (0.66535, 0.74653))
    }

    @Test("A relative first move is an absolute point")
    func relativeMoveStart() {
        expectMarker(
            "m47.71,33.43c0.74,0.74,0.79,1.66,0.73,2.82C47.75,50,44.75,69.63,34.75,84.75",
            start: (47.71, 33.43), direction: (0.02106, 0.99978)
        )
    }

    @Test("A line stroke shorter than the chord points at its end")
    func shortLineStart() {
        expectMarker("M10,20l3,4", start: (10, 20), direction: (0.6, 0.8))
    }

    @Test("A long line stroke points along the line, from M…L")
    func longLineStart() {
        expectMarker("M10,10L10,40", start: (10, 10), direction: (0, 1))
    }

    @Test("A smooth curve with no previous curve starts its first control at the start point")
    func smoothCurveStart() {
        expectMarker("M10,10S20,10,30,20", start: (10, 10), direction: (0.96548, 0.26047))
    }

    @Test("The first curve's tick does not set the direction")
    func chordIgnoresShortFirstSegment() {
        // The first segment is 4 units long and points up. The chord ends 6 units into the second one, at (16, 46).
        expectMarker("M10,50l0,-4l20,0", start: (10, 50), direction: (0.83205, -0.55470))
    }

    @Test("A stroke with no length has a start and no direction")
    func zeroLengthStroke() {
        let marker = parsedMarker("M5,5")
        #expect(marker?.start == CGPoint(x: 5, y: 5))
        #expect(marker?.direction == nil)
        #expect(marker?.arrowPath() == nil)
    }

    @Test("Data with no move has no marker")
    func noMove() {
        #expect(parsedMarker("") == nil)
        #expect(parsedMarker("L5,5") == nil)
    }

    @Test("Parsing for the marker draws the same path as before")
    func pathUnchanged() {
        let data = "M80.96,47.12C86.62,52,95.25,64.62,97,72"
        #expect(StrokePathParser.parse(data).path == StrokePathParser.path(from: data))
    }

    @Test("The dot is centred on the start point")
    func dotGeometry() {
        let bounds = StrokeMarker(start: CGPoint(x: 20, y: 30), direction: nil).dotPath(radius: 4.5).boundingRect
        #expect(abs(bounds.midX - 20) < 0.001)
        #expect(abs(bounds.midY - 30) < 0.001)
        #expect(abs(bounds.width - 9) < 0.001)
    }

    @Test("The arrow sits above a stroke heading right")
    func arrowAboveRightwardStroke() {
        let arrow = StrokeMarker(start: CGPoint(x: 10, y: 20), direction: CGVector(dx: 1, dy: 0)).arrowPath()
        let bounds = arrow?.boundingRect ?? .null
        // Tail 2 units ahead of the start and 8 above it, an 11-unit shaft, and 4-unit arms at 43°.
        #expect(abs(bounds.minX - 12) < 0.001)
        #expect(abs(bounds.maxX - 23) < 0.001)
        #expect(abs(bounds.minY - (12 - 4 * sin(0.75))) < 0.001)
        #expect(abs(bounds.maxY - (12 + 4 * sin(0.75))) < 0.001)
    }

    @Test("The arrow sits to the right of a stroke heading down")
    func arrowBesideDownwardStroke() {
        let arrow = StrokeMarker(start: CGPoint(x: 50, y: 10), direction: CGVector(dx: 0, dy: 1)).arrowPath()
        let bounds = arrow?.boundingRect ?? .null
        #expect(abs(bounds.minY - 12) < 0.001)
        #expect(abs(bounds.maxY - 23) < 0.001)
        #expect(abs(bounds.midX - 58) < 0.001)
    }

    @Test("Each of the eight directions has its own word")
    func directionWords() {
        let diagonal: CGFloat = 0.70710678
        let cases: [(CGFloat, CGFloat, String)] = [
            (1, 0, "right"), (diagonal, diagonal, "down-right"), (0, 1, "down"), (-diagonal, diagonal, "down-left"),
            (-1, 0, "left"), (-diagonal, -diagonal, "up-left"), (0, -1, "up"), (diagonal, -diagonal, "up-right")
        ]
        for (dx, dy, word) in cases {
            let marker = StrokeMarker(start: .zero, direction: CGVector(dx: dx, dy: dy))
            #expect(marker.directionWord == word)
        }
        #expect(StrokeMarker(start: .zero, direction: nil).directionWord == nil)
    }

    @Test("The VoiceOver label keeps the stroke number and adds the direction")
    func accessibilityLabels() {
        let down = StrokeMarker(start: .zero, direction: CGVector(dx: 0, dy: 1))
        #expect(StrokeMarker.accessibilityLabel(stroke: 2, of: 4, marker: down) == "Stroke 2 of 4, starts going down")
        #expect(StrokeMarker.accessibilityLabel(stroke: 2, of: 4, marker: StrokeMarker(start: .zero, direction: nil)) == "Stroke 2 of 4")
        #expect(StrokeMarker.accessibilityLabel(stroke: 1, of: 1, marker: nil) == "Stroke 1 of 1")
    }

    @Test("A real stroke's label names its direction")
    func realStrokeLabel() {
        let data = "M52.22,11.63c1.4,1.4,2.2,3.96,2.2,6.26c0,1.13-0.03,51.22-0.19,73.41c-0.03,3.96-0.06,6.83-0.08,8.08"
        #expect(StrokeMarker.accessibilityLabel(stroke: 2, of: 2, marker: parsedMarker(data)) == "Stroke 2 of 2, starts going down")
    }
}
