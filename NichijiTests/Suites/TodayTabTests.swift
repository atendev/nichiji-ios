import Foundation
import SwiftData
import Testing
@testable import Nichiji

/*-------------------------------today-tests------------------------------*/

@Suite("Today Tab Tests")
struct TodayTabTests {
    @Test("Initial load resolves today's assignment and entry")
    func initialLoad() async throws {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: learnerStore,
            dayProvider: dayProvider
        )

        let day = dayProvider.calendarDay(for: dayProvider.now)
        let assignment = try await service.assignment(for: day)
        let entry = try contentStore.entry(for: assignment!.kanjiID)

        #expect(entry.id == "日")
        #expect(entry.meanings.first == "day")
        #expect(entry.onyomi.first?.kana == "ニチ")
    }

    @Test("Got it marks the assignment learned and advances progress")
    func gotItMarksLearned() async throws {
        let store = TestLearnerStore()
        _ = try await store.createAssignment(calendarDay: "2026-10-28", kanjiID: "日", assignedAt: Date())

        let updated = try await store.markLearned(day: "2026-10-28")
        let nonNewIDs = try await store.nonNewKanjiIDs()

        #expect(updated.status == .learned)
        #expect(nonNewIDs.contains("日"))
    }

    @Test("An exhausted pool produces the level-complete state")
    func levelCompleteState() async throws {
        let dayProvider = TestDayProvider()
        let store = TestLearnerStore()
        let contentStore = TestKanjiContentStore(entries: [SeedKanjiDataset.entries[0]])
        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: store,
            dayProvider: dayProvider
        )
        let today = dayProvider.calendarDay(for: dayProvider.now)
        _ = try await service.assignment(for: today)
        _ = try await store.markLearned(day: today)
        dayProvider.advance(byDays: 1)

        let tomorrow = dayProvider.calendarDay(for: dayProvider.now)
        let assignment = try await service.assignment(for: tomorrow)
        #expect(assignment == nil)
    }

    @Test("Content errors can be retried through the service load path")
    func errorRetry() async throws {
        let store = TestLearnerStore()
        store.shouldThrow = true
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: store,
            dayProvider: TestDayProvider()
        )

        await #expect(throws: NichijiError.self) {
            _ = try await service.assignment(for: "2026-10-28")
        }

        store.shouldThrow = false
        let assignment = try await service.assignment(for: "2026-10-28")
        #expect(assignment != nil)
    }

    @Test("Romaji and stroke data are available for the detail cards")
    func detailCardData() throws {
        let entry = try TestKanjiContentStore(entries: SeedKanjiDataset.entries).entry(for: "日")
        #expect(entry.onyomi.contains { !$0.romaji.isEmpty })
        #expect(entry.exampleWords.contains { !$0.romaji.isEmpty })
        #expect(entry.strokePaths.count == entry.strokeCount)
    }
}
