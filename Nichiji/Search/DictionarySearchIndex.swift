import Foundation

/*---------------------------------source-------------------------------------*/

/// Read-only access to the app-only search files. Kept apart from `KanjiContentStore` because the widget has neither file.
protocol DictionarySearchSource: Sendable {
    func searchRecords() throws -> [KanjiSearchRecord]
    func searchWords() throws -> [SearchWord]
}

/// Reads `kanji-search.json` and `words.json` from the app bundle.
final class BundledDictionarySearchSource: DictionarySearchSource, @unchecked Sendable {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func searchRecords() throws -> [KanjiSearchRecord] {
        try decode([KanjiSearchRecord].self, resource: "kanji-search")
    }

    func searchWords() throws -> [SearchWord] {
        try decode([SearchWord].self, resource: "words")
    }

    private func decode<T: Decodable>(_ type: T.Type, resource: String) throws -> T {
        guard let url = bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(type, from: data)
        else {
            throw NichijiError.contentMissing(kanjiID: resource)
        }
        return value
    }
}

/*---------------------------------rows---------------------------------------*/

private struct KanjiRow: Sendable {
    let entry: KanjiIndexEntry
    /// Hiragana-folded onyomi and kunyomi.
    let readings: [String]
    let romaji: [String]
    let meanings: [String]
}

private struct WordRow: Sendable {
    let word: SearchWord
    let kana: String
    /// The written form, kana-folded so katakana and hiragana meet.
    let written: String
    let romaji: String
    /// `meaning` split at ", " into English-folded glosses.
    let glosses: [String]
}

private struct WordHit {
    let tier: MatchTier
    let row: WordRow
}

private struct KanjiHit {
    let match: KanjiMatch
    let entry: KanjiIndexEntry
}

/*---------------------------------index--------------------------------------*/

/// The folded in-memory index: one linear scan per query over every kanji and common word.
struct DictionarySearchIndex: Sendable {
    static let kanjiLimit = 20
    static let wordLimit = 50

    private let kanjiRows: [KanjiRow]
    private let wordRows: [WordRow]
    private let entriesByID: [String: KanjiIndexEntry]

    init(kanjiIndex: [KanjiIndexEntry], records: [KanjiSearchRecord], words: [SearchWord]) {
        let entries = Dictionary(kanjiIndex.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        entriesByID = entries
        kanjiRows = records.compactMap { record in
            entries[record.id].map { Self.kanjiRow(entry: $0, record: record) }
        }
        wordRows = words.map(Self.wordRow)
    }

    /// Reads the index, the per-kanji search records and the word list. Run it off the main actor.
    static func load(contentStore: any KanjiContentStore, source: any DictionarySearchSource) throws -> DictionarySearchIndex {
        DictionarySearchIndex(
            kanjiIndex: try contentStore.indexEntries(),
            records: try source.searchRecords(),
            words: try source.searchWords()
        )
    }

    /*-------------------------------search---------------------------------*/

    func search(_ rawQuery: String) -> DictionarySearchResults {
        let shown = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let query = DictionaryQuery.parse(rawQuery) else {
            return DictionarySearchResults(query: shown, kanji: [], words: [])
        }
        switch query {
        case .kanji(let text, let literals):
            let kanji = literals.compactMap { entriesByID[$0] }
            return results(shown, kanji: Array(kanji.prefix(Self.kanjiLimit)), words: kanjiQueryWords(text))
        case .kana(let text):
            return results(shown, kanji: kanaQueryKanji(text), words: kanaQueryWords(text))
        case .latin(let romaji, let english):
            return results(shown, kanji: latinQueryKanji(romaji: romaji, english: english), words: latinQueryWords(romaji: romaji, english: english))
        }
    }

    /// The distinct kanji of a word that exist in the dataset, in written order.
    func kanjiTiles(in word: String) -> [KanjiIndexEntry] {
        var seen = Set<String>()
        var tiles: [KanjiIndexEntry] = []
        for scalar in word.unicodeScalars {
            let literal = String(scalar)
            if let entry = entriesByID[literal], seen.insert(literal).inserted {
                tiles.append(entry)
            }
        }
        return tiles
    }

    private func results(_ shown: String, kanji: [KanjiIndexEntry], words: [SearchWord]) -> DictionarySearchResults {
        DictionarySearchResults(
            query: shown,
            kanji: kanji,
            words: words.map { WordResult(word: $0, kanji: kanjiTiles(in: $0.word)) }
        )
    }

    /*-------------------------------kanji----------------------------------*/

    private func kanaQueryKanji(_ text: String) -> [KanjiIndexEntry] {
        let needle = Array(text.utf8)
        return rankedKanji { row in
            SearchMatcher.bestTier(of: needle, in: row.readings, wordStartOnly: false).map { KanjiMatch(tier: $0, field: .reading) }
        }
    }

    private func latinQueryKanji(romaji: String, english: String) -> [KanjiIndexEntry] {
        let romajiNeedle = Array(romaji.utf8)
        let englishNeedle = Array(english.utf8)
        return rankedKanji { row in
            let reading = SearchMatcher.bestTier(of: romajiNeedle, in: row.romaji, wordStartOnly: false)
            let meaning = SearchMatcher.bestTier(of: englishNeedle, in: row.meanings, wordStartOnly: true)
            let matches = [reading.map { KanjiMatch(tier: $0, field: .reading) }, meaning.map { KanjiMatch(tier: $0, field: .meaning) }]
            return matches.compactMap { $0 }.min()
        }
    }

    /// Tier, then field, then frequency with unranked last, then list order.
    private func rankedKanji(_ matchOf: (KanjiRow) -> KanjiMatch?) -> [KanjiIndexEntry] {
        let hits = kanjiRows.compactMap { row in matchOf(row).map { KanjiHit(match: $0, entry: row.entry) } }
        let sorted = hits.sorted { lhs, rhs in
            if lhs.match != rhs.match { return lhs.match < rhs.match }
            let lhsFrequency = lhs.entry.frequencyRank ?? Int.max
            let rhsFrequency = rhs.entry.frequencyRank ?? Int.max
            if lhsFrequency != rhsFrequency { return lhsFrequency < rhsFrequency }
            return lhs.entry.listIndex < rhs.entry.listIndex
        }
        return sorted.prefix(Self.kanjiLimit).map(\.entry)
    }

    /*-------------------------------words----------------------------------*/

    private func kanjiQueryWords(_ text: String) -> [SearchWord] {
        let needle = Array(text.utf8)
        return rankedWords { SearchMatcher.tier(of: needle, in: $0.written, wordStartOnly: false) }
    }

    private func kanaQueryWords(_ text: String) -> [SearchWord] {
        let needle = Array(text.utf8)
        return rankedWords { SearchMatcher.bestTier(of: needle, in: [$0.kana, $0.written], wordStartOnly: false) }
    }

    private func latinQueryWords(romaji: String, english: String) -> [SearchWord] {
        let romajiNeedle = Array(romaji.utf8)
        let englishNeedle = Array(english.utf8)
        return rankedWords { row in
            let reading = SearchMatcher.tier(of: romajiNeedle, in: row.romaji, wordStartOnly: false)
            let meaning = SearchMatcher.bestTier(of: englishNeedle, in: row.glosses, wordStartOnly: true)
            return [reading, meaning].compactMap { $0 }.min()
        }
    }

    /// Tier, then JMdict `rank`, then shorter kana, then id so the order is total.
    private func rankedWords(_ tierOf: (WordRow) -> MatchTier?) -> [SearchWord] {
        let hits = wordRows.compactMap { row in tierOf(row).map { WordHit(tier: $0, row: row) } }
        let sorted = hits.sorted { lhs, rhs in
            if lhs.tier != rhs.tier { return lhs.tier < rhs.tier }
            if lhs.row.word.rank != rhs.row.word.rank { return lhs.row.word.rank < rhs.row.word.rank }
            if lhs.row.kana.count != rhs.row.kana.count { return lhs.row.kana.count < rhs.row.kana.count }
            return lhs.row.word.id < rhs.row.word.id
        }
        return sorted.prefix(Self.wordLimit).map(\.row.word)
    }

    /*-------------------------------folding--------------------------------*/

    private static func kanjiRow(entry: KanjiIndexEntry, record: KanjiSearchRecord) -> KanjiRow {
        let readings = record.onyomi + record.kunyomi
        return KanjiRow(
            entry: entry,
            readings: readings.map { SearchFolding.kana($0.kana) }.filter { !$0.isEmpty },
            romaji: readings.map { SearchFolding.romaji($0.romaji) }.filter { !$0.isEmpty },
            meanings: record.meanings.map(SearchFolding.english).filter { !$0.isEmpty }
        )
    }

    private static func wordRow(_ word: SearchWord) -> WordRow {
        WordRow(
            word: word,
            kana: SearchFolding.kana(word.kana),
            written: SearchFolding.kana(word.word),
            romaji: SearchFolding.romaji(word.romaji),
            glosses: word.meaning.components(separatedBy: ", ").map(SearchFolding.english).filter { !$0.isEmpty }
        )
    }
}
