import Foundation

/*---------------------------------enums--------------------------------------*/

/// Coming up rows on the Review home, by days from today to a kanji's due day.
enum ReviewComingUpBucket: CaseIterable, Sendable {
    case tomorrow
    case inThreeDays
    case nextWeek

    var title: String {
        switch self {
        case .tomorrow: "Tomorrow"
        case .inThreeDays: "In 2 to 3 days"
        case .nextWeek: "Next week"
        }
    }

    /// Bucket for a kanji due the given number of days from today, or nil outside the next week.
    static func bucket(forDaysAhead days: Int) -> ReviewComingUpBucket? {
        switch days {
        case 1: .tomorrow
        case 2...3: .inThreeDays
        case 4...7: .nextWeek
        default: nil
        }
    }
}

/*--------------------------------structs-------------------------------------*/

/// One dot in the This week row.
struct ReviewWeekDay: Equatable, Sendable {
    let label: String
    let calendarDay: String
    let isReviewed: Bool
    let isToday: Bool
}

/// Everything the Review home shows, computed from progress rows and the study log.
struct ReviewHomeSummary: Equatable, Sendable {
    static let maxTiles = 6
    static let secondsPerCard = 20

    /// Due kanji, longest overdue first.
    let dueKanjiIDs: [String]
    /// Rough session length in minutes; 0 when nothing is due.
    let estimatedMinutes: Int
    let stageCounts: [StudyStage: Int]
    let comingUp: [ReviewComingUpBucket: Int]
    let week: [ReviewWeekDay]

    var dueCount: Int { dueKanjiIDs.count }
    var tiles: [String] { Array(dueKanjiIDs.prefix(Self.maxTiles)) }
    var overflowCount: Int { max(dueKanjiIDs.count - Self.maxTiles, 0) }
    var totalKanji: Int { stageCounts.values.reduce(0, +) }

    init(
        progress: [KanjiProgressSnapshot],
        reviewLog: [(action: StudyAction, calendarDay: String)],
        sessionSize: ReviewSessionSize,
        dayProvider: any DayProvider
    ) {
        let now = dayProvider.now
        let calendar = dayProvider.calendar
        var generator = SystemRandomNumberGenerator()
        let due = ReviewScheduler.dueQueue(
            from: progress,
            on: now,
            calendar: calendar,
            preferences: ReviewPreferencesSnapshot(order: .dueFirst, sessionSize: .allDue),
            using: &generator
        )
        dueKanjiIDs = due.map(\.kanjiID)
        estimatedMinutes = Self.minutes(dueCount: due.count, sessionSize: sessionSize)
        stageCounts = Dictionary(grouping: progress, by: \.stage).mapValues(\.count)
        comingUp = Self.comingUp(progress: progress, now: now, calendar: calendar)
        week = Self.week(reviewLog: reviewLog, dayProvider: dayProvider)
    }

    func count(for stage: StudyStage) -> Int {
        stageCounts[stage] ?? 0
    }

    func count(for bucket: ReviewComingUpBucket) -> Int {
        comingUp[bucket] ?? 0
    }

    static func minutes(dueCount: Int, sessionSize: ReviewSessionSize) -> Int {
        let cards = sessionSize.limit.map { min(dueCount, $0) } ?? dueCount
        guard cards > 0 else { return 0 }
        return max(1, Int((Double(cards * secondsPerCard) / 60).rounded(.up)))
    }

    private static func comingUp(
        progress: [KanjiProgressSnapshot],
        now: Date,
        calendar: Calendar
    ) -> [ReviewComingUpBucket: Int] {
        let today = calendar.startOfDay(for: now)
        var counts: [ReviewComingUpBucket: Int] = [:]
        for row in progress where row.stage == .learning || row.stage == .familiar {
            guard let next = row.nextReviewAt,
                  let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next)).day,
                  let bucket = ReviewComingUpBucket.bucket(forDaysAhead: days)
            else { continue }
            counts[bucket, default: 0] += 1
        }
        return counts
    }

    private static func week(
        reviewLog: [(action: StudyAction, calendarDay: String)],
        dayProvider: any DayProvider
    ) -> [ReviewWeekDay] {
        let calendar = dayProvider.calendar
        let now = dayProvider.now
        let reviewed = Set(
            reviewLog
                .filter { ($0.action == .gotItReview || $0.action == .forgotItReview) && !$0.calendarDay.isEmpty }
                .map { $0.calendarDay }
        )
        let today = dayProvider.calendarDay(for: now)
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let symbols = calendar.veryShortWeekdaySymbols

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let day = dayProvider.calendarDay(for: date)
            let weekday = calendar.component(.weekday, from: date)
            return ReviewWeekDay(
                label: symbols[weekday - 1],
                calendarDay: day,
                isReviewed: reviewed.contains(day),
                isToday: day == today
            )
        }
    }
}
