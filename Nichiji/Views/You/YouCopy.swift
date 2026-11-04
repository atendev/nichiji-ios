import Foundation

/*--------------------------------rows------------------------------------*/

/// A value over its label, used by the stat tiles and the level-complete figures.
struct StatTile: Equatable, Sendable {
    let value: String
    let label: String
}

struct FreezeRowCopy: Equatable, Sendable {
    let title: String
    let note: String
    let isReady: Bool
}

struct LevelBarRow: Equatable, Sendable {
    let id: String
    /// Nil for Name kanji, which has no short code.
    let code: String?
    let name: String
    let count: String
    let fraction: Double
}

struct MilestoneRow: Equatable, Sendable {
    let title: String
    let note: String
    let isEarned: Bool
    let progress: Double
}

/*--------------------------------copy------------------------------------*/

/// Every string and fraction the You tab shows, kept apart from the views so it can be tested.
enum YouCopy {
    static let needsAttentionEmpty = "Nothing yet. Kanji you forget often show up here."
    static let learnedEmpty = "Kanji you learn show up here."
    static let historyEmpty = "Nothing yet. Your study history shows up here."
    static let exportFailed = "Could not prepare the export."

    private static let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    /*------------------------------header--------------------------------*/

    static func learningSince(_ month: YearMonth?) -> String? {
        guard let month, months.indices.contains(month.month - 1) else { return nil }
        return "LEARNING SINCE \(months[month.month - 1]) \(month.year)"
    }

    /// The Review tab's header subtitle, hidden with no streak.
    static func streakSubtitle(_ current: Int) -> String? {
        current > 0 ? "\(current) DAY STREAK" : nil
    }

    /*-------------------------------tiles--------------------------------*/

    static func tiles(_ stats: LearnerStats) -> [StatTile] {
        [
            StatTile(value: "\(stats.streak.current)", label: "Day streak"),
            StatTile(value: "\(stats.streak.longest)", label: "Longest streak"),
            StatTile(value: "\(stats.kanjiLearned)", label: "Kanji learned"),
            StatTile(value: "\(stats.reviewsDone)", label: "Reviews done"),
            StatTile(value: rate(stats.gotItRate), label: "Got it rate"),
            StatTile(value: "\(stats.daysStudied)", label: "Days studied")
        ]
    }

    static func rate(_ percent: Int?) -> String {
        percent.map { "\($0)%" } ?? "–"
    }

    static func freezeRow(_ state: StreakFreezeState?) -> FreezeRowCopy? {
        switch state {
        case .ready:
            FreezeRowCopy(title: "Streak freeze ready", note: "Miss one day this week and keep your streak.", isReady: true)
        case .usedThisWeek:
            FreezeRowCopy(title: "Streak freeze used this week", note: "It refills when the next week starts.", isReady: false)
        case nil:
            nil
        }
    }

    /*------------------------------activity------------------------------*/

    /// Counts only days up to today, since the rest of this week is blank.
    static func activitySummary(_ weeks: [[ActivityCell]]) -> String {
        let days = weeks.flatMap { $0 }.filter { $0.shade != nil }
        let studied = days.filter { $0.count > 0 }.count
        return "Study activity for the last 12 weeks. Studied on \(studied) of \(days.count) days."
    }

    /*------------------------------by-level------------------------------*/

    static func levelRow(_ bar: LevelBar) -> LevelBarRow {
        let count = "\(bar.learned) of \(bar.total)"
        let fraction = barFraction(learned: bar.learned, total: bar.total)
        if let level = JLPTLevel(rawValue: bar.id) {
            return LevelBarRow(id: bar.id, code: level.codeLabel, name: level.displayName, count: count, fraction: fraction)
        }
        if let grade = JoyoGrade(rawValue: bar.id) {
            return LevelBarRow(id: bar.id, code: grade.codeLabel, name: grade.displayName, count: count, fraction: fraction)
        }
        return LevelBarRow(id: bar.id, code: nil, name: bar.title, count: count, fraction: fraction)
    }

    /// Any progress shows at least a sliver of bar.
    static func barFraction(learned: Int, total: Int) -> Double {
        guard total > 0, learned > 0 else { return 0 }
        return min(max(Double(learned) / Double(total), 0.02), 1)
    }

    /*-----------------------------milestones-----------------------------*/

    static func milestoneTitle(_ kind: MilestoneKind) -> String {
        switch kind {
        case .firstKanji: "First kanji"
        case .tenKanji: "10 kanji learned"
        case .twentyFiveKanji: "25 kanji learned"
        case .hundredReviews: "100 reviews"
        case .sevenDayStreak: "7-day streak"
        case .thirtyDayStreak: "30-day streak"
        case .finishLevel(let level): level.finishLabel
        }
    }

    static func milestoneRow(_ milestone: Milestone) -> MilestoneRow {
        MilestoneRow(
            title: milestoneTitle(milestone.kind),
            note: milestone.isEarned ? "Earned" : "\(milestone.current) / \(milestone.target)",
            isEarned: milestone.isEarned,
            progress: milestone.progress
        )
    }

    static func milestoneCount(_ milestones: [Milestone]) -> String {
        "\(milestones.filter(\.isEarned).count) of \(milestones.count)"
    }

    /*--------------------------needs-attention---------------------------*/

    static func forgotNote(_ count: Int) -> String {
        count == 1 ? "Forgot 1 time" : "Forgot \(count) times"
    }

    /// The empty message, or nil when there are tiles to show.
    static func needsAttentionMessage(_ items: [NeedsAttentionItem]) -> String? {
        items.isEmpty ? needsAttentionEmpty : nil
    }

    /*-----------------------------your-kanji-----------------------------*/

    static func learnedCount(_ count: Int) -> String {
        "\(count) learned"
    }

    static func learnedMessage(_ kanjiIDs: [String]) -> String? {
        kanjiIDs.isEmpty ? learnedEmpty : nil
    }

    static func historyMessage(_ days: [HistoryDay]) -> String? {
        days.isEmpty ? historyEmpty : nil
    }

    static func historyAction(_ action: StudyAction) -> String {
        switch action {
        case .learnedDaily: "Learned"
        case .gotItReview: "Reviewed, got it"
        case .forgotItReview: "Reviewed, forgot"
        case .resetToNew: "Reset to new"
        }
    }

    /// "8:02 am" in the calendar's time zone.
    static func historyTime(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, parts.minute ?? 0, hour >= 12 ? "pm" : "am")
    }

    /// Sharing needs a prepared file and at least one log entry.
    static func canExport(logIsEmpty: Bool, fileURL: URL?) -> Bool {
        !logIsEmpty && fileURL != nil
    }
}
