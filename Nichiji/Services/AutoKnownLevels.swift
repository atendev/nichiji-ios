import Foundation

/*------------------------------auto-known--------------------------------*/

/// The kanji a level pick marks known on its own: every kanji in the levels easier than the learner's.
enum AutoKnownLevels {
    /// Nil with the custom pool, which has no level, so the automatic marks stay as they are.
    static func kanjiIDs(in index: [KanjiIndexEntry], preferences: LearnerPreferencesSnapshot) -> Set<String>? {
        guard !preferences.isCustomPoolActive else { return nil }
        switch preferences.levelSystem {
        case .jlpt:
            let easier = Set(JLPTLevel.allCases.prefix { $0 != preferences.selectedJLPTLevel })
            return Set(index.filter { $0.jlptLevel.map(easier.contains) ?? false }.map(\.id))
        case .joyo:
            let easier = Set(JoyoGrade.allCases.prefix { $0 != preferences.selectedJoyoGrade })
            return Set(index.filter { $0.joyoGrade.map(easier.contains) ?? false }.map(\.id))
        }
    }

    /// False at the easiest level and with the custom pool, where a level pick marks nothing.
    static func hasEasierLevels(_ preferences: LearnerPreferencesSnapshot) -> Bool {
        guard !preferences.isCustomPoolActive else { return false }
        switch preferences.levelSystem {
        case .jlpt: return preferences.selectedJLPTLevel != JLPTLevel.allCases.first
        case .joyo: return preferences.selectedJoyoGrade != JoyoGrade.allCases.first
        }
    }
}
