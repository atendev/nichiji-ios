import Foundation
@testable import Nichiji

/*------------------------------stats-fixtures--------------------------------*/

/// A Tokyo clock pinned to a day key, with helpers for log rows and index entries.
struct StatsClock {
    let provider: TestDayProvider

    /// Defaults to Wednesday 2026-11-04 with Monday-first weeks.
    init(today: String = "2026-11-04", hour: Int = 12, firstWeekday: Int = 2) {
        provider = TestDayProvider()
        provider.simulatedCalendar.firstWeekday = firstWeekday
        provider.simulatedDate = Self.date(today, hour: hour, minute: 0, calendar: provider.simulatedCalendar)
    }

    var today: String { provider.calendarDay(for: provider.now) }

    func at(_ day: String, hour: Int = 10, minute: Int = 0) -> Date {
        Self.date(day, hour: hour, minute: minute, calendar: provider.calendar)
    }

    func record(_ kanjiID: String, _ action: StudyAction, _ day: String, hour: Int = 10, minute: Int = 0) -> StudyLogRecord {
        StudyLogRecord(kanjiID: kanjiID, action: action, timestamp: at(day, hour: hour, minute: minute), calendarDay: day)
    }

    /// One study row per day key.
    func studied(_ days: [String], kanjiID: String = "日") -> [StudyLogRecord] {
        days.map { record(kanjiID, .gotItReview, $0) }
    }

    func streaks(_ days: [String], freeze: Bool) -> StreakSummary {
        StatsCalculator.streaks(studyDays: Set(days), freezeEnabled: freeze, dayProvider: provider)
    }

    private static func date(_ day: String, hour: Int, minute: Int, calendar: Calendar) -> Date {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: hour, minute: minute)
        return calendar.date(from: components) ?? .distantPast
    }
}

enum StatsFixtures {
    static func entry(_ id: String, jlpt: JLPTLevel?, joyo: JoyoGrade?, listIndex: Int = 0, meaning: String = "") -> KanjiIndexEntry {
        KanjiIndexEntry(
            id: id,
            primaryMeaning: meaning,
            primaryReading: "",
            strokeCount: 1,
            jlptLevel: jlpt,
            joyoGrade: joyo,
            listIndex: listIndex
        )
    }

    static func progress(
        _ id: String,
        _ stage: StudyStage,
        learnedAt: Date? = nil,
        gotItCount: Int = 0,
        forgotItCount: Int = 0
    ) -> KanjiProgressSnapshot {
        KanjiProgressSnapshot(
            kanjiID: id,
            stage: stage,
            firstLearnedAt: learnedAt,
            gotItCount: gotItCount,
            forgotItCount: forgotItCount
        )
    }

    /// A kanji the learner marked as already known.
    static func declared(_ id: String, at date: Date, forgotItCount: Int = 0) -> KanjiProgressSnapshot {
        KanjiProgressSnapshot(kanjiID: id, stage: .known, forgotItCount: forgotItCount, declaredKnownAt: date)
    }
}
