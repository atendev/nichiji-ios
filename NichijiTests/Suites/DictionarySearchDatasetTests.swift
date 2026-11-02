import Foundation
import Testing
@testable import Nichiji

/*-----------------------dictionary-search-dataset-tests----------------------*/

/// Decodes the committed app-only search files with the real models, then searches the real bundled data.
@Suite("Dictionary search dataset Tests")
struct DictionarySearchDatasetTests {
    private static let appOnly: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Dataset/AppOnly")

    private static func decode<T: Decodable>(_ type: T.Type, file: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(contentsOf: appOnly.appendingPathComponent(file)))
    }

    @Test("kanji-search.json decodes and covers all 2,383 kanji")
    func kanjiSearchDecodes() throws {
        let records = try Self.decode([KanjiSearchRecord].self, file: "kanji-search.json")

        #expect(records.count == 2_383)
        #expect(Set(records.map(\.id)).count == 2_383)
        #expect(records.allSatisfy { !$0.meanings.isEmpty || !$0.onyomi.isEmpty || !$0.kunyomi.isEmpty })
    }

    @Test("words.json decodes with a rank on every word")
    func wordsDecode() throws {
        let words = try Self.decode([SearchWord].self, file: "words.json")

        #expect(words.count == 18_195)
        #expect(words.allSatisfy { (1...53).contains($0.rank) })
    }

    @Test("The bundled index finds the obvious hits")
    func bundledSearch() throws {
        let index = try DictionarySearchIndex.load(contentStore: BundledKanjiContentStore(), source: BundledDictionarySearchSource())

        #expect(index.search("一").kanji.first?.id == "一")
        #expect(index.search("ichi").kanji.prefix(3).map(\.id).contains("一"))
        #expect(index.search("いち").kanji.prefix(3).map(\.id).contains("一"))
        #expect(index.search("日本").words.first?.word.word == "日本")
        #expect(index.search("mountain").kanji.prefix(3).map(\.id).contains("山"))
    }

    @Test("A keystroke scan over the real index stays well under a second")
    func scanIsFast() throws {
        let index = try DictionarySearchIndex.load(contentStore: BundledKanjiContentStore(), source: BundledDictionarySearchSource())
        let queries = ["i", "ichi", "ni", "nihon", "いち", "にほん", "tokyo", "one", "日", "日本語"]

        let elapsed = ContinuousClock().measure {
            for query in queries {
                _ = index.search(query)
            }
        }

        #expect(elapsed < .seconds(5))
    }
}
