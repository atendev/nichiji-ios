import Testing
import Foundation
@testable import Nichiji

/*-----------------------------content-tests------------------------------*/

@Suite("KanjiContentStore Tests")
struct KanjiContentStoreTests {
    @Test("Loading existing entry returns decoded model")
    func loadExistingEntry() async throws {
        let entry = KanjiEntry(
            id: "日",
            meanings: ["day", "sun"],
            onyomi: [KanjiReading(kind: .onyomi, kana: "ニチ", romaji: "nichi")],
            kunyomi: [KanjiReading(kind: .kunyomi, kana: "ひ", romaji: "hi")],
            radical: KanjiRadical(character: "日", meaning: "sun"),
            strokeCount: 4,
            strokePaths: ["M0,0 L10,10"],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 1,
            canonicalIndex: 1,
            exampleWords: []
        )
        let store = TestKanjiContentStore(entries: [entry])

        let loaded = try await store.loadEntry(id: "日")
        #expect(loaded.id == "日")
        #expect(loaded.meanings.first == "day")
    }

    @Test("Loading missing entry throws contentMissing error")
    func loadMissingEntryThrows() async throws {
        let store = TestKanjiContentStore()
        await #expect(throws: NichijiError.self) {
            try await store.loadEntry(id: "未知")
        }
    }
}
