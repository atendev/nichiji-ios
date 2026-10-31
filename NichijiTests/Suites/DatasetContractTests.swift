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

    @Test("Index decodes and matches the record count")
    func indexDecodes() throws {
        let data = try Data(contentsOf: Self.shared.appendingPathComponent("kanji-index.json"))
        let index = try JSONDecoder().decode(KanjiIndex.self, from: data)

        #expect(index.formatVersion == 1)
        #expect(index.entries.count == 2_383)
        #expect(index.entries.map(\.listIndex) == Array(0..<2_383))
        #expect(index.entries.first?.id == "日")
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
        #expect(entries.filter { $0.joyoGrade == nil }.count == 247)
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
    }

    @Test("Records carry no inline stroke paths")
    func recordsLeaveStrokePathsToSVG() throws {
        let entries = try Self.loadEntries()

        #expect(entries.allSatisfy { $0.strokePaths.isEmpty })
        #expect(entries.allSatisfy { $0.exampleWords.count <= 3 })
    }
}
