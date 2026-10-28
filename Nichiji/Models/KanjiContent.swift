import Foundation

/*---------------------------------enums--------------------------------------*/

/// JLPT level classification for a kanji entry or study pool.
enum JLPTLevel: String, Codable, CaseIterable, Sendable {
    case n5
    case n4
    case n3
    case n2
    case n1
}

/// Joyo school grade classification for a kanji entry or study pool.
enum JoyoGrade: String, Codable, CaseIterable, Sendable {
    case grade1
    case grade2
    case grade3
    case grade4
    case grade5
    case grade6
    case secondary
}

/// Categorizes a kanji reading as Chinese-derived or native Japanese.
enum ReadingKind: String, Codable, Sendable {
    case onyomi
    case kunyomi
}

/*--------------------------------structs-------------------------------------*/

/// A single kana reading paired with its romaji transliteration.
struct KanjiReading: Codable, Hashable, Sendable {
    let kind: ReadingKind
    let kana: String
    let romaji: String
}

/// The primary dictionary radical for a kanji entry.
struct KanjiRadical: Codable, Hashable, Sendable {
    let character: String
    let meaning: String
}

/// A vocabulary example word containing the target kanji.
struct ExampleWord: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let word: String
    let kana: String
    let romaji: String
    let meaning: String
    let maxJLPTLevel: JLPTLevel?
    let maxJoyoGrade: JoyoGrade?
}

/// An immutable bundled record describing a single kanji character.
struct KanjiEntry: Codable, Hashable, Sendable, Identifiable {
    /// Single-character kanji literal used as the canonical identifier.
    let id: String
    let meanings: [String]
    let onyomi: [KanjiReading]
    let kunyomi: [KanjiReading]
    let radical: KanjiRadical
    let strokeCount: Int
    /// Ordered SVG path strings in a 109x109 KanjiVG coordinate space.
    let strokePaths: [String]
    let jlptLevel: JLPTLevel?
    let joyoGrade: JoyoGrade?
    let frequencyRank: Int?
    let listIndex: Int
    let exampleWords: [ExampleWord]
}
