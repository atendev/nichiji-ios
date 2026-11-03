import Foundation

/*--------------------------------records-------------------------------------*/

/// Sendable copy of a `StudyLogEntry` row, with the stored day kept as written.
public struct StudyLogRecord: Equatable, Sendable {
    public let kanjiID: String
    public let action: StudyAction
    public let timestamp: Date
    /// Stored day key; older Forget it rows may hold an empty string.
    public let calendarDay: String

    public init(kanjiID: String, action: StudyAction, timestamp: Date, calendarDay: String) {
        self.kanjiID = kanjiID
        self.action = action
        self.timestamp = timestamp
        self.calendarDay = calendarDay
    }

    /// The day this entry counts under. Every stat reads this, never `calendarDay` directly.
    public func day(using dayProvider: any DayProvider) -> String {
        calendarDay.isEmpty ? dayProvider.calendarDay(for: timestamp) : calendarDay
    }
}

extension StudyLogEntry {
    var record: StudyLogRecord {
        StudyLogRecord(kanjiID: kanjiID, action: action, timestamp: timestamp, calendarDay: calendarDay)
    }
}

/*-------------------------------study-day------------------------------------*/

/// The one study-day rule shared by streaks, the activity grid and the Review tab's This week dots.
public enum StudyDay {
    /// Learned and review answers make a study day; Forget it does not.
    public static func counts(_ action: StudyAction) -> Bool {
        switch action {
        case .learnedDaily, .gotItReview, .forgotItReview: true
        case .resetToNew: false
        }
    }

    public static func days(in log: [StudyLogRecord], dayProvider: any DayProvider) -> Set<String> {
        Set(log.filter { counts($0.action) }.map { $0.day(using: dayProvider) })
    }
}

/*--------------------------------levels--------------------------------------*/

/// A selectable study level. Name kanji is a browse group only, so it has no case here.
public enum StudyLevel: Hashable, Sendable {
    case jlpt(JLPTLevel)
    case joyo(JoyoGrade)

    /// Milestone title for finishing this level ("Finish N5", "Finish Grade 1").
    public var finishLabel: String {
        switch self {
        case .jlpt(let level): "Finish \(level.codeLabel)"
        case .joyo(.secondary): "Finish Secondary"
        case .joyo(let grade): "Finish Grade \(grade.codeLabel)"
        }
    }

    func contains(_ entry: KanjiIndexEntry) -> Bool {
        switch self {
        case .jlpt(let level): entry.jlptLevel == level
        case .joyo(let grade): entry.joyoGrade == grade
        }
    }
}

/// Order of study levels for the level-complete "Start <next level>" button.
public enum LevelSequence {
    /// The active level, or nil for a custom pool.
    public static func current(preferences: LearnerPreferencesSnapshot) -> StudyLevel? {
        guard !preferences.isCustomPoolActive else { return nil }
        return switch preferences.levelSystem {
        case .jlpt: .jlpt(preferences.selectedJLPTLevel)
        case .joyo: .joyo(preferences.selectedJoyoGrade)
        }
    }

    /// The level after the given one, or nil after N1, after Secondary, or for a custom pool.
    public static func next(after level: StudyLevel?) -> StudyLevel? {
        switch level {
        case .jlpt(let current):
            successor(of: current, in: JLPTLevel.allCases).map(StudyLevel.jlpt)
        case .joyo(let current):
            successor(of: current, in: JoyoGrade.allCases).map(StudyLevel.joyo)
        case nil:
            nil
        }
    }

    /// The level a system starts on; the level milestone targets it.
    static func first(in system: LevelSystem) -> StudyLevel {
        switch system {
        case .jlpt: .jlpt(.n5)
        case .joyo: .joyo(.grade1)
        }
    }

    private static func successor<T: Equatable>(of value: T, in cases: [T]) -> T? {
        guard let index = cases.firstIndex(of: value), index + 1 < cases.count else { return nil }
        return cases[index + 1]
    }
}
