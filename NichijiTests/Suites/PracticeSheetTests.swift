import CoreGraphics
import Testing
@testable import Nichiji

/*-----------------------------practice-tests-----------------------------*/

@Suite("Practice Sheet Tests")
struct PracticeSheetTests {
    @Test("A new pad is empty")
    func newPadIsEmpty() {
        let pad = PracticePad()
        #expect(pad.isEmpty)
        #expect(pad.strokeCount == 0)
        #expect(!pad.canUndo)
        #expect(pad.allStrokes.isEmpty)
    }

    @Test("A drag records one stroke with its points")
    func dragRecordsOneStroke() {
        var pad = PracticePad()
        pad.begin(at: CGPoint(x: 0.1, y: 0.2))
        pad.extend(to: CGPoint(x: 0.3, y: 0.4))
        pad.end()

        #expect(pad.strokeCount == 1)
        #expect(pad.strokes == [[CGPoint(x: 0.1, y: 0.2), CGPoint(x: 0.3, y: 0.4)]])
        #expect(pad.currentStroke == nil)
        #expect(pad.canUndo)
    }

    @Test("A stroke in progress counts but cannot be undone")
    func unfinishedStrokeCounts() {
        var pad = PracticePad()
        pad.begin(at: CGPoint(x: 0.5, y: 0.5))

        #expect(pad.strokeCount == 1)
        #expect(!pad.isEmpty)
        #expect(!pad.canUndo)
        #expect(pad.countLabel(total: 8) == "1 stroke drawn · 8 in the kanji")
    }

    @Test("A tap counts as one stroke")
    func tapCountsAsStroke() {
        var pad = PracticePad()
        pad.begin(at: CGPoint(x: 0.5, y: 0.5))
        pad.end()

        #expect(pad.strokeCount == 1)
        #expect(pad.strokes == [[CGPoint(x: 0.5, y: 0.5)]])
    }

    @Test("Undo removes only the last finished stroke")
    func undoRemovesLastStroke() {
        var pad = PracticePad()
        draw(on: &pad, from: CGPoint(x: 0.1, y: 0.1), to: CGPoint(x: 0.2, y: 0.2))
        draw(on: &pad, from: CGPoint(x: 0.3, y: 0.3), to: CGPoint(x: 0.4, y: 0.4))
        #expect(pad.strokeCount == 2)

        pad.undo()
        #expect(pad.strokeCount == 1)
        #expect(pad.strokes.first?.first == CGPoint(x: 0.1, y: 0.1))

        pad.undo()
        #expect(pad.isEmpty)
        #expect(!pad.canUndo)
    }

    @Test("Undo on an empty pad does nothing")
    func undoOnEmptyPad() {
        var pad = PracticePad()
        pad.undo()
        #expect(pad == PracticePad())
    }

    @Test("Clear empties the pad, including a stroke in progress")
    func clearEmptiesPad() {
        var pad = PracticePad()
        draw(on: &pad, from: CGPoint(x: 0.1, y: 0.1), to: CGPoint(x: 0.2, y: 0.2))
        pad.begin(at: CGPoint(x: 0.6, y: 0.6))

        pad.clear()
        #expect(pad.isEmpty)
        #expect(pad.currentStroke == nil)
    }

    @Test("Points outside the pad are clamped to its edges")
    func pointsAreClamped() {
        var pad = PracticePad()
        pad.begin(at: CGPoint(x: -0.2, y: 0.5))
        pad.extend(to: CGPoint(x: 1.4, y: 2))
        pad.end()

        #expect(pad.strokes == [[CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 1)]])
    }

    @Test("Extending without a stroke in progress is ignored")
    func extendWithoutBegin() {
        var pad = PracticePad()
        pad.extend(to: CGPoint(x: 0.5, y: 0.5))
        pad.end()
        #expect(pad.isEmpty)
    }

    @Test("The counter label reads singular and plural")
    func countLabel() {
        var pad = PracticePad()
        #expect(pad.countLabel(total: 8) == "0 strokes drawn · 8 in the kanji")

        draw(on: &pad, from: CGPoint(x: 0.1, y: 0.1), to: CGPoint(x: 0.2, y: 0.2))
        #expect(pad.countLabel(total: 8) == "1 stroke drawn · 8 in the kanji")

        draw(on: &pad, from: CGPoint(x: 0.3, y: 0.3), to: CGPoint(x: 0.4, y: 0.4))
        #expect(pad.countLabel(total: 1) == "2 strokes drawn · 1 in the kanji")
    }

    @Test("A target maps the entry and its stroke paths")
    func targetMapsEntry() throws {
        let entry = try TestKanjiContentStore(entries: SeedKanjiDataset.entries).entry(for: "日")
        let target = PracticeTarget(entry: entry, strokePaths: ["M1 1L2 2"])

        #expect(target.id == "日")
        #expect(target.kanji == "日")
        #expect(target.meaning == entry.meanings.first)
        #expect(target.strokeCount == entry.strokeCount)
        #expect(target.strokePaths == ["M1 1L2 2"])
    }

    @Test("Missing stroke data keeps the entry's stroke count")
    func missingStrokeData() throws {
        let store = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        let entry = try store.entry(for: "日")
        let paths = (try? store.strokePaths(for: entry.id)) ?? []
        let target = PracticeTarget(entry: entry, strokePaths: paths)

        #expect(target.strokePaths.isEmpty)
        #expect(target.strokeCount == entry.strokeCount)
        #expect(target.strokeCount > 0)
    }

    @Test("A kanji with no meanings maps to an empty meaning")
    func emptyMeaning() {
        let target = PracticeTarget(kanji: "日", meanings: [], strokeCount: 4, strokePaths: [])
        #expect(target.meaning.isEmpty)
    }

    private func draw(on pad: inout PracticePad, from start: CGPoint, to end: CGPoint) {
        pad.begin(at: start)
        pad.extend(to: end)
        pad.end()
    }
}
