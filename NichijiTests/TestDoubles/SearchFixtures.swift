import Foundation
@testable import Nichiji

/*-------------------------------search-fixtures------------------------------*/

enum SearchFixtures {
    private static func reading(_ kind: ReadingKind, _ kana: String, _ romaji: String) -> KanjiReading {
        KanjiReading(kind: kind, kana: kana, romaji: romaji)
    }

    private static func kanji(
        _ id: String,
        listIndex: Int,
        frequency: Int?,
        meanings: [String],
        onyomi: [KanjiReading] = [],
        kunyomi: [KanjiReading] = []
    ) -> (KanjiIndexEntry, KanjiSearchRecord) {
        let entry = KanjiIndexEntry(
            id: id,
            primaryMeaning: meanings.first ?? "",
            primaryReading: (onyomi + kunyomi).first?.kana ?? "",
            strokeCount: 4,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            listIndex: listIndex,
            frequencyRank: frequency
        )
        return (entry, KanjiSearchRecord(id: id, meanings: meanings, onyomi: onyomi, kunyomi: kunyomi))
    }

    private static let kanjiRows: [(KanjiIndexEntry, KanjiSearchRecord)] = [
        kanji("日", listIndex: 0, frequency: 1, meanings: ["day", "sun"],
              onyomi: [reading(.onyomi, "ニチ", "nichi"), reading(.onyomi, "ジツ", "jitsu")],
              kunyomi: [reading(.kunyomi, "ひ", "hi"), reading(.kunyomi, "-び", "-bi"), reading(.kunyomi, "か", "ka")]),
        kanji("月", listIndex: 1, frequency: 2, meanings: ["month", "moon"],
              onyomi: [reading(.onyomi, "ゲツ", "getsu"), reading(.onyomi, "ガツ", "gatsu")],
              kunyomi: [reading(.kunyomi, "つき", "tsuki")]),
        kanji("本", listIndex: 2, frequency: 10, meanings: ["book", "origin"],
              onyomi: [reading(.onyomi, "ホン", "hon")], kunyomi: [reading(.kunyomi, "もと", "moto")]),
        kanji("一", listIndex: 3, frequency: nil, meanings: ["one"],
              onyomi: [reading(.onyomi, "イチ", "ichi"), reading(.onyomi, "イツ", "itsu")],
              kunyomi: [reading(.kunyomi, "ひと.つ", "hito.tsu"), reading(.kunyomi, "ひと-", "hito-")]),
        kanji("人", listIndex: 4, frequency: 5, meanings: ["person"],
              onyomi: [reading(.onyomi, "ジン", "jin"), reading(.onyomi, "ニン", "nin")],
              kunyomi: [reading(.kunyomi, "ひと", "hito")]),
        kanji("東", listIndex: 5, frequency: 20, meanings: ["east"],
              onyomi: [reading(.onyomi, "トウ", "tō")], kunyomi: [reading(.kunyomi, "ひがし", "higashi")]),
        kanji("京", listIndex: 6, frequency: 30, meanings: ["capital"],
              onyomi: [reading(.onyomi, "キョウ", "kyō")]),
        kanji("新", listIndex: 7, frequency: 40, meanings: ["new"],
              onyomi: [reading(.onyomi, "シン", "shin")], kunyomi: [reading(.kunyomi, "あたら.しい", "atara.shii")])
    ]

    static let kanjiIndex = kanjiRows.map(\.0)
    static let records = kanjiRows.map(\.1)

    static let words = [
        SearchWord(id: "1", word: "日本", kana: "にほん", romaji: "nihon", meaning: "Japan", rank: 5),
        SearchWord(id: "2", word: "日本語", kana: "にほんご", romaji: "nihongo", meaning: "Japanese (language)", rank: 9),
        SearchWord(id: "3", word: "東京", kana: "とうきょう", romaji: "tōkyō", meaning: "Tokyo", rank: 3),
        SearchWord(id: "4", word: "一人", kana: "ひとり", romaji: "hitori", meaning: "one person, alone", rank: 2),
        SearchWord(id: "5", word: "日日", kana: "ひび", romaji: "hibi", meaning: "every day, days", rank: 12),
        SearchWord(id: "6", word: "一面", kana: "いちめん", romaji: "ichimen", meaning: "one-sided, whole surface", rank: 7),
        SearchWord(id: "7", word: "本人", kana: "ほんにん", romaji: "honnin", meaning: "the person himself, someone in question", rank: 4),
        SearchWord(id: "8", word: "新聞", kana: "しんぶん", romaji: "shinbun", meaning: "newspaper", rank: 1),
        SearchWord(id: "9", word: "月日", kana: "つきひ", romaji: "tsukihi", meaning: "months and days, time", rank: 20),
        SearchWord(id: "10", word: "ありがとう", kana: "ありがとう", romaji: "arigatō", meaning: "thank you", rank: 1)
    ]

    static var index: DictionarySearchIndex {
        DictionarySearchIndex(kanjiIndex: kanjiIndex, records: records, words: words)
    }
}
