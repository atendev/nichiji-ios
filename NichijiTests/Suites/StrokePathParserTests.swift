import CoreGraphics
import SwiftUI
import Testing
@testable import Nichiji

/*--------------------------stroke-path-tests-----------------------------*/

@Suite("Stroke Path Parser Tests")
struct StrokePathParserTests {
    private func expectPoint(_ point: CGPoint?, _ x: CGFloat, _ y: CGFloat) {
        guard let point else {
            Issue.record("Path has no current point")
            return
        }
        #expect(abs(point.x - x) < 0.001)
        #expect(abs(point.y - y) < 0.001)
    }

    @Test("Compact KanjiVG data with packed commands parses")
    func compactData() {
        let path = StrokePathParser.path(from: "M11,54.25c3.19,0.62,6.25,0.75,9.73,0.5")

        #expect(!path.isEmpty)
        expectPoint(path.currentPoint, 20.73, 54.75)
    }

    @Test("Minus signs start a new number")
    func packedNegatives() {
        let path = StrokePathParser.path(from: "M10,10c1-2,3-4,5-6")

        expectPoint(path.currentPoint, 15, 4)
    }

    @Test("Smooth curves continue from the previous curve")
    func smoothCurves() {
        let path = StrokePathParser.path(from: "M0,0C0,10,10,10,10,0s10-10,20,0S40,10,50,0")

        expectPoint(path.currentPoint, 50, 0)
    }

    @Test("Malformed data stops without looping")
    func malformedData() {
        let path = StrokePathParser.path(from: "M1,1Z5 x")

        #expect(!path.isEmpty)
    }

    @Test("Every bundled stroke of 日 draws inside the viewBox")
    func bundledStrokes() throws {
        let paths = try BundledKanjiContentStore().strokePaths(for: "日")
        let viewBox = CGRect(x: 0, y: 0, width: StrokePathParser.viewBoxSize, height: StrokePathParser.viewBoxSize)

        for data in paths {
            let bounds = StrokePathParser.path(from: data).boundingRect
            #expect(bounds.width > 0 || bounds.height > 0)
            #expect(viewBox.contains(bounds))
        }
    }
}
