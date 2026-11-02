import Foundation

/*--------------------------------structs-------------------------------------*/

/// One level group in the Dictionary browse grid.
struct KanjiBrowseSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let entries: [KanjiIndexEntry]

    var countLabel: String {
        entries.count == 1 ? "1 kanji" : "\(entries.count) kanji"
    }
}

/// Route pushed onto the Dictionary stack when a tile is tapped.
struct KanjiDetailRoute: Hashable, Sendable {
    let kanjiID: String
}

/*--------------------------------grouping------------------------------------*/

/// Groups the bundled index by the learner's level system so every kanji lands in exactly one section.
enum KanjiBrowseGrouping {
    static let unleveledTitle = "Other kanji"
    /// Jinmeiyō kanji have no Jōyō grade, so Jōyō browse gives them their own group.
    static let nameKanjiTitle = "Name kanji"

    /// Reads the index only; opening Dictionary never decodes full records.
    static func load(system: LevelSystem, contentStore: any KanjiContentStore) throws -> [KanjiBrowseSection] {
        sections(from: try contentStore.indexEntries(), system: system)
    }

    /// Sections in level order with kanji in list order. Empty groups are dropped.
    static func sections(from entries: [KanjiIndexEntry], system: LevelSystem) -> [KanjiBrowseSection] {
        let sorted = entries.sorted { $0.listIndex < $1.listIndex }
        var sections: [KanjiBrowseSection]

        switch system {
        case .jlpt:
            sections = JLPTLevel.allCases.map { level in
                KanjiBrowseSection(id: level.rawValue, title: level.codeLabel, entries: sorted.filter { $0.jlptLevel == level })
            }
            sections.append(KanjiBrowseSection(id: "unleveled", title: unleveledTitle, entries: sorted.filter { $0.jlptLevel == nil }))
        case .joyo:
            sections = JoyoGrade.allCases.map { grade in
                KanjiBrowseSection(id: grade.rawValue, title: grade.displayName, entries: sorted.filter { $0.joyoGrade == grade })
            }
            sections.append(KanjiBrowseSection(id: "name-kanji", title: nameKanjiTitle, entries: sorted.filter { $0.joyoGrade == nil }))
        }

        return sections.filter { !$0.entries.isEmpty }
    }
}
