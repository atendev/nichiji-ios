import Foundation
import SwiftData
import Testing
@testable import Nichiji

/*------------------------------history-tests-----------------------------*/

// Today is Wednesday 2026-11-04 in Tokyo.
@Suite("Study History Tests")
struct StudyHistoryTests {
    private let clock = StatsClock()

    /// 2026-10-31 20:00 UTC, which is 2026-11-01 05:00 in Tokyo.
    private var legacyReset: StudyLogRecord {
        StudyLogRecord(kanjiID: "月", action: .resetToNew, timestamp: Date(timeIntervalSince1970: 1_793_476_800), calendarDay: "")
    }

    @Test("Days run newest first, entries oldest first, resets included")
    func grouping() {
        let log = [
            clock.record("日", .gotItReview, "2026-11-04", hour: 9),
            clock.record("日", .learnedDaily, "2026-11-04", hour: 8),
            clock.record("一", .learnedDaily, "2026-11-03"),
            legacyReset,
            clock.record("二", .learnedDaily, "2026-10-26"),
            clock.record("三", .learnedDaily, "2025-10-26")
        ]
        let days = StudyHistory.days(log: log, dayProvider: clock.provider)
        #expect(days.map(\.calendarDay) == ["2026-11-04", "2026-11-03", "2026-11-01", "2026-10-26", "2025-10-26"])
        #expect(days.map(\.heading) == ["TODAY", "YESTERDAY", "SUN, NOV 1", "MON, OCT 26", "SUN, OCT 26, 2025"])
        #expect(days[0].entries.map(\.action) == [.learnedDaily, .gotItReview])
        #expect(days[2].entries.map(\.action) == [.resetToNew])
    }

    @Test("An empty stored day resolves to the timestamp's day in the provider's zone")
    func effectiveDay() {
        #expect(legacyReset.day(using: clock.provider) == "2026-11-01")
        let stored = clock.record("日", .learnedDaily, "2026-11-02", hour: 0, minute: 5)
        #expect(stored.day(using: clock.provider) == "2026-11-02")
        #expect(!StudyDay.days(in: [legacyReset], dayProvider: clock.provider).contains("2026-11-01"))
    }

    @Test("Only learned and review answers make a study day")
    func studyDayRule() {
        #expect(StudyDay.counts(.learnedDaily))
        #expect(StudyDay.counts(.gotItReview))
        #expect(StudyDay.counts(.forgotItReview))
        #expect(!StudyDay.counts(.resetToNew))
    }

    /*---------------------------------csv----------------------------------*/

    private func csvText(_ log: [StudyLogRecord], meanings: [String: String] = [:]) throws -> String {
        let data = HistoryCSV.data(log: log, meanings: meanings, dayProvider: clock.provider)
        #expect(Array(data.prefix(3)) == [0xEF, 0xBB, 0xBF])
        return try #require(String(data: data.dropFirst(3), encoding: .utf8))
    }

    @Test("The CSV lists every entry oldest first with mapped actions, meanings and offset times")
    func csvRows() throws {
        let log = [
            clock.record("日", .forgotItReview, "2026-11-04", hour: 9),
            clock.record("日", .learnedDaily, "2026-11-03", hour: 8),
            clock.record("日", .gotItReview, "2026-11-03", hour: 21),
            legacyReset
        ]
        let text = try csvText(log, meanings: ["日": "day", "月": "month"])
        #expect(text == """
        date,time,kanji,meaning,action
        2026-11-01,2026-11-01T05:00:00+09:00,月,month,forget_it
        2026-11-03,2026-11-03T08:00:00+09:00,日,day,learned
        2026-11-03,2026-11-03T21:00:00+09:00,日,day,got_it
        2026-11-04,2026-11-04T09:00:00+09:00,日,day,forgot_it

        """)
    }

    @Test("An empty log exports the header only")
    func csvEmpty() throws {
        #expect(try csvText([]) == "date,time,kanji,meaning,action\n")
    }

    @Test("Fields with commas, quotes or line breaks are quoted")
    func csvEscaping() {
        #expect(HistoryCSV.escape("plain") == "plain")
        #expect(HistoryCSV.escape("day, sun") == "\"day, sun\"")
        #expect(HistoryCSV.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(HistoryCSV.escape("two\nlines") == "\"two\nlines\"")
        #expect(HistoryCSV.escape("two\r\nlines") == "\"two\r\nlines\"")
    }

    @Test("The file name carries today's date")
    func csvFileName() {
        #expect(HistoryCSV.fileName(dayProvider: clock.provider) == "nichiji-history-2026-11-04.csv")
    }
}

/*-------------------------------store-tests------------------------------*/

@Suite("Study Log Store Tests")
struct StudyLogStoreTests {
    private let clock = StatsClock()

    /// Holds the container so the in-memory store outlives each test's statements.
    private final class Fixture: @unchecked Sendable {
        let container: ModelContainer
        let store: SwiftDataLearnerStore

        init() throws {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: Schema.nichijiLearner, configurations: configuration)
            store = SwiftDataLearnerStore(modelContainer: container)
        }
    }

    @Test("Got it, review answers with repeats, and Forget it each write one row under their day")
    func everyActionLogs() async throws {
        let fixture = try Fixture()
        let store = fixture.store
        _ = try await store.createAssignment(calendarDay: "2026-11-03", kanjiID: "日", assignedAt: clock.at("2026-11-03"))
        _ = try await store.markLearned(day: "2026-11-03", nextReviewAt: clock.at("2026-11-04", hour: 0))
        try await store.recordReview(kanjiID: "日", answer: .forgotIt, outcome: nil, reviewedAt: clock.at("2026-11-04", hour: 9), calendarDay: "2026-11-04")
        try await store.recordReview(kanjiID: "日", answer: .forgotIt, outcome: nil, reviewedAt: clock.at("2026-11-04", hour: 10), calendarDay: "2026-11-04")
        try await store.recordReview(kanjiID: "日", answer: .gotIt, outcome: nil, reviewedAt: clock.at("2026-11-04", hour: 11), calendarDay: "2026-11-04")
        try await store.forgetIt(kanjiID: "日", calendarDay: "2026-11-04")

        // Got it and Forget it stamp the real clock, so compare without relying on row order.
        let log = try await store.studyLog().map { "\($0.action.rawValue)@\($0.calendarDay)" }.sorted()
        #expect(log == [
            "forgotItReview@2026-11-04", "forgotItReview@2026-11-04", "gotItReview@2026-11-04",
            "learnedDaily@2026-11-03", "resetToNew@2026-11-04"
        ])
    }

    @Test("The log reads oldest first and keeps an empty day for the resolver")
    func studyLogOrder() async throws {
        let fixture = try Fixture()
        let store = fixture.store
        let context = ModelContext(fixture.container)
        context.insert(StudyLogEntry(kanjiID: "二", action: .gotItReview, timestamp: clock.at("2026-11-03"), calendarDay: "2026-11-03"))
        context.insert(StudyLogEntry(kanjiID: "一", action: .resetToNew, timestamp: Date(timeIntervalSince1970: 1_793_476_800), calendarDay: ""))
        try context.save()

        let log = try await store.studyLog()
        #expect(log.map(\.kanjiID) == ["一", "二"])
        #expect(log.first?.calendarDay == "")
        #expect(log.first?.day(using: clock.provider) == "2026-11-01")
    }

    @Test("All progress returns every row, new ones included")
    func allProgress() async throws {
        let fixture = try Fixture()
        let store = fixture.store
        _ = try await store.createAssignment(calendarDay: "2026-11-03", kanjiID: "日", assignedAt: clock.at("2026-11-03"))
        _ = try await store.createAssignment(calendarDay: "2026-11-04", kanjiID: "一", assignedAt: clock.at("2026-11-04"))
        _ = try await store.markLearned(day: "2026-11-03", nextReviewAt: clock.at("2026-11-04", hour: 0))

        let stages = try await store.allProgress().reduce(into: [String: StudyStage]()) { $0[$1.kanjiID] = $1.stage }
        #expect(stages == ["日": .learning, "一": .new])
    }

    @Test("The stats service reads the store and the index")
    func serviceReadsStore() async throws {
        let fixture = try Fixture()
        let store = fixture.store
        _ = try await store.createAssignment(calendarDay: "2026-11-04", kanjiID: "日", assignedAt: clock.at("2026-11-04"))
        _ = try await store.markLearned(day: "2026-11-04", nextReviewAt: clock.at("2026-11-05", hour: 0))
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        let service = DefaultStatsService(learnerStore: store, contentStore: contentStore, dayProvider: clock.provider)

        let stats = try await service.stats(preferences: .standard)
        let log = try await store.studyLog()
        let progress = try await store.allProgress()
        let index = try contentStore.indexEntries()
        let expected = StatsCalculator.stats(log: log, progress: progress, index: index, preferences: .standard, dayProvider: clock.provider)
        #expect(stats == expected)
        #expect(stats.streak.current == 1)
        #expect(stats.kanjiLearned == 1)

        let history = try await service.history()
        #expect(history.map(\.heading) == ["TODAY"])

        let export = try await service.historyExport()
        #expect(export.fileName == "nichiji-history-2026-11-04.csv")
        let text = try #require(String(data: export.data.dropFirst(3), encoding: .utf8))
        #expect(text.hasSuffix(",日,day,learned\n"))

        let figures = try await service.levelComplete(level: .jlpt(.n5))
        #expect(figures.kanjiLearned == 1)
        #expect(figures.daysTaken == 1)
    }
}
