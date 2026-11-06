import Foundation

/*---------------------------------enums--------------------------------------*/

/// State of the You tab's freeze row when the streak freeze setting is on.
public enum StreakFreezeState: Equatable, Sendable {
    case ready
    case usedThisWeek
}

/// The seven lifetime milestones, in display order.
public enum MilestoneKind: Equatable, Sendable {
    case firstKanji
    case tenKanji
    case twentyFiveKanji
    case hundredReviews
    case sevenDayStreak
    case thirtyDayStreak
    case finishLevel(StudyLevel)
}

/*--------------------------------structs-------------------------------------*/

/// A calendar year and month, for the "Learning since" header.
public struct YearMonth: Equatable, Sendable {
    public let year: Int
    public let month: Int
}

/// Day streak figures recomputed from the whole log.
public struct StreakSummary: Equatable, Sendable {
    public let current: Int
    public let longest: Int
    /// Nil when the streak freeze setting is off.
    public let freeze: StreakFreezeState?
}

/// One day in the activity grid.
public struct ActivityCell: Equatable, Sendable {
    public let calendarDay: String
    /// Learned plus review answers on the day.
    public let count: Int
    /// Shade bucket 0 to 4, or nil for days after today, which stay blank.
    public let shade: Int?
}

/// One bar in By level: learned kanji out of the group's total.
public struct LevelBar: Equatable, Sendable {
    public let id: String
    public let title: String
    public let learned: Int
    public let total: Int
}

/// A milestone with its progress toward the target. Earned stays earned because every measure only grows.
public struct Milestone: Equatable, Sendable {
    public let kind: MilestoneKind
    public let current: Int
    public let target: Int

    public var isEarned: Bool { target > 0 && current >= target }

    /// Fraction for a locked milestone's progress bar, capped at 1.
    public var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1)
    }
}

/// A kanji in Needs attention with its Forgot it count.
public struct NeedsAttentionItem: Equatable, Sendable {
    public let kanjiID: String
    public let forgotCount: Int
}

/// Every number the You tab shows, except history and the level-complete figures, which load separately.
public struct LearnerStats: Equatable, Sendable {
    public let streak: StreakSummary
    /// The freeze row: nil when the setting is off.
    public let streakFreeze: StreakFreezeState?
    public let kanjiLearned: Int
    public let reviewsDone: Int
    /// Whole percent, or nil before the first review answer.
    public let gotItRate: Int?
    public let daysStudied: Int
    public let learningSince: YearMonth?
    /// 12 weeks, oldest first, each 7 days in locale weekday order.
    public let activity: [[ActivityCell]]
    public let levelBars: [LevelBar]
    public let milestones: [Milestone]
    public let needsAttention: [NeedsAttentionItem]
    /// Learned kanji, newest first.
    public let learnedKanjiIDs: [String]
    /// Kanji the learner marked as already known, counted apart from Learned.
    public var kanjiKnown: Int = 0
}

/// One day of history: entries in the order they happened.
public struct HistoryDay: Equatable, Sendable {
    public let calendarDay: String
    /// "TODAY", "YESTERDAY", "MON, OCT 26" or "SUN, OCT 26, 2025".
    public let heading: String
    public let entries: [StudyLogRecord]
}

/// Figures for the level-complete screen.
public struct LevelCompleteFigures: Equatable, Sendable {
    public let kanjiLearned: Int
    /// Inclusive days from the first to the last learned kanji in the level; nil when none.
    public let daysTaken: Int?
    /// Whole percent over the level's kanji, or nil with no review answers.
    public let gotItRate: Int?
}

/// A ready-to-share history CSV.
public struct HistoryExport: Equatable, Sendable {
    public let fileName: String
    public let data: Data
}
