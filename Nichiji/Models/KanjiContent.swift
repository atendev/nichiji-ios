import Foundation

/*---------------------------------enums--------------------------------------*/\n
/// JLPT level classification for a kanji entry or study pool.
public enum JLPTLevel: String, Codable, CaseIterable, Sendable {
    case n5
    case n4
    case n3
    case n2
    case n1
}

/// Joyo school grade classification for a kanji entry or study pool.
public enum JoyoGrade: String, Codable, CaseIterable, Sendable {
    case grade1
    case grade2
    case grade3
    case grade4
    case grade5
    case grade6
    case secondary
}

/// Categorizes a kanji reading as Chinese-derived or native Japanese.
public enum ReadingKind: String, Codable, Sendable {
    case onyomi
    case kunyomi
}

/*--------------------------------structs-------------------------------------*/

/// A single kana reading paired with its romaji transliteration.
public struct KanjiReading: Codable, Hashable, Sendable {
    public let kind: ReadingKind
    public let kana: String
    public let romaji: String

    public init(kind: ReadingKind, kana: String, romaji: String) {
        self.kind = kind
        self.kana = kana
        self.romaji = romaji
    }
}

/// The primary dictionary radical for a kanji entry.
public struct KanjiRadical: Codable, Hashable, Sendable {
    public let character: String
    public let meaning: String

    public init(character: String, meaning: String) {
        self.character = character
        self.meaning = meaning
    }
}

/// A vocabulary example word containing the target kanji.
public struct ExampleWord: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let word: String
    public let kana: String
    public let romaji: String
    public let meaning: String
    public let maxJLPTLevel: JLPTLevel?
    public let maxJoyoGrade: JoyoGrade?

    public init(
        id: String,
        word: String,
        kana: String,
        romaji: String,
        meaning: String,
        maxJLPTLevel: JLPTLevel? = nil,
        maxJoyoGrade: JoyoGrade? = nil
    ) {
        self.id = id
        self.word = word
        self.kana = kana
        self.romaji = romaji
        self.meaning = meaning
        self.maxJLPTLevel = maxJLPTLevel
        self.maxJoyoGrade = maxJoyoGrade
    }
}

/// An immutable bundled record describing a single kanji character.
public struct KanjiEntry: Codable, Hashable, Sendable, Identifiable {
    /// Single-character kanji literal used as the canonical identifier.
    public let id: String
    public let meanings: [String]
    public let onyomi: [KanjiReading]
    public let kunyomi: [KanjiReading]
    public let radical: KanjiRadical
    public let strokeCount: Int
    /// Ordered SVG path strings in a 109x109 KanjiVG coordinate space.
    public let strokePaths: [String]
    public let jlptLevel: JLPTLevel?
    public let joyoGrade: JoyoGrade?
    public let frequencyRank: Int?
    public let listIndex: Int
    public let exampleWords: [ExampleWord]

    public init(
        id: String,
        meanings: [String],
        onyomi: [KanjiReading],
        kunyomi: [KanjiReading],
        radical: KanjiRadical,
        strokeCount: Int,
        strokePaths: [String],
        jlptLevel: JLPTLevel?,
        joyoGrade: JoyoGrade?,
        frequencyRank: Int?,
        listIndex: Int,
        exampleWords: [ExampleWord]
    ) {
        self.id = id
        self.meanings = meanings
        self.onyomi = onyomi
        self.kunyomi = kunyomi
        self.radical = radical
        self.strokeCount = strokeCount
        self.strokePaths = strokePaths
        self.jlptLevel = jlptLevel
        self.joyoGrade = joyoGrade
        self.frequencyRank = frequencyRank
        self.listIndex = listIndex
        self.exampleWords = exampleWords
    }
}

/// Lightweight summary record contained in the bundled kanji index.
public struct KanjiIndexEntry: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let primaryMeaning: String
    public let primaryReading: String
    public let strokeCount: Int
    public let jlptLevel: JLPTLevel?
    public let joyoGrade: JoyoGrade?
    public let listIndex: Int

    public init(
        id: String,
        primaryMeaning: String,
        primaryReading: String,
        strokeCount: Int,
        jlptLevel: JLPTLevel?,
        joyoGrade: JoyoGrade?,
        listIndex: Int
    ) {
        self.id = id
        self.primaryMeaning = primaryMeaning
        self.primaryReading = primaryReading
        self.strokeCount = strokeCount
        self.jlptLevel = jlptLevel
        self.joyoGrade = joyoGrade
        self.listIndex = listIndex
    }
}
