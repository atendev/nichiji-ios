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

/// One line of the flattened browse list: a level header or a row of tiles.
enum KanjiBrowseRow: Identifiable, Equatable, Sendable {
    case header(KanjiBrowseSection, isCollapsed: Bool, isFirst: Bool)
    case tiles(id: String, entries: [KanjiIndexEntry])

    var id: String {
        switch self {
        case .header(let section, _, _): "header-\(section.id)"
        case .tiles(let id, _): id
        }
    }
}

/// Route pushed onto the Dictionary stack when a tile is tapped.
struct KanjiDetailRoute: Hashable, Sendable {
    let kanjiID: String
}

/*--------------------------------grouping------------------------------------*/

/// Groups the bundled index by the learner's level system so every kanji lands in exactly one section.
enum KanjiBrowseGrouping {
    /// Reads the index only; opening Dictionary never decodes full records.
    static func load(system: LevelSystem, contentStore: any KanjiContentStore) throws -> [KanjiBrowseSection] {
        sections(from: try contentStore.indexEntries(), system: system)
    }

    /// Sections in level order with kanji in list order. Empty groups are dropped.
    static func sections(from entries: [KanjiIndexEntry], system: LevelSystem) -> [KanjiBrowseSection] {
        let sorted = entries.sorted { $0.listIndex < $1.listIndex }

        let sections: [KanjiBrowseSection]
        switch system {
        case .jlpt:
            sections = JLPTLevel.allCases.map { level in
                KanjiBrowseSection(
                    id: level.rawValue,
                    title: level.badgeLabel,
                    entries: sorted.filter { level.includes($0) }
                )
            }
        case .joyo:
            sections = JoyoGrade.allCases.map { grade in
                KanjiBrowseSection(id: grade.rawValue, title: grade.displayName, entries: sorted.filter { grade.includes($0) })
            }
        }

        return sections.filter { !$0.entries.isEmpty }
    }

    /// Flat rows for one lazy list. Collapsed sections keep their header and drop their tiles.
    static func rows(from sections: [KanjiBrowseSection], collapsed: Set<String>, columnCount: Int) -> [KanjiBrowseRow] {
        var rows: [KanjiBrowseRow] = []
        for (index, section) in sections.enumerated() {
            let isCollapsed = collapsed.contains(section.id)
            rows.append(.header(section, isCollapsed: isCollapsed, isFirst: index == 0))
            guard !isCollapsed else { continue }
            for start in stride(from: 0, to: section.entries.count, by: columnCount) {
                let end = min(start + columnCount, section.entries.count)
                rows.append(.tiles(id: "\(section.id)-\(start)", entries: Array(section.entries[start..<end])))
            }
        }
        return rows
    }
}
