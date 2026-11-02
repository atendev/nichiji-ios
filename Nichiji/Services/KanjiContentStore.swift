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

    /// Counts the bundled kanji at a JLPT level without decoding their records.
    func count(for jlptLevel: JLPTLevel) throws -> Int

    /// Counts the bundled kanji in a Joyo grade without decoding their records.
    func count(for joyoGrade: JoyoGrade) throws -> Int

    /// Lazily loads ordered SVG stroke paths for a kanji literal in the main app target.
    func strokePaths(for kanjiID: String) throws -> [String]
}

/*----------------------------------store-------------------------------------*/

/// Thread-safe store over the generated `Dataset/` bundle: the index loads once, records decode on demand and stay cached.
public final class BundledKanjiContentStore: KanjiContentStore, @unchecked Sendable {
    private let bundle: Bundle
    private let lock = NSLock()
    private var cachedEntries: [String: KanjiEntry] = [:]
    private var cachedIndex: [KanjiIndexEntry]?

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func entry(for kanjiID: String) throws -> KanjiEntry {
        lock.lock()
        defer { lock.unlock() }

        return try loadEntry(kanjiID)
    }

    public func entries(for jlptLevel: JLPTLevel) throws -> [KanjiEntry] {
        lock.lock()
        defer { lock.unlock() }

        return try loadIndex()
            .filter { $0.jlptLevel == jlptLevel }
            .sorted { $0.listIndex < $1.listIndex }
            .map { try loadEntry($0.id) }
    }

    public func entries(for joyoGrade: JoyoGrade) throws -> [KanjiEntry] {
        lock.lock()
        defer { lock.unlock() }

        return try loadIndex()
            .filter { $0.joyoGrade == joyoGrade }
            .sorted { $0.listIndex < $1.listIndex }
            .map { try loadEntry($0.id) }
    }

    public func count(for jlptLevel: JLPTLevel) throws -> Int {
        lock.lock()
        defer { lock.unlock() }

        return try loadIndex().filter { $0.jlptLevel == jlptLevel }.count
    }

    public func count(for joyoGrade: JoyoGrade) throws -> Int {
        lock.lock()
        defer { lock.unlock() }

        return try loadIndex().filter { $0.joyoGrade == joyoGrade }.count
    }

    public func strokePaths(for kanjiID: String) throws -> [String] {
        guard let name = Self.resourceName(for: kanjiID),
              let url = bundle.url(forResource: name, withExtension: "svg", subdirectory: "stroke-order"),
              let svg = try? String(contentsOf: url, encoding: .utf8)
        else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        let paths = Self.pathData(in: svg)
        guard !paths.isEmpty else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        return paths
    }

    // MARK: - Private Loading

    /// Callers hold `lock`.
    private func loadEntry(_ kanjiID: String) throws -> KanjiEntry {
        if let cached = cachedEntries[kanjiID] {
            return cached
        }
        guard let name = Self.resourceName(for: kanjiID),
              let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "kanji"),
              let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(KanjiEntry.self, from: data)
        else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        cachedEntries[kanjiID] = entry
        return entry
    }

    /// Callers hold `lock`.
    private func loadIndex() throws -> [KanjiIndexEntry] {
        if let cachedIndex {
            return cachedIndex
        }
        guard let url = bundle.url(forResource: "kanji-index", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let index = try? JSONDecoder().decode(KanjiIndex.self, from: data)
        else {
            throw NichijiError.contentMissing(kanjiID: "kanji-index")
        }
        cachedIndex = index.entries
        return index.entries
    }

    /// Five-digit lowercase hex of the code point, the generator's file naming; nil unless the ID is one character.
    private static func resourceName(for kanjiID: String) -> String? {
        guard kanjiID.unicodeScalars.count == 1, let scalar = kanjiID.unicodeScalars.first else { return nil }
        return String(format: "%05x", scalar.value)
    }

    /// Extracts each `<path d="...">` in document order, which is stroke order in KanjiVG.
    static func pathData(in svg: String) -> [String] {
        var paths: [String] = []
        var remaining = svg[...]
        while let start = remaining.range(of: " d=\"") {
            let afterStart = remaining[start.upperBound...]
            guard let end = afterStart.firstIndex(of: "\"") else { break }
            paths.append(String(afterStart[..<end]))
            remaining = afterStart[end...]
        }
        return paths
    }
}
