import Foundation

/*-------------------------------protocols------------------------------------*/

/// Read-only access to bundled kanji records and lazily loaded stroke paths.
protocol KanjiContentStore: Sendable {
    /// Loads the bundled kanji entry for a single-character kanji literal.
    // TODO: Decode and cache kanji/<hex-codepoint>.json from the active bundle, throwing NichijiError.contentMissing if absent.
    func entry(for kanjiID: String) throws -> KanjiEntry

    /// Loads all bundled kanji entries matching a JLPT level in canonical list order.
    // TODO: Filter the decoded bundle index by jlptLevel and return entries sorted by listIndex.
    func entries(for jlptLevel: JLPTLevel) throws -> [KanjiEntry]

    /// Loads all bundled kanji entries matching a Joyo grade in canonical list order.
    // TODO: Filter the decoded bundle index by joyoGrade and return entries sorted by listIndex.
    func entries(for joyoGrade: JoyoGrade) throws -> [KanjiEntry]

    /// Lazily loads ordered SVG stroke paths for a kanji literal in the main app target.
    // TODO: Parse stroke-order/<hex-codepoint>.svg on demand and throw NichijiError.contentMissing when the glyph resource is absent.
    func strokePaths(for kanjiID: String) throws -> [String]
}
