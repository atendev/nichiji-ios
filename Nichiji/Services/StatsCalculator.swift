import Foundation

/*------------------------------calculator------------------------------------*/

/// Pure stats over the study log and progress rows. Nothing here is stored; every number is recomputed.
enum StatsCalculator {
    static let activityWeeks = 12
    static let needsAttentionLimit = 3

    static func stats(
        log: [StudyLogRecord],
        progress: [KanjiProgressSnapshot],
        index: [KanjiIndexEntry],
        preferences: LearnerPreferencesSnapshot,
        dayProvider: any DayProvider
    ) -> LearnerStats {
        let studyDays = StudyDay.days(in: log, dayProvider: dayProvider)
        let streak = streaks(studyDays: studyDays, freezeEnabled: preferences.streakFreezeEnabled, dayProvider: dayProvider)
        let reviewsDone = log.filter { $0.action == .gotItReview || $0.action == .forgotItReview }.count
        let learnedEver = Set(log.filter { $0.action == .learnedDaily }.map(\.kanjiID))

        return LearnerStats(
            streak: streak,
            streakFreeze: streak.freeze,
            kanjiLearned: progress.filter { $0.stage != .new }.count,
            reviewsDone: reviewsDone,
            gotItRate: gotItRate(in: log),
            daysStudied: studyDays.count,
            learningSince: learningSince(log: log, dayProvider: dayProvider),
            activity: activityGrid(log: log, dayProvider: dayProvider),
            levelBars: levelBars(progress: progress, index: index, system: preferences.levelSystem),
            milestones: milestones(
                learnedEver: learnedEver,
                reviewsDone: reviewsDone,
                longestStreak: streak.longest,
                index: index,
                system: preferences.levelSystem
            ),
            needsAttention: needsAttention(progress: progress, log: log),
            learnedKanjiIDs: learnedKanjiIDs(progress: progress)
        )
    }

    /*-------------------------------streaks----------------------------------*/

    /// Walks every day from the first study day to today. Today only adds; it never breaks the streak.
    static func streaks(studyDays: Set<String>, freezeEnabled: Bool, dayProvider: any DayProvider) -> StreakSummary {
        let calendar = dayProvider.calendar
        let today = calendar.startOfDay(for: dayProvider.now)
        let todayKey = dayProvider.calendarDay(for: today)
        var walk = StreakWalk(freezeEnabled: freezeEnabled)

        if let firstKey = studyDays.min(), var day = date(forDay: firstKey, dayProvider: dayProvider) {
            while day <= today {
                let key = dayProvider.calendarDay(for: day)
                if studyDays.contains(key) {
                    walk.study()
                } else if key != todayKey {
                    walk.miss(week: weekStart(of: day, calendar: calendar))
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }

        let freeze: StreakFreezeState? = freezeEnabled
            ? (walk.forgivenWeeks.contains(weekStart(of: today, calendar: calendar)) ? .usedThisWeek : .ready)
            : nil
        return StreakSummary(current: walk.run, longest: walk.longest, freeze: freeze)
    }

    /*--------------------------------tiles-----------------------------------*/

    /// Got it share of review answers, halves rounded up; nil before the first answer.
    static func gotItRate(in log: [StudyLogRecord]) -> Int? {
        let got = log.filter { $0.action == .gotItReview }.count
        let forgot = log.filter { $0.action == .forgotItReview }.count
        guard got + forgot > 0 else { return nil }
        return Int((Double(got) * 100 / Double(got + forgot)).rounded())
    }

    static func learningSince(log: [StudyLogRecord], dayProvider: any DayProvider) -> YearMonth? {
        guard let first = log.map({ $0.day(using: dayProvider) }).min() else { return nil }
        let parts = first.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return YearMonth(year: parts[0], month: parts[1])
    }

    /*-------------------------------activity---------------------------------*/

    /// Twelve weeks ending with the current one, each in locale weekday order.
    static func activityGrid(log: [StudyLogRecord], dayProvider: any DayProvider) -> [[ActivityCell]] {
        let calendar = dayProvider.calendar
        let today = calendar.startOfDay(for: dayProvider.now)
        let thisWeek = weekStart(of: today, calendar: calendar)
        var counts: [String: Int] = [:]
        for record in log where StudyDay.counts(record.action) {
            counts[record.day(using: dayProvider), default: 0] += 1
        }

        return (0..<activityWeeks).map { column in
            let weekOffset = (column - (activityWeeks - 1)) * 7
            let start = calendar.date(byAdding: .day, value: weekOffset, to: thisWeek) ?? thisWeek
            return (0..<7).map { row in
                let date = calendar.date(byAdding: .day, value: row, to: start) ?? start
                let key = dayProvider.calendarDay(for: date)
                let count = counts[key] ?? 0
                return ActivityCell(calendarDay: key, count: count, shade: date > today ? nil : shade(for: count))
            }
        }
    }

    static func shade(for count: Int) -> Int {
        switch count {
        case ...0: 0
        case 1: 1
        case 2...10: 2
        case 11...20: 3
        default: 4
        }
    }

    /*-------------------------------helpers----------------------------------*/

    /// Start of the local day a day key names, in the provider's calendar.
    static func date(forDay day: String, dayProvider: any DayProvider) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = dayProvider.calendar
        formatter.timeZone = dayProvider.calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: day).map { dayProvider.calendar.startOfDay(for: $0) }
    }

    static func weekStart(of date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}

/*--------------------------------walk----------------------------------------*/

/// Running state for the day-by-day streak walk.
private struct StreakWalk {
    let freezeEnabled: Bool
    var run = 0
    var longest = 0
    var lastForgivenWeek: Date?
    var forgivenWeeks: Set<Date> = []

    mutating func study() {
        run += 1
        longest = max(longest, run)
    }

    /// A miss spends the week's freeze if it is still there; otherwise it breaks the streak.
    mutating func miss(week: Date) {
        if freezeEnabled, lastForgivenWeek != week {
            lastForgivenWeek = week
            forgivenWeeks.insert(week)
        } else {
            run = 0
        }
    }
}
