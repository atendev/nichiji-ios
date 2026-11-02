import Foundation

/*--------------------------------records-------------------------------------*/

/// A common JMdict word from the app-only `words.json`.
public struct SearchWord: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let word: String
    public let kana: String
    public let romaji: String
    public let meaning: String
    /// Lower is more common, from the JMdict `nf` band and priority tags.
    public let rank: Int

    public init(id: String, word: String, kana: String, romaji: String, meaning: String, rank: Int) {
        self.id = id
        self.word = word
        self.kana = kana
        self.romaji = romaji
        self.meaning = meaning
        self.rank = rank
    }
}

/// One kanji's full readings and meanings from the app-only `kanji-search.json`.
public struct KanjiSearchRecord: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let meanings: [String]
    public let onyomi: [KanjiReading]
    public let kunyomi: [KanjiReading]

    public init(id: String, meanings: [String], onyomi: [KanjiReading], kunyomi: [KanjiReading]) {
        self.id = id
        self.meanings = meanings
        self.onyomi = onyomi
        self.kunyomi = kunyomi
    }
}

/*--------------------------------results-------------------------------------*/

/// What tapping a word row does.
enum WordTapAction: Equatable, Sendable {
    /// The word has no kanji in the dataset.
    case unavailable
    /// One distinct kanji, so detail opens directly.
    case openKanji(String)
    /// Two or more distinct kanji, so the "Which kanji?" sheet opens.
    case chooseKanji
}

/// A word hit with the distinct dataset kanji it contains, in written order.
struct WordResult: Equatable, Identifiable, Sendable {
    let word: SearchWord
    let kanji: [KanjiIndexEntry]

    var id: String { word.id }

    var tapAction: WordTapAction {
        switch kanji.count {
        case 0: return .unavailable
        case 1: return .openKanji(kanji[0].id)
        default: return .chooseKanji
        }
    }
}

/// Ranked, capped hits for one query. `query` is the trimmed text as typed.
struct DictionarySearchResults: Equatable, Sendable {
    let query: String
    let kanji: [KanjiIndexEntry]
    let words: [WordResult]

    var isEmpty: Bool { kanji.isEmpty && words.isEmpty }
}

/*---------------------------------match--------------------------------------*/

/// How a query lines up with a field, best first.
enum MatchTier: Int, Comparable, Sendable {
    case exact
    case prefix
    case substring

    static func < (lhs: MatchTier, rhs: MatchTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// The field a kanji matched on, best first. Literal matches are handled by the kanji-in-query path.
enum KanjiMatchField: Int, Comparable, Sendable {
    case reading
    case meaning

    static func < (lhs: KanjiMatchField, rhs: KanjiMatchField) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct KanjiMatch: Comparable, Sendable {
    let tier: MatchTier
    let field: KanjiMatchField

    static func < (lhs: KanjiMatch, rhs: KanjiMatch) -> Bool {
        (lhs.tier, lhs.field) < (rhs.tier, rhs.field)
    }
}

/*---------------------------------query--------------------------------------*/

/// The query read by script: kanji first, then kana, then Latin. No toggle, no romaji-to-kana conversion.
enum DictionaryQuery: Equatable, Sendable {
    /// `text` is kana-folded with whitespace removed; `literals` are the distinct kanji in typed order.
    case kanji(text: String, literals: [String])
    /// Hiragana-folded kana with any Latin letters dropped.
    case kana(String)
    case latin(romaji: String, english: String)

    /// Kana and kanji search from one character, Latin from two.
    static let minimumLatinLetters = 2

    /// Nil when the text is empty or too short to search, in which case the browse grid stays up.
    static func parse(_ raw: String) -> DictionaryQuery? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.unicodeScalars.contains(where: SearchFolding.isKanji) {
            return kanjiQuery(trimmed)
        }
        if trimmed.unicodeScalars.contains(where: SearchFolding.isKana) {
            return kanaQuery(trimmed)
        }
        return latinQuery(trimmed)
    }

    private static func kanjiQuery(_ trimmed: String) -> DictionaryQuery {
        var seen = Set<String>()
        var literals: [String] = []
        for scalar in trimmed.unicodeScalars where SearchFolding.isKanji(scalar) {
            let literal = String(scalar)
            if seen.insert(literal).inserted {
                literals.append(literal)
            }
        }
        return .kanji(text: SearchFolding.kana(trimmed), literals: literals)
    }

    private static func kanaQuery(_ trimmed: String) -> DictionaryQuery? {
        let withoutLatin = String(trimmed.unicodeScalars.filter { !SearchFolding.isLatinLetter($0) })
        let folded = SearchFolding.kana(withoutLatin)
        return folded.isEmpty ? nil : .kana(folded)
    }

    private static func latinQuery(_ trimmed: String) -> DictionaryQuery? {
        let letterCount = trimmed.unicodeScalars.filter { SearchFolding.isLatinLetter($0) }.count
        guard letterCount >= minimumLatinLetters else { return nil }
        let romaji = SearchFolding.romaji(trimmed)
        let english = SearchFolding.english(trimmed)
        guard !romaji.isEmpty, !english.isEmpty else { return nil }
        return .latin(romaji: romaji, english: english)
    }
}
