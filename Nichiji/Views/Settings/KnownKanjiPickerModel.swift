import Foundation

/*--------------------------------model---------------------------------------*/

/// Selection state behind the Known kanji picker. It starts from every kanji the learner already marked, so groups
/// that are not on screen are never undeclared when the learner is done.
struct KnownKanjiPickerModel: Equatable {
    private(set) var sections: [KanjiBrowseSection]
    private(set) var selected: Set<String>
    var committed: Set<String>
    /// Kanji already past new through Today or Review. They cannot be marked.
    private let studied: Set<String>

    init(sections: [KanjiBrowseSection], declared: Set<String>, studied: Set<String>) {
        self.sections = sections
        self.selected = declared
        self.committed = declared
        self.studied = studied.subtracting(declared)
    }

    /*------------------------------selection-------------------------------*/

    func isEnabled(_ kanjiID: String) -> Bool {
        !studied.contains(kanjiID)
    }

    func isSelected(_ kanjiID: String) -> Bool {
        selected.contains(kanjiID)
    }

    /// Everything marked, including kanji outside the groups on screen and ones picked from search results.
    var selectedCount: Int { selected.count }

    mutating func toggle(_ kanjiID: String) {
        guard isEnabled(kanjiID) else { return }
        if selected.contains(kanjiID) {
            selected.remove(kanjiID)
        } else {
            selected.insert(kanjiID)
        }
    }

    /*-------------------------------groups---------------------------------*/

    private func enabledIDs(in section: KanjiBrowseSection) -> [String] {
        section.entries.map(\.id).filter(isEnabled)
    }

    /// A group with nothing to mark hides its Select all button.
    func showsGroupButton(for section: KanjiBrowseSection) -> Bool {
        !enabledIDs(in: section).isEmpty
    }

    func isAllSelected(in section: KanjiBrowseSection) -> Bool {
        let enabled = enabledIDs(in: section)
        return !enabled.isEmpty && enabled.allSatisfy(selected.contains)
    }

    func selectedCount(in section: KanjiBrowseSection) -> Int {
        enabledIDs(in: section).filter(selected.contains).count
    }

    mutating func setAll(in section: KanjiBrowseSection, selected isOn: Bool) {
        for id in enabledIDs(in: section) {
            if isOn {
                selected.insert(id)
            } else {
                selected.remove(id)
            }
        }
    }

    /*-------------------------------commit---------------------------------*/

    /// The difference between what is marked now and what the store already holds.
    var pendingChanges: (declare: Set<String>, undeclare: Set<String>) {
        (declare: selected.subtracting(committed), undeclare: committed.subtracting(selected))
    }

    /// Called before the write starts, so a second commit sees no difference.
    mutating func markCommitted() {
        committed = selected
    }

    /*-------------------------------search---------------------------------*/

    /// Typed kanji show exactly those kanji, with no cap. Anything else searches readings and meanings across every level.
    static func results(for query: String, in index: DictionarySearchIndex) -> [KanjiIndexEntry] {
        let typed = index.kanjiTiles(in: query)
        return typed.isEmpty ? index.search(query).kanji : typed
    }

    /// Where a search result sits in the learner's level system, so out-of-level kanji are clear.
    static func levelLabel(for entry: KanjiIndexEntry, system: LevelSystem) -> String {
        switch system {
        case .jlpt: entry.jlptLevel?.codeLabel ?? "No level"
        case .joyo: entry.joyoGrade?.codeLabel ?? KanjiBrowseGrouping.nameKanjiTitle
        }
    }
}

/*------------------------------scope-----------------------------------------*/

/// Which groups the picker lists before the learner types anything: the learner's level and every easier one.
enum KnownKanjiScope {
    /// A custom pool has no level of its own, so it lists every group. "Other kanji" and name kanji are never easier.
    static func sections(
        from all: [KanjiBrowseSection],
        preferences: LearnerPreferencesSnapshot
    ) -> [KanjiBrowseSection] {
        guard !preferences.isCustomPoolActive else { return all }
        let ids: [String]
        switch preferences.levelSystem {
        case .jlpt:
            ids = throughLevel(preferences.selectedJLPTLevel).map(\.rawValue)
        case .joyo:
            ids = throughLevel(preferences.selectedJoyoGrade).map(\.rawValue)
        }
        return all.filter { ids.contains($0.id) }
    }

    /// Both level enums list their cases easiest first.
    private static func throughLevel<Level: CaseIterable & Equatable>(_ level: Level) -> [Level] {
        let levels = Array(Level.allCases)
        guard let index = levels.firstIndex(of: level) else { return levels }
        return Array(levels[...index])
    }
}
