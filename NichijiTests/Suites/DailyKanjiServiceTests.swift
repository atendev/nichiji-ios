import Testing
import Foundation
import SwiftData
@testable import Nichiji

/*-----------------------------rollover-tests-----------------------------*/

@Suite("DailyKanjiService Tests")
struct DailyKanjiServiceTests {
    private func makeTestEnvironment() throws -> (DefaultDailyKanjiService, TestDayProvider, SwiftDataLearnerStore, TestKanjiContentStore) {
        let dayProvider = TestDayProvider()
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)

        let schema = Schema([
            KanjiProgress.self,
            DailyAssignment.self,
            CustomKanjiSelection.self,
            StudyLogEntry.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let learnerStore = SwiftDataLearnerStore(modelContainer: container)

        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: learnerStore,
            dayProvider: dayProvider,
            preferencesProvider: { .standard }
        )
        return (service, dayProvider, learnerStore, contentStore)
    }

    @Test("DayProvider formats calendar days and calculates next midnight accurately")
    func calendarDayFormattingAndMidnight() {
        let provider = TestDayProvider()
        let dayString = provider.calendarDay(for: provider.now)
        #expect(dayString.count == 10)
        #expect(dayString.contains("-"))

        let midnight = provider.nextMidnight(after: provider.now)
        #expect(midnight > provider.now)

        let systemProvider = SystemDayProvider()
        let today = systemProvider.calendarDay(for: systemProvider.now)
        #expect(today.count == 10)
    }

    @Test("Lazy rollover marks past assigned rows as missed while keeping stage new")
    func lazyRolloverMarksPastAssignedAsMissed() async throws {
        let (service, dayProvider, learnerStore, _) = try makeTestEnvironment()

        // Day 1 assignment
        let day1 = dayProvider.calendarDay(for: dayProvider.now)
        let assignment1 = try await service.assignment(for: day1)
        #expect(assignment1 != nil)
        #expect(assignment1?.status == .assigned)

        // Advance 1 day
        dayProvider.advance(byDays: 1)
        let day2 = dayProvider.calendarDay(for: dayProvider.now)

        // Request day 2 assignment -> triggers rollover of day 1
        let assignment2 = try await service.assignment(for: day2)
        #expect(assignment2 != nil)
        #expect(assignment2?.calendarDay == day2)

        // Check day 1 status in store
        let past = try await learnerStore.assignment(for: day1)
        #expect(past?.status == .missed)

        // KanjiProgress for past missed kanji must remain .new
        let nonNew = try await learnerStore.nonNewKanjiIDs()
        #expect(!nonNew.contains(assignment1!.kanjiID))
    }

    @Test("Same-day assignment calls are idempotent")
    func sameDayAssignmentIsIdempotent() async throws {
        let (service, dayProvider, _, _) = try makeTestEnvironment()
        let today = dayProvider.calendarDay(for: dayProvider.now)

        let first = try await service.assignment(for: today)
        let second = try await service.assignment(for: today)

        #expect(first?.kanjiID == second?.kanjiID)
        #expect(first?.calendarDay == second?.calendarDay)
    }

    @Test("Selection strategies are deterministic")
    func deterministicSelectionOrders() async throws {
        let (service, _, _, _) = try makeTestEnvironment()
        let pool = SeedKanjiDataset.entries

        let mostCommonID = service.selectKanjiID(from: pool, order: .mostCommon, excluding: [], day: "2026-10-28")
        #expect(mostCommonID == "日") // Frequency rank 1

        let listOrderID = service.selectKanjiID(from: pool, order: .listOrder, excluding: [], day: "2026-10-28")
        #expect(listOrderID == "日") // List index 1

        let randomID1 = service.selectKanjiID(from: pool, order: .random, excluding: [], day: "2026-10-28")
        let randomID2 = service.selectKanjiID(from: pool, order: .random, excluding: [], day: "2026-10-28")
        #expect(randomID1 != nil)
        #expect(randomID1 == randomID2) // Pure & deterministic for same day
    }

    @Test("Exhausted pool returns nil for level complete state")
    func levelCompleteReturnsNil() async throws {
        let (_, dayProvider, learnerStore, _) = try makeTestEnvironment()
        let today = dayProvider.calendarDay(for: dayProvider.now)

        // Only 1 kanji in store
        let singleEntry = SeedKanjiDataset.entries[0]
        let smallContentStore = TestKanjiContentStore(entries: [singleEntry])

        let customService = DefaultDailyKanjiService(
            contentStore: smallContentStore,
            learnerStore: learnerStore,
            dayProvider: dayProvider,
            preferencesProvider: { .standard }
        )

        // Assign and complete it
        let assignment = try await customService.assignment(for: today)
        #expect(assignment?.kanjiID == singleEntry.id)
        _ = try await learnerStore.markLearned(day: today)

        // Next day -> pool should now be empty
        dayProvider.advance(byDays: 1)
        let tomorrow = dayProvider.calendarDay(for: dayProvider.now)
        let nextAssignment = try await customService.assignment(for: tomorrow)
        #expect(nextAssignment == nil)
    }

    @Test("Widget snapshot compilation reflects learned state")
    func widgetSnapshotGeneration() async throws {
        let (service, dayProvider, learnerStore, _) = try makeTestEnvironment()
        let today = dayProvider.calendarDay(for: dayProvider.now)

        let initialSnapshot = try await service.widgetSnapshot(for: today)
        #expect(initialSnapshot != nil)
        #expect(initialSnapshot?.kanjiID == "日")
        #expect(initialSnapshot?.isLearned == false)
        #expect(initialSnapshot?.primaryMeaning == "day")

        // Mark learned
        _ = try await learnerStore.markLearned(day: today)

        let learnedSnapshot = try await service.widgetSnapshot(for: today)
        #expect(learnedSnapshot?.isLearned == true)
    }
}
