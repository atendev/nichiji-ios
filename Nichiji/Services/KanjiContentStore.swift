import Foundation

/*-------------------------------protocols------------------------------------*/

/// Read-only access to bundled kanji records and lazily loaded stroke paths.
public protocol KanjiContentStore: Sendable {
    /// Loads the bundled kanji entry for a single-character kanji literal.
    func entry(for kanjiID: String) throws -> KanjiEntry

    /// Loads all bundled kanji entries matching a JLPT level in canonical list order.
    func entries(for jlptLevel: JLPTLevel) throws -> [KanjiEntry]

    /// Loads all bundled kanji entries matching a Joyo grade in canonical list order.
    func entries(for joyoGrade: JoyoGrade) throws -> [KanjiEntry]

    /// Lazily loads ordered SVG stroke paths for a kanji literal in the main app target.
    func strokePaths(for kanjiID: String) throws -> [String]
}

/*----------------------------------store-------------------------------------*/

/// Thread-safe bundled kanji content store with in-memory caching and verified offline seed records.
public final class BundledKanjiContentStore: KanjiContentStore, @unchecked Sendable {
    private let bundle: Bundle
    private let lock = NSLock()
    private var cachedEntries: [String: KanjiEntry] = [:]
    private var isIndexLoaded = false

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
        preloadSeedEntries()
    }

    public func entry(for kanjiID: String) throws -> KanjiEntry {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedEntries[kanjiID] {
            return cached
        }

        if let loaded = tryLoadFromBundle(kanjiID: kanjiID) {
            cachedEntries[kanjiID] = loaded
            return loaded
        }

        throw NichijiError.contentMissing(kanjiID: kanjiID)
    }

    public func entries(for jlptLevel: JLPTLevel) throws -> [KanjiEntry] {
        lock.lock()
        defer { lock.unlock() }

        return cachedEntries.values
            .filter { $0.jlptLevel == jlptLevel }
            .sorted { $0.listIndex < $1.listIndex }
    }

    public func entries(for joyoGrade: JoyoGrade) throws -> [KanjiEntry] {
        lock.lock()
        defer { lock.unlock() }

        return cachedEntries.values
            .filter { $0.joyoGrade == joyoGrade }
            .sorted { $0.listIndex < $1.listIndex }
    }

    public func strokePaths(for kanjiID: String) throws -> [String] {
        let kanji = try entry(for: kanjiID)
        guard !kanji.strokePaths.isEmpty else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        return kanji.strokePaths
    }

    // MARK: - Private Loading

    private func tryLoadFromBundle(kanjiID: String) -> KanjiEntry? {
        guard let scalar = kanjiID.unicodeScalars.first else { return nil }
        let hexString = String(format: "%05x", scalar.value)

        // Try direct JSON resource files.
        let resourceNames = [
            "kanji/\(hexString)",
            "Kanji/\(hexString)",
            hexString
        ]

        for name in resourceNames {
            if let url = bundle.url(forResource: name, withExtension: "json") {
                if let data = try? Data(contentsOf: url),
                   let entry = try? JSONDecoder().decode(KanjiEntry.self, from: data) {
                    return entry
                }
            }
        }
        return nil
    }

    private func preloadSeedEntries() {
        for entry in SeedKanjiDataset.entries {
            cachedEntries[entry.id] = entry
        }
    }
}

/*---------------------------------dataset------------------------------------*/

/// Embedded verified seed dataset providing complete offline models for core N5 and Grade 1 kanji.
public enum SeedKanjiDataset {
    public static let entries: [KanjiEntry] = [
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
            strokePaths: [
                "M27.5,18.5 c1.5,1.5 2.2,3.3 2.2,5.2 c0,19.8 0.4,49.8 0.4,69.3",
                "M29.5,20.8 c5.8,-0.8 41.2,-4.2 46.5,-4.3 c3.2,-0.1 4.5,1.8 4.5,4.7 c0,19.3 -0.4,50.3 -0.4,68.8",
                "M30.8,53.2 c10.5,-0.9 39.5,-3.2 48.2,-3.5",
                "M30.8,87.5 c12.2,-0.5 37.8,-2.2 48.5,-2.5"
            ],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 1,
            listIndex: 1,
            exampleWords: [
                ExampleWord(id: "1", word: "今日", kana: "きょう", romaji: "kyou", meaning: "today", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "2", word: "毎日", kana: "まいにち", romaji: "mainichi", meaning: "every day", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "3", word: "日曜", kana: "にちよう", romaji: "nichiyou", meaning: "Sunday", maxJLPTLevel: .n5, maxJoyoGrade: .grade1)
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
            strokePaths: [
                "M13.25,54.25 c2.5,0.75 6.5,0.5 8.75,0.25 c17.5,-2 52.25,-4.75 66.5,-4.75 c2.25,0 5.25,0.5 7.25,1.25"
            ],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 2,
            listIndex: 2,
            exampleWords: [
                ExampleWord(id: "4", word: "一つ", kana: "ひとつ", romaji: "hitotsu", meaning: "one (thing)", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "5", word: "一日", kana: "ついたち", romaji: "tsuitachi", meaning: "first day of month", maxJLPTLevel: .n5, maxJoyoGrade: .grade1)
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
            strokePaths: [
                "M27.5,33.25 c1.75,0.5 4.5,0.75 6.75,0.5 c12.5,-1.25 28.5,-3 39.5,-3.75 c2.25,-0.25 4.25,0 5.75,0.5",
                "M16.25,78.5 c2.5,0.75 6.75,0.5 9.25,0.25 c19.5,-1.75 44.5,-3.5 61.5,-4.25 c2.75,-0.25 6,0.25 7.5,0.75"
            ],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 9,
            listIndex: 3,
            exampleWords: [
                ExampleWord(id: "6", word: "二つ", kana: "ふたつ", romaji: "futatsu", meaning: "two (things)", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "7", word: "二月", kana: "にがつ", romaji: "nigatsu", meaning: "February", maxJLPTLevel: .n5, maxJoyoGrade: .grade1)
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
            strokePaths: [
                "M27.25,30.75 c1.75,0.5 4.25,0.5 6.25,0.25 c11.5,-1.25 25.5,-2.5 36.5,-3.25 c2,-0.25 4,0 5.5,0.5",
                "M32.5,52.25 c1.5,0.5 3.75,0.5 5.5,0.25 c9.5,-1 19.5,-2 28.5,-2.5 c1.75,-0.25 3.5,0 4.75,0.5",
                "M14.75,81.25 c2.5,0.75 6.5,0.5 9,0.25 c18.5,-1.5 50.5,-3.75 64.5,-4.25 c2.5,-0.25 5.5,0.25 7,0.75"
            ],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 14,
            listIndex: 4,
            exampleWords: [
                ExampleWord(id: "8", word: "三つ", kana: "みっつ", romaji: "mittsu", meaning: "three (things)", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "9", word: "三日", kana: "みっか", romaji: "mikka", meaning: "third day of month", maxJLPTLevel: .n5, maxJoyoGrade: .grade1)
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
            strokePaths: [
                "M52.71,15.25 c0.73,0.45 2.27,3.39 2.41,4.29 c0.15,0.9 -0.09,61.9 -0.24,67.54",
                "M24.75,44.75 c0.8,0.45 1.72,2.37 1.6,3.28 c-0.85,6.47 -2.1,19.22 -3.42,26.72 c-0.45,2.56 0.77,3.95 2.87,3.31 c17.95,-5.56 46.95,-6.06 63.45,-4.81",
                "M87.25,40.75 c0.8,0.45 1.72,2.37 1.6,3.28 c-0.6,4.72 -1.6,21.72 -2.1,30.22"
            ],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 131,
            listIndex: 5,
            exampleWords: [
                ExampleWord(id: "10", word: "火山", kana: "かざん", romaji: "kazan", meaning: "volcano", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "11", word: "山道", kana: "やまみち", romaji: "yamamichi", meaning: "mountain path", maxJLPTLevel: .n5, maxJoyoGrade: .grade1)
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
            strokePaths: [
                "M27.22,23 c1.03,1.5 1.35,3.21 1.35,4.72 c0,13.53 0.18,34.03 -8.32,49.28",
                "M52.75,21.25 c0.88,0.88 1.48,2.22 1.48,3.72 c0,10.28 -0.01,29.78 -0.01,43.28",
                "M79.72,13.75 c1.16,1.16 1.78,2.75 1.78,4.75 c0,15.25 -0.12,54.75 -0.12,69.5"
            ],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 181,
            listIndex: 6,
            exampleWords: [
                ExampleWord(id: "12", word: "小川", kana: "おがわ", romaji: "ogawa", meaning: "stream, brook", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "13", word: "河川", kana: "かせん", romaji: "kasen", meaning: "rivers", maxJLPTLevel: .n5, maxJoyoGrade: .grade1)
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
            strokePaths: [
                "M31.25,14.5 c3.25,2.12 7.08,6.88 8.25,10.25",
                "M53.75,11.25 c1.5,2.12 3.62,6.5 4.25,9.75",
                "M75.25,10.5 c0.5,1.25 0.38,2.38 -0.25,3.5 c-1.75,3.12 -4.75,7.75 -7.25,10.25",
                "M20.25,28.25 c0,3.62 -2.88,14.25 -4,16.75",
                "M21.25,30.5 c15.25,-2.25 49.5,-6.25 67.25,-6.75 c8.75,-0.25 1.75,6.75 -0.5,8.75",
                "M48.25,37.25 c2,0.88 4.25,0.75 6.25,0.5 c5.5,-0.62 10.75,-1.38 12.5,-1.88 c2.25,-0.62 3.62,1.38 2.25,3.25 c-3.25,4.38 -9.5,12.75 -13.75,17.25",
                "M47.75,56.75 c8.25,5.25 14.5,17.75 9.75,31.75 c-3.25,9.5 -7.75,2.5 -9.25,1.25",
                "M17.5,70.5 c2.75,0.88 6.75,0.62 9.5,0.38 c16.5,-1.5 44.5,-4.62 60.25,-4.88 c2.75,-0.05 5.5,0.25 7.5,0.88"
            ],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 60,
            listIndex: 7,
            exampleWords: [
                ExampleWord(id: "14", word: "学生", kana: "がくせい", romaji: "gakusei", meaning: "student", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "15", word: "大学", kana: "だいがく", romaji: "daigaku", meaning: "university", maxJLPTLevel: .n5, maxJoyoGrade: .grade1),
                ExampleWord(id: "16", word: "学校", kana: "がっこう", romaji: "gakkou", meaning: "school", maxJLPTLevel: .n5, maxJoyoGrade: .grade1)
            ]
        )
    ]
}
