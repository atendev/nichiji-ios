import Testing
import Foundation
@testable import Nichiji

/*-----------------------------content-tests------------------------------*/

@Suite("KanjiContentStore Tests")
struct KanjiContentStoreTests {
    @Test("Loading existing entry returns complete decoded model")
    func loadExistingEntry() throws {
        let store = BundledKanjiContentStore()
        let entry = try store.entry(for: "日")

        #expect(entry.id == "日")
        #expect(entry.meanings.contains("day"))
        #expect(entry.meanings.contains("sun"))
        #expect(entry.strokeCount == 4)
        #expect(entry.radical.character == "日")
        #expect(entry.onyomi.first?.kana == "ニチ")
        #expect(entry.kunyomi.first?.kana == "ひ")
        #expect(entry.exampleWords.count >= 2)
    }

    @Test("Filtering by JLPT level returns sorted entries")
    func filterByJLPTLevel() throws {
        let store = BundledKanjiContentStore()
        let n5Entries = try store.entries(for: .n5)

        #expect(!n5Entries.isEmpty)
        #expect(n5Entries.allSatisfy { $0.jlptLevel == .n5 })
        // Check sorted by listIndex
        let indices = n5Entries.map(\.listIndex)
        #expect(indices == indices.sorted())
    }

    @Test("Filtering by Joyo grade returns sorted entries")
    func filterByJoyoGrade() throws {
        let store = BundledKanjiContentStore()
        let grade1Entries = try store.entries(for: .grade1)

        #expect(!grade1Entries.isEmpty)
        #expect(grade1Entries.allSatisfy { $0.joyoGrade == .grade1 })
        let indices = grade1Entries.map(\.listIndex)
        #expect(indices == indices.sorted())
    }

    @Test("Retrieving stroke paths returns valid ordered SVG paths")
    func loadStrokePaths() throws {
        let store = BundledKanjiContentStore()
        let paths = try store.strokePaths(for: "日")

        #expect(paths.count == 4)
        #expect(paths.allSatisfy { $0.starts(with: "M") })
    }

    @Test("Querying missing kanji throws contentMissing error")
    func missingKanjiThrowsError() {
        let store = BundledKanjiContentStore()
        #expect(throws: NichijiError.self) {
            try store.entry(for: "未知")
        }
        #expect(throws: NichijiError.self) {
            try store.strokePaths(for: "未知")
        }
    }

    @Test("TestKanjiContentStore double satisfies protocol contracts")
    func testDoubleBehavior() throws {
        let sample = KanjiEntry(
            id: "学",
            meanings: ["study"],
            onyomi: [KanjiReading(kind: .onyomi, kana: "ガク", romaji: "gaku")],
            kunyomi: [],
            radical: KanjiRadical(character: "子", meaning: "child"),
            strokeCount: 8,
            strokePaths: ["M0,0 L10,10"],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 60,
            listIndex: 7,
            exampleWords: []
        )
        let double = TestKanjiContentStore(entries: [sample])

        let retrieved = try double.entry(for: "学")
        #expect(retrieved.id == "学")

        let n5 = try double.entries(for: .n5)
        #expect(n5.count == 1)

        let paths = try double.strokePaths(for: "学")
        #expect(paths.count == 1)

        #expect(throws: NichijiError.self) {
            try double.entry(for: "木")
        }
    }
}
