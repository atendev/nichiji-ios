import CoreGraphics
import Foundation
import Testing
@testable import Nichiji

/*------------------------handwriting-accuracy-tests-----------------------*/

final class HandwritingFixtureToken {}

/// The 104 drawings exported from the prototype: points are `[x, y, t]` on a 360 pt canvas.
private struct HandwritingTestSet: Decodable {
    struct Sample: Decodable, Sendable {
        let target: String
        let strokes: [[[Double]]]
    }

    let samples: [Sample]
}

@Suite("Handwriting Accuracy Tests")
struct HandwritingAccuracyTests {
    /// Built once for the suite; the 2,383 templates are slow to build in a Debug test run.
    private static let matcher = Result { try HandwritingTemplateBuilder.matcher(contentStore: BundledKanjiContentStore()) }

    private func loadTestSet() throws -> HandwritingTestSet {
        let url = try #require(Bundle(for: HandwritingFixtureToken.self).url(forResource: "handwriting-testset", withExtension: "json"))
        return try JSONDecoder().decode(HandwritingTestSet.self, from: Data(contentsOf: url))
    }

    @Test("The matcher scores at least 76% top-1 and 89% top-5 on the drawn test set")
    func accuracyGate() async throws {
        let samples = try loadTestSet().samples
        #expect(samples.count == 104)
        let matcher = try Self.matcher.get()

        let ranks = await withTaskGroup(of: Int?.self) { group in
            for sample in samples {
                group.addTask {
                    let strokes = sample.strokes.map { stroke in stroke.map { CGPoint(x: $0[0], y: $0[1]) } }
                    return matcher.candidates(for: strokes, limit: 5).firstIndex(of: sample.target)
                }
            }
            return await group.reduce(into: [Int?]()) { $0.append($1) }
        }
        let top1 = Double(ranks.filter { $0 == 0 }.count) / Double(samples.count)
        let top5 = Double(ranks.filter { $0 != nil }.count) / Double(samples.count)

        #expect(top1 >= 0.76, "top-1 was \(top1)")
        #expect(top5 >= 0.89, "top-5 was \(top5)")
    }

    @Test("Every matcher candidate is a kanji the app ships")
    func candidatesAreShipped() throws {
        let matcher = try Self.matcher.get()
        let shipped = Set(try BundledKanjiContentStore().indexEntries().map(\.id))
        let sample = try #require(try loadTestSet().samples.first)
        let strokes = sample.strokes.map { stroke in stroke.map { CGPoint(x: $0[0], y: $0[1]) } }

        #expect(matcher.shippedKanji == shipped)
        #expect(matcher.templates.count == shipped.count)
        #expect(matcher.candidates(for: strokes, limit: 50).allSatisfy(shipped.contains))
    }

    @Test("Flattening the bundled 日 gives four strokes with curve samples")
    func flattensSun() throws {
        let paths = try BundledKanjiContentStore().strokePaths(for: "日")
        let strokes = HandwritingTemplateBuilder.strokes(fromSVGPaths: paths)

        #expect(strokes.count == 4)
        #expect(strokes.allSatisfy { $0.count > HandwritingTemplateBuilder.samplesPerCurve })
        #expect(strokes.flatMap { $0 }.allSatisfy { (0...StrokePathParser.viewBoxSize).contains($0.x) })
    }
}
