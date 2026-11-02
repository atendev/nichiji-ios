import Foundation
@testable import Nichiji

/*---------------------------------fixtures-----------------------------------*/

/// Seven-entry fixture dataset of core N5 and Grade 1 kanji for tests that do not need the bundle.
enum SeedKanjiDataset {
    static let entries: [KanjiEntry] = [
        KanjiEntry(
            id: "日",
            meanings: ["day", "sun", "Japan"],
            onyomi: [
                KanjiReading(kind: .onyomi, kana: "ニチ", romaji: "nichi"),
                KanjiReading(kind: .onyomi, kana: "ジツ", romaji: "jitsu")
            ],
            kunyomi: [
                KanjiReading(kind: .kunyomi, kana: "ひ", romaji: "hi"),
                KanjiReading(kind: .kunyomi, kana: "-び", romaji: "-bi"),
                KanjiReading(kind: .kunyomi, kana: "-か", romaji: "-ka")
            ],
            radical: KanjiRadical(character: "日", meaning: "sun"),
            strokeCount: 4,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 1,
            listIndex: 1,
            exampleWords: [
                ExampleWord(id: "1", word: "今日", kana: "きょう", romaji: "kyou", meaning: "today"),
                ExampleWord(id: "2", word: "毎日", kana: "まいにち", romaji: "mainichi", meaning: "every day"),
                ExampleWord(id: "3", word: "日曜", kana: "にちよう", romaji: "nichiyou", meaning: "Sunday")
            ]
        ),
        KanjiEntry(
            id: "一",
            meanings: ["one"],
            onyomi: [
                KanjiReading(kind: .onyomi, kana: "イチ", romaji: "ichi"),
                KanjiReading(kind: .onyomi, kana: "イツ", romaji: "itsu")
            ],
            kunyomi: [
                KanjiReading(kind: .kunyomi, kana: "ひと-", romaji: "hito-"),
                KanjiReading(kind: .kunyomi, kana: "ひと.つ", romaji: "hito.tsu")
            ],
            radical: KanjiRadical(character: "一", meaning: "one"),
            strokeCount: 1,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 2,
            listIndex: 2,
            exampleWords: [
                ExampleWord(id: "4", word: "一つ", kana: "ひとつ", romaji: "hitotsu", meaning: "one (thing)"),
                ExampleWord(id: "5", word: "一日", kana: "ついたち", romaji: "tsuitachi", meaning: "first day of month")
            ]
        ),
        KanjiEntry(
            id: "二",
            meanings: ["two"],
            onyomi: [
                KanjiReading(kind: .onyomi, kana: "ニ", romaji: "ni"),
                KanjiReading(kind: .onyomi, kana: "ジ", romaji: "ji")
            ],
            kunyomi: [
                KanjiReading(kind: .kunyomi, kana: "ふた-", romaji: "futa-"),
                KanjiReading(kind: .kunyomi, kana: "ふた.つ", romaji: "futa.tsu")
            ],
            radical: KanjiRadical(character: "二", meaning: "two"),
            strokeCount: 2,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 9,
            listIndex: 3,
            exampleWords: [
                ExampleWord(id: "6", word: "二つ", kana: "ふたつ", romaji: "futatsu", meaning: "two (things)"),
                ExampleWord(id: "7", word: "二月", kana: "にがつ", romaji: "nigatsu", meaning: "February")
            ]
        ),
        KanjiEntry(
            id: "三",
            meanings: ["three"],
            onyomi: [
                KanjiReading(kind: .onyomi, kana: "サン", romaji: "san")
            ],
            kunyomi: [
                KanjiReading(kind: .kunyomi, kana: "み-", romaji: "mi-"),
                KanjiReading(kind: .kunyomi, kana: "みっ.つ", romaji: "mit.tsu")
            ],
            radical: KanjiRadical(character: "一", meaning: "one"),
            strokeCount: 3,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 14,
            listIndex: 4,
            exampleWords: [
                ExampleWord(id: "8", word: "三つ", kana: "みっつ", romaji: "mittsu", meaning: "three (things)"),
                ExampleWord(id: "9", word: "三日", kana: "みっか", romaji: "mikka", meaning: "third day of month")
            ]
        ),
        KanjiEntry(
            id: "山",
            meanings: ["mountain"],
            onyomi: [
                KanjiReading(kind: .onyomi, kana: "サン", romaji: "san")
            ],
            kunyomi: [
                KanjiReading(kind: .kunyomi, kana: "やま", romaji: "yama")
            ],
            radical: KanjiRadical(character: "山", meaning: "mountain"),
            strokeCount: 3,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 131,
            listIndex: 5,
            exampleWords: [
                ExampleWord(id: "10", word: "火山", kana: "かざん", romaji: "kazan", meaning: "volcano"),
                ExampleWord(id: "11", word: "山道", kana: "やまみち", romaji: "yamamichi", meaning: "mountain path")
            ]
        ),
        KanjiEntry(
            id: "川",
            meanings: ["river", "stream"],
            onyomi: [
                KanjiReading(kind: .onyomi, kana: "セン", romaji: "sen")
            ],
            kunyomi: [
                KanjiReading(kind: .kunyomi, kana: "かわ", romaji: "kawa")
            ],
            radical: KanjiRadical(character: "巛", meaning: "river"),
            strokeCount: 3,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 181,
            listIndex: 6,
            exampleWords: [
                ExampleWord(id: "12", word: "小川", kana: "おがわ", romaji: "ogawa", meaning: "stream, brook"),
                ExampleWord(id: "13", word: "河川", kana: "かせん", romaji: "kasen", meaning: "rivers")
            ]
        ),
        KanjiEntry(
            id: "学",
            meanings: ["study", "learning", "science"],
            onyomi: [
                KanjiReading(kind: .onyomi, kana: "ガク", romaji: "gaku")
            ],
            kunyomi: [
                KanjiReading(kind: .kunyomi, kana: "まな.ぶ", romaji: "mana.bu")
            ],
            radical: KanjiRadical(character: "子", meaning: "child"),
            strokeCount: 8,
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 60,
            listIndex: 7,
            exampleWords: [
                ExampleWord(id: "14", word: "学生", kana: "がくせい", romaji: "gakusei", meaning: "student"),
                ExampleWord(id: "15", word: "大学", kana: "だいがく", romaji: "daigaku", meaning: "university"),
                ExampleWord(id: "16", word: "学校", kana: "がっこう", romaji: "gakkou", meaning: "school")
            ]
        )
    ]
}
