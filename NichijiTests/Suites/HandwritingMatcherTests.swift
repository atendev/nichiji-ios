import CoreGraphics
import Testing
@testable import Nichiji

/*-------------------------handwriting-matcher-tests-----------------------*/

@Suite("Handwriting Matcher Tests")
struct HandwritingMatcherTests {
    private let horizontal = [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)]
    private let vertical = [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1)]

    @Test("Resampling gives 12 points and keeps the endpoints")
    func resampleKeepsEndpoints() {
        let points = HandwritingTemplateMatcher.resample(
            [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1)],
            count: HandwritingTemplateMatcher.pointsPerStroke
        )

        #expect(points.count == 12)
        #expect(points.first == CGPoint(x: 0, y: 0))
        #expect(points.last == CGPoint(x: 1, y: 1))
    }

    @Test("A one-point or zero-length stroke resamples without crashing")
    func degenerateStrokes() {
        let dot = CGPoint(x: 0.4, y: 0.6)

        #expect(HandwritingTemplateMatcher.resample([dot], count: 12) == Array(repeating: dot, count: 12))
        #expect(HandwritingTemplateMatcher.resample([dot, dot], count: 12) == Array(repeating: dot, count: 12))

        let matcher = HandwritingTemplateMatcher(templates: [(kanji: "一", strokes: [horizontal])])
        #expect(matcher.candidates(for: [[dot]], limit: 5) == ["一"])
        #expect(matcher.candidates(for: [], limit: 5).isEmpty)
    }

    @Test("Bounding-box normalization keeps the aspect and centres")
    func normalizationKeepsAspect() {
        let normalized = HandwritingTemplateMatcher.normalize([[CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 1)]])

        #expect(normalized == [[CGPoint(x: 0, y: 0.25), CGPoint(x: 1, y: 0.75)]])
    }

    @Test("Hungarian finds the minimum assignment")
    func hungarianMinimum() {
        let matrix: [Double] = [
            4, 1, 3,
            2, 0, 5,
            3, 2, 2
        ]

        #expect(HungarianSolver.minimumCost(matrix, size: 3) == 5)
    }

    @Test("A reversed stroke costs its forward cost plus 0.08")
    func reversedStrokeCost() {
        let line = HandwritingTemplateMatcher.resample(horizontal, count: 12)
        let forward = line.flatMap { [Double($0.x), Double($0.y)] }
        let reversed = line.reversed().flatMap { [Double($0.x), Double($0.y)] }

        #expect(HandwritingTemplateMatcher.strokeCost(forward, at: 0, forward, at: 0) == 0)
        #expect(abs(HandwritingTemplateMatcher.strokeCost(forward, at: 0, reversed, at: 0) - 0.08) < 1e-9)
    }

    @Test("Templates more than two strokes away are skipped")
    func strokeWindow() {
        let five = Array(repeating: horizontal, count: 5)
        let matcher = HandwritingTemplateMatcher(templates: [
            (kanji: "一", strokes: [horizontal]),
            (kanji: "三", strokes: [horizontal, horizontal, horizontal]),
            (kanji: "五", strokes: five)
        ])

        let found = matcher.candidates(for: [horizontal], limit: 5)
        #expect(found.contains("一"))
        #expect(found.contains("三"))
        #expect(!found.contains("五"))
    }

    @Test("Swapped stroke order still ranks the right kanji first")
    func freeStrokeOrder() {
        let topBar = [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.8, y: 0.2)]
        let bottomBar = [CGPoint(x: 0, y: 0.8), CGPoint(x: 1, y: 0.8)]
        let matcher = HandwritingTemplateMatcher(templates: [
            (kanji: "二", strokes: [topBar, bottomBar]),
            (kanji: "十", strokes: [horizontal, vertical])
        ])

        #expect(matcher.candidates(for: [vertical, horizontal], limit: 5).first == "十")
    }

    @Test("Ties keep template order")
    func tiesKeepOrder() {
        let matcher = HandwritingTemplateMatcher(templates: [
            (kanji: "甲", strokes: [horizontal]),
            (kanji: "乙", strokes: [horizontal]),
            (kanji: "丙", strokes: [horizontal])
        ])

        #expect(matcher.candidates(for: [horizontal], limit: 5) == ["甲", "乙", "丙"])
    }

    @Test("The shipped set defaults to the template kanji")
    func shippedDefaults() {
        let matcher = HandwritingTemplateMatcher(templates: [(kanji: "一", strokes: [horizontal])])

        #expect(matcher.shippedKanji == ["一"])
    }
}

/*---------------------------handwriting-pad-tests-------------------------*/

@Suite("Handwriting Pad Tests")
struct HandwritingPadTests {
    @Test("Begin, extend and end record one stroke with times from the first touch")
    func recordsStroke() {
        var pad = HandwritingPad()
        pad.begin(at: CGPoint(x: 0.1, y: 0.2), time: 100)
        pad.extend(to: CGPoint(x: 0.3, y: 0.4), time: 100.25)
        #expect(pad.strokeCount == 1)
        #expect(!pad.canUndo)
        pad.end()

        #expect(pad.strokes == [[HandwritingPoint(x: 0.1, y: 0.2, t: 0), HandwritingPoint(x: 0.3, y: 0.4, t: 250)]])
        #expect(pad.currentStroke == nil)
        #expect(pad.canUndo)

        pad.begin(at: CGPoint(x: 0.5, y: 0.5), time: 101)
        pad.end()
        #expect(pad.strokes[1] == [HandwritingPoint(x: 0.5, y: 0.5, t: 1000)])
    }

    @Test("Points are clamped to the pad")
    func clamps() {
        var pad = HandwritingPad()
        pad.begin(at: CGPoint(x: -0.5, y: 1.5), time: 0)
        pad.end()

        #expect(pad.strokes == [[HandwritingPoint(x: 0, y: 1, t: 0)]])
    }

    @Test("Undo removes the last stroke and clear empties the pad")
    func undoAndClear() {
        var pad = HandwritingPad()
        for index in 0..<3 {
            pad.begin(at: CGPoint(x: 0.1 * Double(index), y: 0.5), time: Double(index))
            pad.end()
        }
        pad.undo()
        #expect(pad.strokeCount == 2)

        pad.clear()
        #expect(pad.isEmpty)
        pad.begin(at: CGPoint(x: 0.5, y: 0.5), time: 50)
        pad.end()
        #expect(pad.strokes == [[HandwritingPoint(x: 0.5, y: 0.5, t: 0)]])
    }

    @Test("The stroke note counts strokes and pluralizes")
    func strokeNote() {
        var pad = HandwritingPad()
        #expect(pad.note == "Matches appear as you draw")
        pad.begin(at: CGPoint(x: 0.5, y: 0.5), time: 0)
        #expect(pad.note == "1 stroke drawn")
        pad.end()
        pad.begin(at: CGPoint(x: 0.2, y: 0.5), time: 1)
        pad.end()
        #expect(pad.note == "2 strokes drawn")
    }
}
