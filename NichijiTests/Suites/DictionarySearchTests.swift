import Foundation
import Testing
@testable import Nichiji

/*---------------------------dictionary-search-tests--------------------------*/

@Suite("Dictionary search Tests")
struct DictionarySearchTests {
    private let index = SearchFixtures.index

    private func kanjiIDs(_ query: String) -> [String] {
        index.search(query).kanji.map(\.id)
    }

    private func wordForms(_ query: String) -> [String] {
        index.search(query).words.map(\.word.word)
    }

    @Test("Kanji in the query list each distinct kanji in typed order and skip unknown ones")
    func kanjiQueryOrder() {
        #expect(kanjiIDs("月日月") == ["月", "日"])
        #expect(kanjiIDs("日猫") == ["日"])
        #expect(kanjiIDs("猫").isEmpty)
    }

    @Test("A kanji query returns the words that contain it, exact before prefix")
    func kanjiQueryWords() {
        #expect(wordForms("日本") == ["日本", "日本語"])
        #expect(wordForms("聞") == ["新聞"])
        #expect(kanjiIDs("聞").isEmpty)
    }

    @Test("Kana readings rank exact before prefix, break ties by frequency with unranked last")
    func kanaReadings() {
        #expect(kanjiIDs("ひと") == ["人", "一"])
        #expect(kanjiIDs("ヒト") == ["人", "一"])
        #expect(kanjiIDs("ひとつ") == ["一"])
        #expect(wordForms("ひと") == ["一人"])
    }

    @Test("Substring hits rank after prefix hits")
    func kanaSubstring() {
        #expect(kanjiIDs("つ") == ["月", "日", "一"])
    }

    @Test("Romaji matches readings with markers stripped and folds long vowels and spellings")
    func romajiMatching() {
        #expect(kanjiIDs("hito") == ["人", "一"])
        #expect(kanjiIDs("kyo") == ["京"])
        #expect(kanjiIDs("sin") == ["新"])
        #expect(wordForms("toukyou") == ["東京"])
        #expect(wordForms("shimbun") == ["新聞"])
        #expect(wordForms("nihon") == ["日本", "日本語"])
    }

    @Test("English matches word starts only, per gloss, with hyphens read as spaces")
    func englishMatching() {
        #expect(kanjiIDs("one") == ["一"])
        #expect(wordForms("one") == ["一人", "一面"])
        #expect(wordForms("person himself") == ["本人"])
        #expect(index.search("meone").isEmpty)
    }

    @Test("Kanji field order is reading before meaning at the same tier")
    func fieldOrder() {
        let records = [
            KanjiSearchRecord(id: "甲", meanings: ["kyo"], onyomi: [], kunyomi: []),
            KanjiSearchRecord(id: "乙", meanings: ["other"], onyomi: [KanjiReading(kind: .onyomi, kana: "キョ", romaji: "kyo")], kunyomi: [])
        ]
        let entries = [
            KanjiIndexEntry(id: "甲", primaryMeaning: "kyo", primaryReading: "", strokeCount: 1, jlptLevel: nil, joyoGrade: nil, listIndex: 0, frequencyRank: 1),
            KanjiIndexEntry(id: "乙", primaryMeaning: "other", primaryReading: "キョ", strokeCount: 1, jlptLevel: nil, joyoGrade: nil, listIndex: 1)
        ]
        let fieldIndex = DictionarySearchIndex(kanjiIndex: entries, records: records, words: [])

        #expect(fieldIndex.search("kyo").kanji.map(\.id) == ["乙", "甲"])
    }

    @Test("Equal frequency falls back to list order")
    func listOrderTieBreak() {
        let ids = ["甲", "乙", "丙"]
        let records = ids.map { KanjiSearchRecord(id: $0, meanings: ["thing"], onyomi: [], kunyomi: []) }
        let entries = ids.enumerated().reversed().map { position, id in
            KanjiIndexEntry(id: id, primaryMeaning: "thing", primaryReading: "", strokeCount: 1, jlptLevel: nil, joyoGrade: nil, listIndex: position)
        }
        let tieIndex = DictionarySearchIndex(kanjiIndex: entries, records: records, words: [])

        #expect(tieIndex.search("thing").kanji.map(\.id) == ids)
    }

    @Test("Words rank by tier, then rank, then shorter kana")
    func wordOrder() {
        let words = [
            SearchWord(id: "a", word: "亜", kana: "あいう", romaji: "aiu", meaning: "x", rank: 1),
            SearchWord(id: "b", word: "意", kana: "あい", romaji: "ai", meaning: "x", rank: 1),
            SearchWord(id: "c", word: "宇", kana: "あえ", romaji: "ae", meaning: "x", rank: 0),
            SearchWord(id: "d", word: "絵", kana: "いあ", romaji: "ia", meaning: "x", rank: 0)
        ]
        let wordIndex = DictionarySearchIndex(kanjiIndex: [], records: [], words: words)

        #expect(wordIndex.search("あ").words.map(\.word.word) == ["宇", "意", "亜", "絵"])
        #expect(wordIndex.search("あい").words.map(\.word.word) == ["意", "亜"])
    }

    @Test("Results are capped at 20 kanji and 50 words")
    func caps() {
        let scalars = (0..<60).compactMap { Unicode.Scalar(0x4E00 + $0) }.map { String($0) }
        let records = scalars.map { KanjiSearchRecord(id: $0, meanings: ["thing"], onyomi: [], kunyomi: []) }
        let entries = scalars.enumerated().map { position, id in
            KanjiIndexEntry(id: id, primaryMeaning: "thing", primaryReading: "", strokeCount: 1, jlptLevel: nil, joyoGrade: nil, listIndex: position)
        }
        let words = scalars.enumerated().map { position, scalar in
            SearchWord(id: "w\(position)", word: scalar + scalar, kana: "かな", romaji: "kana", meaning: "thing", rank: position)
        }
        let capped = DictionarySearchIndex(kanjiIndex: entries, records: records, words: words).search("thing")

        #expect(capped.kanji.count == DictionarySearchIndex.kanjiLimit)
        #expect(capped.words.count == DictionarySearchIndex.wordLimit)
    }

    @Test("No hit gives empty results that keep the typed query; too-short queries give none")
    func emptyStates() {
        let none = index.search("  zzzz ")

        #expect(none.isEmpty)
        #expect(none.query == "zzzz")
        #expect(index.search("o").isEmpty)
    }

    @Test("A word row opens detail, a sheet or nothing by how many distinct dataset kanji it has")
    func wordTapActions() throws {
        let nihon = try #require(index.search("日本").words.first)
        let hibi = try #require(index.search("日日").words.first)
        let thanks = try #require(index.search("ありがとう").words.first)

        #expect(nihon.kanji.map(\.id) == ["日", "本"])
        #expect(nihon.tapAction == .chooseKanji)
        #expect(hibi.tapAction == .openKanji("日"))
        #expect(thanks.tapAction == .unavailable)
        #expect(index.kanjiTiles(in: "日本日").map(\.id) == ["日", "本"])
    }

    @Test("A word with a kanji outside the dataset only tiles the kanji it has")
    func tilesSkipUnknownKanji() throws {
        let paper = try #require(index.search("新聞").words.first)

        #expect(paper.kanji.map(\.id) == ["新"])
        #expect(paper.tapAction == .openKanji("新"))
    }
}
