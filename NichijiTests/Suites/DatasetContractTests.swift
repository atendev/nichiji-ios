import Testing
import Foundation
@testable import Nichiji

/*--------------------------dataset-contract-tests---------------------------*/

/// Decodes the committed `Dataset/` with the real models so a schema drift fails here, not at runtime.
@Suite("Dataset contract Tests")
struct DatasetContractTests {
    private static let shared: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Dataset/Shared")

    private static func loadEntries() throws -> [KanjiEntry] {
        let folder = shared.appendingPathComponent("kanji")
        let urls = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        return try urls.filter { $0.pathExtension == "json" }.map { try JSONDecoder().decode(KanjiEntry.self, from: Data(contentsOf: $0)) }
    }

    private static let appOnly: URL = shared.deletingLastPathComponent().appendingPathComponent("AppOnly")

    @Test("Index decodes and matches the record count")
    func indexDecodes() throws {
        let data = try Data(contentsOf: Self.shared.appendingPathComponent("kanji-index.json"))
        let index = try JSONDecoder().decode(KanjiIndex.self, from: data)

        #expect(index.formatVersion == 1)
        #expect(index.entries.count == 6_464)
        #expect(index.entries.map(\.listIndex) == Array(0..<6_464))
        #expect(index.entries.first?.id == "日")
    }

    @Test("Classification counts match KANJIDIC2 and JIS X 0208, in the index and the records")
    func classificationCounts() throws {
        let entries = try Self.loadEntries()
        let data = try Data(contentsOf: Self.shared.appendingPathComponent("kanji-index.json"))
        let index = try JSONDecoder().decode(KanjiIndex.self, from: data)

        for counts in [
            Dictionary(grouping: entries, by: \.classification).mapValues(\.count),
            Dictionary(grouping: index.entries, by: \.classification).mapValues(\.count)
        ] {
            #expect(counts[.joyo] == 2_136)
            #expect(counts[.jinmeiyo] == 863)
            #expect(counts[.hyogai] == 3_465)
        }
        #expect(entries.filter { ($0.classification == .joyo) != ($0.joyoGrade != nil) }.isEmpty)
    }

    @Test("Stroke SVGs exist for every kanji except 89 jinmeiyo kanji KanjiVG lacks")
    func strokeFileCoverage() throws {
        let entries = try Self.loadEntries()
        let folder = Self.appOnly.appendingPathComponent("stroke-order")
        let hex = { (id: String) in String(format: "%05x", id.unicodeScalars.first!.value) }
        let missing = entries.filter { !FileManager.default.fileExists(atPath: folder.appendingPathComponent("\(hex($0.id)).svg").path) }

        #expect(missing.count == 89)
        #expect(missing.allSatisfy { $0.classification == .jinmeiyo })
    }

    @Test("Joyo grade counts match KANJIDIC2")
    func gradeCounts() throws {
        let entries = try Self.loadEntries()
        let counts = Dictionary(grouping: entries.compactMap(\.joyoGrade), by: { $0 }).mapValues(\.count)

        #expect(counts[.grade1] == 80)
        #expect(counts[.grade2] == 160)
        #expect(counts[.grade3] == 200)
        #expect(counts[.grade4] == 202)
        #expect(counts[.grade5] == 193)
        #expect(counts[.grade6] == 191)
        #expect(counts[.secondary] == 1_110)
        #expect(entries.filter { $0.joyoGrade == nil }.count == 4_328)
    }

    @Test("JLPT level counts match the pinned lists")
    func levelCounts() throws {
        let entries = try Self.loadEntries()
        let counts = Dictionary(grouping: entries.compactMap(\.jlptLevel), by: { $0 }).mapValues(\.count)

        #expect(counts[.n5] == 84)
        #expect(counts[.n4] == 169)
        #expect(counts[.n3] == 387)
        #expect(counts[.n2] == 398)
        #expect(counts[.n1] == 1_345)
        #expect(entries.filter(\.isJLPTLevelEstimated).count == 172)
        #expect(entries.filter { $0.jlptLevel == nil }.count == 4_081)
    }

    @Test("Records carry at most three example words")
    func recordsCapExampleWords() throws {
        let entries = try Self.loadEntries()

        #expect(entries.allSatisfy { $0.exampleWords.count <= 3 })
        #expect(entries.filter { $0.exampleWords.isEmpty }.count == 1_339)
        #expect(entries.filter { $0.meanings.isEmpty }.count == 25)
    }
}
