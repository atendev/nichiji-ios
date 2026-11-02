import Foundation
import Testing
@testable import Nichiji

/*-------------------------dictionary-search-folding--------------------------*/

@Suite("Dictionary search folding Tests")
struct DictionarySearchFoldingTests {
    @Test("Macrons and doubled vowels fold together")
    func longVowelsCollapse() {
        let forms = ["Tōkyō", "tokyo", "toukyou", "tookyoo"].map(SearchFolding.romaji)

        #expect(Set(forms) == ["tokyo"])
        #expect(SearchFolding.romaji("yūjin") == SearchFolding.romaji("yuujin"))
        #expect(SearchFolding.romaji("kāsan") == SearchFolding.romaji("kaasan"))
    }

    @Test("shi, tsu, chi and mb fold to one spelling each")
    func spellingPairs() {
        #expect(SearchFolding.romaji("shimbun") == SearchFolding.romaji("sinbun"))
        #expect(SearchFolding.romaji("tsuki") == SearchFolding.romaji("tuki"))
        #expect(SearchFolding.romaji("chizu") == SearchFolding.romaji("tizu"))
    }

    @Test("Apostrophes, dots, hyphens and spaces drop from romaji")
    func markersDrop() {
        #expect(SearchFolding.romaji("kin'en") == "kinen")
        #expect(SearchFolding.romaji("hito.tsu") == SearchFolding.romaji("hitotu"))
        #expect(SearchFolding.romaji("Hito-") == "hito")
        #expect(SearchFolding.romaji("hito tsu") == SearchFolding.romaji("hito.tsu"))
    }

    @Test("Katakana folds to hiragana and okurigana markers drop")
    func kanaFolding() {
        #expect(SearchFolding.kana("ヒト") == "ひと")
        #expect(SearchFolding.kana("ひと.つ") == "ひとつ")
        #expect(SearchFolding.kana("ひと-") == "ひと")
        #expect(SearchFolding.kana("ラーメン") == "らーめん")
    }

    @Test("English folds hyphens and punctuation to single spaces")
    func englishFolding() {
        #expect(SearchFolding.english("One-sided") == "one sided")
        #expect(SearchFolding.english("one radical (no.1)") == "one radical no 1")
        #expect(SearchFolding.english("  Café  ") == "cafe")
    }

    @Test("The matcher tells exact, prefix and substring apart, and word starts apart from mid-word hits")
    func matcherTiers() {
        let one = Array("one".utf8)

        #expect(SearchMatcher.tier(of: one, in: "one", wordStartOnly: true) == .exact)
        #expect(SearchMatcher.tier(of: one, in: "one sided", wordStartOnly: true) == .prefix)
        #expect(SearchMatcher.tier(of: one, in: "the one", wordStartOnly: true) == .substring)
        #expect(SearchMatcher.tier(of: one, in: "someone", wordStartOnly: true) == nil)
        #expect(SearchMatcher.tier(of: one, in: "someone", wordStartOnly: false) == .substring)
        #expect(SearchMatcher.tier(of: one, in: "on", wordStartOnly: false) == nil)
    }

    @Test("A kanji anywhere in the query picks kanji mode, with distinct literals in typed order")
    func kanjiMode() {
        #expect(DictionaryQuery.parse("日本") == .kanji(text: "日本", literals: ["日", "本"]))
        #expect(DictionaryQuery.parse("月 日 月") == .kanji(text: "月日月", literals: ["月", "日"]))
        #expect(DictionaryQuery.parse("日abc") == .kanji(text: "日abc", literals: ["日"]))
    }

    @Test("Kana without kanji picks kana mode, folds katakana and drops Latin letters")
    func kanaMode() {
        #expect(DictionaryQuery.parse("にほん") == .kana("にほん"))
        #expect(DictionaryQuery.parse("ニホン") == .kana("にほん"))
        #expect(DictionaryQuery.parse("か a") == .kana("か"))
    }

    @Test("Latin only picks romaji plus English")
    func latinMode() {
        #expect(DictionaryQuery.parse("Tōkyō") == .latin(romaji: "tokyo", english: "tokyo"))
        #expect(DictionaryQuery.parse("one-sided") == .latin(romaji: "onesided", english: "one sided"))
    }

    @Test("One kana or kanji searches; one Latin letter, digits and blank text do not")
    func lengthGates() {
        #expect(DictionaryQuery.parse("ひ") != nil)
        #expect(DictionaryQuery.parse("日") != nil)
        #expect(DictionaryQuery.parse("ab") != nil)
        #expect(DictionaryQuery.parse("a") == nil)
        #expect(DictionaryQuery.parse("1") == nil)
        #expect(DictionaryQuery.parse("   ") == nil)
        #expect(DictionaryQuery.parse("") == nil)
    }
}
