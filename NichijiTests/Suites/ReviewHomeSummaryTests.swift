import Foundation
import Testing
@testable import Nichiji

/*---------------------------review-home-tests----------------------------*/

// The test day is Wednesday 2023-11-15 in Tokyo.
@Suite("Review Home Summary Tests")
struct ReviewHomeSummaryTests {
    private let dayProvider = TestDayProvider()

    private func day(_ offset: Int, hour: Int = 9, minute: Int = 0) -> Date {
        let calendar = dayProvider.calendar
        let start = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: dayProvider.now))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)!
    }

    private func row(_ id: String, _ stage: StudyStage, dueIn offset: Int? = nil) -> KanjiProgressSnapshot {
        KanjiProgressSnapshot(kanjiID: id, stage: stage, nextReviewAt: offset.map { day($0, hour: 0) })
    }

    private func summary(
        _ progress: [KanjiProgressSnapshot],
        log: [(action: StudyAction, calendarDay: String)] = [],
        size: ReviewSessionSize = .ten
    ) -> ReviewHomeSummary {
        let records = log.map { StudyLogRecord(kanjiID: "日", action: $0.action, timestamp: day(-400), calendarDay: $0.calendarDay) }
        return ReviewHomeSummary(progress: progress, studyLog: records, sessionSize: size, dayProvider: dayProvider)
    }

    @Test("No progress shows nothing due")
    func emptySummary() {
        let result = summary([])
        #expect(result.dueCount == 0)
        #expect(result.tiles.isEmpty)
        #expect(result.estimatedMinutes == 0)
        #expect(result.totalKanji == 0)
        #expect(result.count(for: .tomorrow) == 0)
    }

    @Test("Seven due kanji show six tiles and one more")
    func tilesOverflow() {
        let progress = (0..<7).map { row("k\($0)", .learning, dueIn: -$0) }
        let result = summary(progress)
        #expect(result.dueCount == 7)
        #expect(result.tiles == ["k6", "k5", "k4", "k3", "k2", "k1"])
        #expect(result.overflowCount == 1)
    }

    @Test("Six due kanji fit without overflow")
    func tilesExact() {
        let result = summary((0..<6).map { row("k\($0)", .familiar, dueIn: 0) })
        #expect(result.tiles.count == 6)
        #expect(result.overflowCount == 0)
    }

    @Test("Minutes round up at 20 seconds a card and respect the session size")
    func minutes() {
        #expect(ReviewHomeSummary.minutes(dueCount: 1, sessionSize: .ten) == 1)
        #expect(ReviewHomeSummary.minutes(dueCount: 6, sessionSize: .ten) == 2)
        #expect(ReviewHomeSummary.minutes(dueCount: 10, sessionSize: .ten) == 4)
        #expect(ReviewHomeSummary.minutes(dueCount: 25, sessionSize: .ten) == 4)
        #expect(ReviewHomeSummary.minutes(dueCount: 25, sessionSize: .allDue) == 9)
        #expect(ReviewHomeSummary.minutes(dueCount: 0, sessionSize: .allDue) == 0)
    }

    @Test("Known and new kanji are never due")
    func knownNotDue() {
        let result = summary([row("a", .known, dueIn: -2), row("b", .new), row("c", .learning, dueIn: 0)])
        #expect(result.dueKanjiIDs == ["c"])
    }

    @Test("Stage counts cover every progress row")
    func stageCounts() {
        let result = summary([row("a", .new), row("b", .learning, dueIn: 1), row("c", .learning, dueIn: 2), row("d", .known)])
        #expect(result.count(for: .new) == 1)
        #expect(result.count(for: .learning) == 2)
        #expect(result.count(for: .familiar) == 0)
        #expect(result.count(for: .known) == 1)
        #expect(result.totalKanji == 4)
    }

    @Test("Coming up buckets by days ahead and skips today and past a week")
    func comingUpBuckets() {
        let progress = [0, 1, 2, 3, 4, 7, 8].map { row("d\($0)", .learning, dueIn: $0) }
        let result = summary(progress)
        #expect(result.count(for: .tomorrow) == 1)
        #expect(result.count(for: .inThreeDays) == 2)
        #expect(result.count(for: .nextWeek) == 2)
    }

    @Test("Due is by day: late tonight is today, just after midnight is tomorrow")
    func dayGranularity() {
        let late = KanjiProgressSnapshot(kanjiID: "late", stage: .learning, nextReviewAt: day(0, hour: 23, minute: 59))
        let early = KanjiProgressSnapshot(kanjiID: "early", stage: .learning, nextReviewAt: day(1, hour: 0, minute: 1))
        let result = summary([late, early])
        #expect(result.dueKanjiIDs == ["late"])
        #expect(result.count(for: .tomorrow) == 1)
    }

    @Test("Known kanji with a stale date stay out of Coming up")
    func knownOutOfComingUp() {
        let result = summary([row("a", .known, dueIn: 1), row("b", .known, dueIn: 3)])
        #expect(result.count(for: .tomorrow) == 0)
        #expect(result.count(for: .inThreeDays) == 0)
    }

    @Test("This week marks study days: learned or reviewed, never a reset alone")
    func weekFromStudyDays() {
        dayProvider.simulatedCalendar.firstWeekday = 2
        let log: [(action: StudyAction, calendarDay: String)] = [
            (.gotItReview, "2023-11-13"),
            (.learnedDaily, "2023-11-14"),
            (.forgotItReview, "2023-11-15"),
            (.resetToNew, "2023-11-16"),
            (.gotItReview, "2023-11-06"),
            (.gotItReview, "")
        ]
        let week = summary([], log: log).week
        #expect(week.count == 7)
        #expect(week.first?.calendarDay == "2023-11-13")
        #expect(week.map(\.isStudyDay) == [true, true, true, false, false, false, false])
        #expect(week.firstIndex(where: \.isToday) == 2)
    }

    @Test("An empty stored day counts under its timestamp's day")
    func weekResolvesEmptyDay() {
        dayProvider.simulatedCalendar.firstWeekday = 2
        let record = StudyLogRecord(kanjiID: "日", action: .learnedDaily, timestamp: day(-1, hour: 0, minute: 30), calendarDay: "")
        let week = ReviewHomeSummary(progress: [], studyLog: [record], sessionSize: .ten, dayProvider: dayProvider).week
        #expect(week.map(\.isStudyDay) == [false, true, false, false, false, false, false])
    }

    @Test("The week starts on the calendar's first weekday")
    func weekStartFollowsCalendar() {
        dayProvider.simulatedCalendar.firstWeekday = 1
        let week = summary([], log: [(action: .gotItReview, calendarDay: "2023-11-13")]).week
        #expect(week.first?.calendarDay == "2023-11-12")
        #expect(week.firstIndex(where: \.isStudyDay) == 1)
    }
}
