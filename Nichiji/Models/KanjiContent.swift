import Foundation

/*---------------------------------enums--------------------------------------*/
/// JLPT level classification for a kanji entry or study pool.
public enum JLPTLevel: String, Codable, CaseIterable, Sendable {
    case n5
    case n4
    case n3
    case n2
    case n1
    case jinmeiyo
    case hyogai
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
    case jinmeiyo
    case hyogai
}

/// Which official list a kanji belongs to: the Joyo school set, the jinmeiyo name kanji, or hyogai (neither).
public enum KanjiClassification: String, Codable, CaseIterable, Sendable {
    case joyo
    case jinmeiyo
    case hyogai

    /// The classification of a hand-built record: a Joyo grade means Joyo, none means jinmeiyo (the old "name kanji").
    static func inferred(joyoGrade: JoyoGrade?) -> KanjiClassification {
        joyoGrade == nil ? .jinmeiyo : .joyo
    }
}

/// The fields a level rung reads to decide whether a kanji belongs to it; shared by full and index records.
public protocol LevelMember {
    var classification: KanjiClassification { get }
    var jlptLevel: JLPTLevel? { get }
    var joyoGrade: JoyoGrade? { get }
}

public extension JLPTLevel {
    /// True for the two rungs past N1, which hold name kanji and kanji beyond the lists.
    var isListStep: Bool {
        self == .jinmeiyo || self == .hyogai
    }

    /// Whether the kanji sits on this rung. Jinmeiyo and Hyogai hold only kanji with no N-level, so every kanji has one rung.
    func includes(_ kanji: some LevelMember) -> Bool {
        switch self {
        case .jinmeiyo: kanji.classification == .jinmeiyo && kanji.jlptLevel == nil
        case .hyogai: kanji.classification == .hyogai && kanji.jlptLevel == nil
        case .n5, .n4, .n3, .n2, .n1: kanji.jlptLevel == self
        }
    }
}

public extension JoyoGrade {
    /// True for the two rungs past secondary school.
    var isListStep: Bool {
        self == .jinmeiyo || self == .hyogai
    }

    /// Whether the kanji sits on this rung. Jinmeiyo holds all 806 name kanji, Hyogai all kanji beyond the lists.
    func includes(_ kanji: some LevelMember) -> Bool {
        switch self {
        case .jinmeiyo: kanji.classification == .jinmeiyo
        case .hyogai: kanji.classification == .hyogai
        case .grade1, .grade2, .grade3, .grade4, .grade5, .grade6, .secondary: kanji.joyoGrade == self
        }
    }
}

public extension KanjiClassification {
    /// Label for the Details card List row.
    var listLabel: String {
        switch self {
        case .joyo: "Jōyō"
        case .jinmeiyo: "Jinmeiyō"
        case .hyogai: "Hyōgai"
        }
    }
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

    public init(
        id: String,
        word: String,
        kana: String,
        romaji: String,
        meaning: String
    ) {
        self.id = id
        self.word = word
        self.kana = kana
        self.romaji = romaji
        self.meaning = meaning
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
    public let classification: KanjiClassification
    /// Unofficial community level; see `isJLPTLevelEstimated`.
    public let jlptLevel: JLPTLevel?
    /// True when the level comes from the OpenJLPT supplement instead of Waller's lists.
    public let isJLPTLevelEstimated: Bool
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
        jlptLevel: JLPTLevel?,
        joyoGrade: JoyoGrade?,
        frequencyRank: Int?,
        listIndex: Int,
        exampleWords: [ExampleWord],
        isJLPTLevelEstimated: Bool = false,
        classification: KanjiClassification? = nil
    ) {
        self.id = id
        self.meanings = meanings
        self.onyomi = onyomi
        self.kunyomi = kunyomi
        self.radical = radical
        self.strokeCount = strokeCount
        self.classification = classification ?? .inferred(joyoGrade: joyoGrade)
        self.jlptLevel = jlptLevel
        self.isJLPTLevelEstimated = isJLPTLevelEstimated
        self.joyoGrade = joyoGrade
        self.frequencyRank = frequencyRank
        self.listIndex = listIndex
        self.exampleWords = exampleWords
    }
}

extension KanjiEntry: LevelMember {}

/// Lightweight summary record contained in the bundled kanji index.
public struct KanjiIndexEntry: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let primaryMeaning: String
    public let primaryReading: String
    public let strokeCount: Int
    public let classification: KanjiClassification
    public let jlptLevel: JLPTLevel?
    public let joyoGrade: JoyoGrade?
    public let frequencyRank: Int?
    public let listIndex: Int

    public init(
        id: String,
        primaryMeaning: String,
        primaryReading: String,
        strokeCount: Int,
        jlptLevel: JLPTLevel?,
        joyoGrade: JoyoGrade?,
        listIndex: Int,
        frequencyRank: Int? = nil,
        classification: KanjiClassification? = nil
    ) {
        self.id = id
        self.primaryMeaning = primaryMeaning
        self.primaryReading = primaryReading
        self.strokeCount = strokeCount
        self.classification = classification ?? .inferred(joyoGrade: joyoGrade)
        self.jlptLevel = jlptLevel
        self.joyoGrade = joyoGrade
        self.frequencyRank = frequencyRank
        self.listIndex = listIndex
    }
}

extension KanjiIndexEntry: LevelMember {}

/// Top-level shape of the generated `kanji-index.json`.
public struct KanjiIndex: Codable, Sendable {
    public let formatVersion: Int
    public let entries: [KanjiIndexEntry]
}
