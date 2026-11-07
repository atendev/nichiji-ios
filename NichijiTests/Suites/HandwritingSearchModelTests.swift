import CoreGraphics
import Foundation
import Testing
@testable import Nichiji

/*---------------------handwriting-search-model-tests----------------------*/

@MainActor
@Suite("Handwriting Search Model Tests")
struct HandwritingSearchModelTests {
    private nonisolated static let horizontal = [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)]
    private nonisolated static let vertical = [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1)]

    private nonisolated static func testMatcher() -> HandwritingTemplateMatcher {
        HandwritingTemplateMatcher(
            templates: [
                (kanji: "一", strokes: [horizontal]),
                (kanji: "十", strokes: [horizontal, vertical]),
                (kanji: "二", strokes: [[CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.8, y: 0.2)], [CGPoint(x: 0, y: 0.8), CGPoint(x: 1, y: 0.8)]])
            ],
            shippedKanji: ["一", "十", "二", "学"]
        )
    }

    private struct LoadFailure: Error {}

    private final class LoadCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0

        var count: Int { lock.withLock { value } }

        func increment() {
            lock.withLock { value += 1 }
        }
    }

    private func makeModel() -> HandwritingSearchModel {
        HandwritingSearchModel { Self.testMatcher() }
    }

    private func draw(_ points: [CGPoint], on model: HandwritingSearchModel) {
        model.beginStroke(at: points[0], time: 0)
        for point in points.dropFirst() {
            model.extendStroke(to: point, time: 0.1)
        }
        model.endStroke()
    }

    private func settle(_ model: HandwritingSearchModel) async {
        await model.recognitionTask?.value
    }

    private func firstMatch(_ model: HandwritingSearchModel) -> String? {
        guard case .matches(let kanji) = model.matchState else { return nil }
        return kanji.first
    }

    /*------------------------------states--------------------------------*/

    @Test("The row says Preparing until the templates load, then waits on an empty pad")
    func preparingThenWaiting() async {
        let model = makeModel()
        #expect(model.matchState == .preparing)

        await model.open()
        #expect(model.matchState == .waiting)
        #expect(model.pad.isEmpty)
    }

    @Test("Templates that fail to load leave the row unavailable")
    func templatesFail() async {
        let model = HandwritingSearchModel { throw LoadFailure() }

        await model.open()
        #expect(model.matchState == .unavailable)
    }

    @Test("Matches refresh after a finished stroke, not mid-stroke")
    func refreshesOnStrokeEnd() async {
        let model = makeModel()
        await model.open()

        model.beginStroke(at: CGPoint(x: 0, y: 0.5), time: 0)
        model.extendStroke(to: CGPoint(x: 1, y: 0.5), time: 0.1)
        #expect(model.recognitionTask == nil)
        #expect(model.matchState == .waiting)

        model.endStroke()
        #expect(model.recognitionTask != nil)
        await settle(model)
        #expect(firstMatch(model) == "一")
    }

    @Test("Opening again keeps the loaded templates")
    func templatesLoadOnce() async {
        let loads = LoadCounter()
        let model = HandwritingSearchModel {
            loads.increment()
            return Self.testMatcher()
        }

        await model.open()
        await model.open()
        #expect(loads.count == 1)
        #expect(model.matchState == .waiting)
    }

    @Test("The app's model loads the bundled templates")
    func liveLoadsBundledTemplates() async {
        let model = HandwritingSearchModel.live(contentStore: BundledKanjiContentStore())

        await model.open()
        #expect(model.matchState == .waiting)
    }

    /*-------------------------------editing------------------------------*/

    @Test("Undo refreshes the matches and Clear empties the row")
    func undoAndClear() async {
        let model = makeModel()
        await model.open()
        draw(Self.horizontal, on: model)
        draw(Self.vertical, on: model)
        await settle(model)
        #expect(firstMatch(model) == "十")

        model.undo()
        await settle(model)
        #expect(firstMatch(model) == "一")

        model.clear()
        #expect(model.matchState == .waiting)
        #expect(model.recognitionTask == nil)
    }

    @Test("A result that arrives after the drawing changed is dropped")
    func staleResultDropped() async {
        let model = makeModel()
        await model.open()

        draw(Self.horizontal, on: model)
        let stale = model.recognitionTask
        model.clear()
        await stale?.value

        #expect(model.matches.isEmpty)
        #expect(model.matchState == .waiting)
    }

    @Test("Choosing a match returns it for the search bar")
    func choosingAMatch() async {
        let model = makeModel()
        await model.open()
        draw(Self.horizontal, on: model)
        await settle(model)

        #expect(model.choose("一") == "一")
        #expect(model.choose("木") == nil)
    }
}
