import Foundation
import Testing
@testable import Nichiji

/*------------------------------streak-tests------------------------------*/

// Today is Wednesday 2026-11-04 in Tokyo; weeks start Monday unless a test says otherwise.
@Suite("Stats Streak Tests")
struct StatsStreakTests {
    private let clock = StatsClock()

    @Test("An empty log has no streak")
    func emptyLog() {
        #expect(clock.streaks([], freeze: false) == StreakSummary(current: 0, longest: 0, freeze: nil))
        #expect(clock.streaks([], freeze: true).freeze == .ready)
    }

    @Test("Today not yet studied keeps yesterday's streak; studying today adds one")
    func todayNeverBreaks() {
        #expect(clock.streaks(["2026-11-01", "2026-11-02", "2026-11-03"], freeze: false).current == 3)
        #expect(clock.streaks(["2026-11-02", "2026-11-03", "2026-11-04"], freeze: false).current == 3)
        #expect(clock.streaks(["2026-11-01", "2026-11-02"], freeze: false).current == 0)
    }

    @Test("A gap breaks the streak and the longest run is kept")
    func gapBreaks() {
        let summary = clock.streaks(["2026-10-25", "2026-10-26", "2026-10-27", "2026-10-28", "2026-10-30", "2026-11-03"], freeze: false)
        #expect(summary.current == 1)
        #expect(summary.longest == 4)
    }

    @Test("The freeze forgives one miss; the forgiven day adds nothing, and turning it on repairs the break")
    func freezeForgives() {
        let days = ["2026-10-30", "2026-10-31", "2026-11-02", "2026-11-03"]
        #expect(clock.streaks(days, freeze: false).current == 2)
        let frozen = clock.streaks(days, freeze: true)
        #expect(frozen.current == 4)
        #expect(frozen.longest == 4)
        #expect(frozen.freeze == .ready)
    }

    @Test("A second miss in the same week breaks the streak")
    func secondMissBreaks() {
        let days = ["2026-10-26", "2026-10-29", "2026-10-30", "2026-10-31", "2026-11-01", "2026-11-02", "2026-11-03"]
        let summary = clock.streaks(days, freeze: true)
        #expect(summary.current == 6)
        #expect(summary.longest == 6)
    }

    @Test("The freeze refills each week")
    func freezeRefills() {
        let days = ["2026-10-26", "2026-10-27", "2026-10-29", "2026-10-30", "2026-10-31", "2026-11-01", "2026-11-03"]
        let summary = clock.streaks(days, freeze: true)
        #expect(summary.current == 7)
        #expect(summary.freeze == .usedThisWeek)
    }

    @Test("The week boundary follows the calendar's first weekday")
    func weekBoundary() {
        let days = ["2026-10-29", "2026-10-30", "2026-10-31", "2026-11-03"]
        #expect(StatsClock(firstWeekday: 2).streaks(days, freeze: true).current == 4)
        #expect(StatsClock(firstWeekday: 1).streaks(days, freeze: true).current == 1)
    }

    @Test("Forgiven days bridge runs in the longest streak only with the freeze on")
    func longestBridgesWithFreeze() {
        let days = ["2026-10-20", "2026-10-21", "2026-10-22", "2026-10-24", "2026-10-25"]
        #expect(clock.streaks(days, freeze: true).longest == 5)
        #expect(clock.streaks(days, freeze: false).longest == 3)
        #expect(clock.streaks(days, freeze: true).current == 0)
        // Monday's miss spent this week's freeze even though the streak had already broken.
        #expect(clock.streaks(days, freeze: true).freeze == .usedThisWeek)
    }

    @Test("A day with only a reset is a miss")
    func resetOnlyDayIsMissed() {
        let log = clock.studied(["2026-11-02", "2026-11-04"]) + [clock.record("日", .resetToNew, "2026-11-03")]
        let days = StudyDay.days(in: log, dayProvider: clock.provider)
        #expect(StatsCalculator.streaks(studyDays: days, freezeEnabled: false, dayProvider: clock.provider).current == 1)
        let frozen = StatsCalculator.streaks(studyDays: days, freezeEnabled: true, dayProvider: clock.provider)
        #expect(frozen.current == 2)
        #expect(frozen.freeze == .usedThisWeek)
    }

    /*-----------------------------freeze-row-------------------------------*/

    @Test("The freeze row is ready with no miss this week, nil with the setting off")
    func freezeReady() {
        #expect(clock.streaks(["2026-11-02", "2026-11-03"], freeze: true).freeze == .ready)
        #expect(clock.streaks(["2026-11-03"], freeze: true).freeze == .ready)
        #expect(clock.streaks(["2026-11-02", "2026-11-03"], freeze: false).freeze == nil)
    }

    @Test("A forgiven yesterday uses this week's freeze")
    func freezeUsedYesterday() {
        let summary = clock.streaks(["2026-11-02"], freeze: true)
        #expect(summary.current == 1)
        #expect(summary.freeze == .usedThisWeek)
    }

    @Test("A forgiven day stays used after a later second miss breaks the streak")
    func freezeUsedAfterBreak() {
        let thursday = StatsClock(today: "2026-11-05")
        let summary = thursday.streaks(["2026-11-02", "2026-11-05"], freeze: true)
        #expect(summary.current == 1)
        #expect(summary.freeze == .usedThisWeek)
    }

    @Test("A miss last week leaves this week's freeze ready")
    func freezeReadyNextWeek() {
        let summary = clock.streaks(["2026-10-30", "2026-11-01", "2026-11-02", "2026-11-03"], freeze: true)
        #expect(summary.current == 4)
        #expect(summary.freeze == .ready)
    }
}

/*-------------------------------tile-tests-------------------------------*/

@Suite("Stats Tile Tests")
struct StatsTileTests {
    private let clock = StatsClock()

    private func stats(
        _ log: [StudyLogRecord],
        progress: [KanjiProgressSnapshot] = [],
        preferences: LearnerPreferencesSnapshot = .standard
    ) -> LearnerStats {
        StatsCalculator.stats(log: log, progress: progress, index: [], preferences: preferences, dayProvider: clock.provider)
    }

    @Test("Kanji learned counts stages past new, so Forget it lowers it")
    func kanjiLearned() {
        let progress = [StatsFixtures.progress("日", .learning), StatsFixtures.progress("月", .known), StatsFixtures.progress("火", .new)]
        #expect(stats([], progress: progress).kanjiLearned == 2)
    }

    @Test("Reviews done counts every answer, repeats included")
    func reviewsDone() {
        let log = [
            clock.record("日", .gotItReview, "2026-11-03"),
            clock.record("日", .forgotItReview, "2026-11-03"),
            clock.record("日", .forgotItReview, "2026-11-03"),
            clock.record("月", .learnedDaily, "2026-11-03"),
            clock.record("月", .resetToNew, "2026-11-03")
        ]
        #expect(stats(log).reviewsDone == 3)
    }

    @Test("Got-it rate rounds halves up and is nil before the first answer")
    func gotItRate() {
        func rate(got: Int, forgot: Int) -> Int? {
            let log = Array(repeating: clock.record("日", .gotItReview, "2026-11-03"), count: got)
                + Array(repeating: clock.record("日", .forgotItReview, "2026-11-03"), count: forgot)
            return StatsCalculator.gotItRate(in: log)
        }
        #expect(rate(got: 2, forgot: 1) == 67)
        #expect(rate(got: 1, forgot: 7) == 13)
        #expect(rate(got: 0, forgot: 0) == nil)
        #expect(stats([clock.record("日", .learnedDaily, "2026-11-03")]).gotItRate == nil)
    }

    @Test("Got-it rate comes from the log, not the progress count")
    func gotItRateIgnoresProgressCount() {
        let log = [clock.record("日", .gotItReview, "2026-11-03"), clock.record("日", .forgotItReview, "2026-11-03")]
        let progress = [StatsFixtures.progress("日", .learning, gotItCount: 5, forgotItCount: 1)]
        #expect(stats(log, progress: progress).gotItRate == 50)
    }

    @Test("Days studied counts study days, not resets")
    func daysStudied() {
        let log = clock.studied(["2026-11-01", "2026-11-01", "2026-11-03"]) + [clock.record("日", .resetToNew, "2026-11-02")]
        #expect(stats(log).daysStudied == 2)
    }

    @Test("The freeze row reads the streak freeze setting")
    func freezeRow() {
        let log = clock.studied(["2026-11-02"])
        #expect(stats(log).streakFreeze == nil)
        #expect(stats(log, preferences: LearnerPreferencesSnapshot(streakFreezeEnabled: true)).streakFreeze == .usedThisWeek)
    }

    @Test("Learning since is the earliest entry's month, from its effective day")
    func learningSince() {
        #expect(stats([]).learningSince == nil)
        #expect(stats(clock.studied(["2026-11-03", "2026-09-14"])).learningSince == YearMonth(year: 2026, month: 9))
        let legacy = StudyLogRecord(
            kanjiID: "日",
            action: .resetToNew,
            timestamp: Date(timeIntervalSince1970: 1_793_476_800),
            calendarDay: ""
        )
        #expect(stats([legacy] + clock.studied(["2026-11-03"])).learningSince == YearMonth(year: 2026, month: 11))
    }
}

/*-----------------------------activity-tests-----------------------------*/

@Suite("Stats Activity Tests")
struct StatsActivityTests {
    private let clock = StatsClock()

    private func grid(_ log: [StudyLogRecord]) -> [[ActivityCell]] {
        StatsCalculator.activityGrid(log: log, dayProvider: clock.provider)
    }

    private func rows(_ count: Int, _ day: String) -> [StudyLogRecord] {
        (0..<count).map { clock.record("日", $0.isMultiple(of: 2) ? .learnedDaily : .gotItReview, day) }
    }

    @Test("Twelve weeks, oldest first, the current week last, future days blank")
    func shape() {
        let cells = grid([])
        #expect(cells.count == 12)
        #expect(cells.allSatisfy { $0.count == 7 })
        #expect(cells.first?.first?.calendarDay == "2026-08-17")
        #expect(cells.last?.map(\.calendarDay) == ["2026-11-02", "2026-11-03", "2026-11-04", "2026-11-05", "2026-11-06", "2026-11-07", "2026-11-08"])
        #expect(cells.last?.map(\.shade) == [0, 0, 0, nil, nil, nil, nil])
    }

    @Test("Shades bucket learned plus review answers at 0, 1, 2-10, 11-20 and 21+")
    func buckets() {
        let log = rows(1, "2026-10-26") + rows(2, "2026-10-27") + rows(10, "2026-10-28") + rows(11, "2026-10-29")
            + rows(20, "2026-10-30") + rows(21, "2026-10-31") + [clock.record("日", .resetToNew, "2026-11-01")]
        let week = grid(log)[10]
        #expect(week.map(\.count) == [1, 2, 10, 11, 20, 21, 0])
        #expect(week.map(\.shade) == [1, 2, 2, 3, 3, 4, 0])
    }

    @Test("A legacy empty-day row lands on its timestamp's day")
    func legacyRowCell() {
        let legacy = StudyLogRecord(kanjiID: "日", action: .learnedDaily, timestamp: clock.at("2026-11-02", hour: 0, minute: 30), calendarDay: "")
        #expect(grid([legacy]).last?.first?.count == 1)
    }
}
