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

    private func makeModel(_ onDevice: TestOnDeviceHandwritingModel? = nil) -> HandwritingSearchModel {
        HandwritingSearchModel(onDevice: onDevice) { Self.testMatcher() }
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

    private func waitUntil(_ condition: () -> Bool) async {
        var tries = 0
        while !condition(), tries < 500 {
            tries += 1
            try? await Task.sleep(for: .milliseconds(10))
        }
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
        let model = HandwritingSearchModel(onDevice: nil) { throw TestOnDeviceHandwritingModel.Failure() }

        await model.open()
        #expect(model.matchState == .unavailable)
    }

    @Test("Before the model is ready, the matcher answers")
    func matcherBeforeModel() async {
        let onDevice = TestOnDeviceHandwritingModel(prepareResults: [false])
        let model = makeModel(onDevice)
        await model.open()

        draw(Self.horizontal, on: model)
        await settle(model)

        #expect(firstMatch(model) == "一")
        #expect(model.source == .matcher)
        #expect(onDevice.candidateCalls == 0)
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

    /*------------------------------download------------------------------*/

    @Test("Opening with the model absent requests the download once while it is in flight")
    func downloadOnceInFlight() async {
        let onDevice = TestOnDeviceHandwritingModel(prepareResults: [true])
        onDevice.holdsPrepare = true
        let model = makeModel(onDevice)

        let first = Task { await model.open() }
        await waitUntil { onDevice.hasHeldPrepare }
        let second = Task { await model.open() }
        await second.value

        #expect(onDevice.prepareCalls == 1)
        onDevice.releasePrepare()
        await first.value
        #expect(onDevice.isModelReady)
    }

    @Test("A failed download keeps the matcher, and the next open asks again")
    func failedDownloadRetries() async {
        let onDevice = TestOnDeviceHandwritingModel(prepareResults: [false, true])
        let model = makeModel(onDevice)

        await model.open()
        #expect(onDevice.prepareCalls == 1)
        #expect(!onDevice.isModelReady)

        await model.open()
        #expect(onDevice.prepareCalls == 2)
        #expect(onDevice.isModelReady)
    }

    @Test("Once the model is ready, a later open requests nothing")
    func readyModelIsNotRequested() async {
        let onDevice = TestOnDeviceHandwritingModel(isModelReady: true)
        let model = makeModel(onDevice)

        await model.open()
        await model.open()
        #expect(onDevice.prepareCalls == 0)
    }

    @Test("When the model lands, the current drawing switches to its matches")
    func switchesWhenModelLands() async {
        let onDevice = TestOnDeviceHandwritingModel(prepareResults: [true])
        onDevice.holdsPrepare = true
        onDevice.candidatesResult = .success(["十"])
        let model = makeModel(onDevice)

        let opening = Task { await model.open() }
        await waitUntil { model.matchState != .preparing }
        draw(Self.horizontal, on: model)
        await settle(model)
        #expect(model.source == .matcher)

        onDevice.releasePrepare()
        await opening.value
        await settle(model)
        #expect(model.source == .onDevice)
        #expect(model.matchState == .matches(["十"]))
        #expect(onDevice.lastInk?.strokes.count == 1)
    }

    /*------------------------------filtering-----------------------------*/

    @Test("Model candidates are filtered to single shipped kanji, deduplicated and capped at five")
    func filtersCandidates() async {
        let shipped: Set<String> = ["一", "二", "三", "四", "五", "六", "十"]
        let raw = ["学校", "十", "十", "Z", "一", "二", "三", "四", "五", "六"]
        #expect(HandwritingSearchModel.shippedCandidates(raw, shipped: shipped) == ["十", "一", "二", "三", "四"])

        let onDevice = TestOnDeviceHandwritingModel(isModelReady: true)
        onDevice.candidatesResult = .success(["学校", "十", "十", "Z", "一"])
        let model = makeModel(onDevice)
        await model.open()
        draw(Self.horizontal, on: model)
        await settle(model)
        #expect(model.matchState == .matches(["十", "一"]))
        #expect(model.source == .onDevice)
    }

    @Test("A throwing model falls back to the matcher")
    func throwingFallsBack() async {
        let onDevice = TestOnDeviceHandwritingModel(isModelReady: true)
        onDevice.candidatesResult = .failure(TestOnDeviceHandwritingModel.Failure())
        let model = makeModel(onDevice)
        await model.open()

        draw(Self.horizontal, on: model)
        await settle(model)
        #expect(onDevice.candidateCalls == 1)
        #expect(firstMatch(model) == "一")
        #expect(model.source == .matcher)
    }

    @Test("A model result with nothing shipped falls back to the matcher")
    func emptyAfterFilterFallsBack() async {
        let onDevice = TestOnDeviceHandwritingModel(isModelReady: true)
        onDevice.candidatesResult = .success(["Z", "学校"])
        let model = makeModel(onDevice)
        await model.open()

        draw(Self.horizontal, on: model)
        await settle(model)
        #expect(firstMatch(model) == "一")
        #expect(model.source == .matcher)
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
        let onDevice = TestOnDeviceHandwritingModel(isModelReady: true)
        onDevice.holdsCandidates = true
        onDevice.candidatesResult = .success(["十"])
        let model = makeModel(onDevice)
        await model.open()

        draw(Self.horizontal, on: model)
        let stale = model.recognitionTask
        await waitUntil { onDevice.hasHeldCandidates }
        model.clear()
        onDevice.releaseCandidates()
        await stale?.value

        #expect(model.matches.isEmpty)
        #expect(model.source == .matcher)
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
