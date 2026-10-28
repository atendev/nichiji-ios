import Testing
import SwiftData
import Foundation
@testable import Nichiji

/*-----------------------------learner-tests------------------------------*/

@Suite("LearnerStore Tests")
struct LearnerStoreTests {
    private func makeInMemoryStore() throws -> SwiftDataLearnerStore {
        let schema = Schema([
            KanjiProgress.self,
            DailyAssignment.self,
            CustomKanjiSelection.self,
            StudyLogEntry.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return SwiftDataLearnerStore(modelContainer: container)
    }

    @Test("Learner models initialize cleanly in memory")
    func inMemoryContainerSetup() throws {
        let schema = Schema([
            KanjiProgress.self,
            DailyAssignment.self,
            CustomKanjiSelection.self,
            StudyLogEntry.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        #expect(container.schema.entities.count == 4)
    }

    @Test("Creating and fetching a daily assignment")
    func assignmentCreationAndFetch() async throws {
        let store = try makeInMemoryStore()
        let created = try await store.createAssignment(
            calendarDay: "2026-10-28",
            kanjiID: "日",
            assignedAt: Date()
        )

        #expect(created.calendarDay == "2026-10-28")
        #expect(created.kanjiID == "日")
        #expect(created.status == .assigned)

        let fetched = try await store.assignment(for: "2026-10-28")
        #expect(fetched != nil)
        #expect(fetched?.kanjiID == "日")
        #expect(fetched?.status == .assigned)
    }

    @Test("Marking an assignment learned advances progress to learning and logs entry")
    func markLearnedAdvancesProgressAndLogs() async throws {
        let store = try makeInMemoryStore()
        _ = try await store.createAssignment(
            calendarDay: "2026-10-28",
            kanjiID: "学",
            assignedAt: Date()
        )

        let updated = try await store.markLearned(day: "2026-10-28")
        #expect(updated.status == .learned)
        #expect(updated.completedAt != nil)

        let nonNew = try await store.nonNewKanjiIDs()
        #expect(nonNew.contains("学"))
    }

    @Test("Past unlearned assignments transition to missed while keeping stage new")
    func pastAssignedMarkedAsMissed() async throws {
        let store = try makeInMemoryStore()
        _ = try await store.createAssignment(
            calendarDay: "2026-10-26",
            kanjiID: "山",
            assignedAt: Date()
        )
        _ = try await store.createAssignment(
            calendarDay: "2026-10-27",
            kanjiID: "川",
            assignedAt: Date()
        )

        let missed = try await store.markPastAssignedAsMissed(before: "2026-10-28")
        #expect(missed.count == 2)
        #expect(missed.allSatisfy { $0.status == .missed })

        // Invariant: Missed kanji must NOT be counted as non-new (they stay in the unlearned pool).
        let nonNew = try await store.nonNewKanjiIDs()
        #expect(!nonNew.contains("山"))
        #expect(!nonNew.contains("川"))
    }

    @Test("forgetIt resets progress stage back to new")
    func forgetItResetsStageToNew() async throws {
        let store = try makeInMemoryStore()
        _ = try await store.createAssignment(calendarDay: "2026-10-28", kanjiID: "木", assignedAt: Date())
        _ = try await store.markLearned(day: "2026-10-28")

        var nonNew = try await store.nonNewKanjiIDs()
        #expect(nonNew.contains("木"))

        try await store.forgetIt(kanjiID: "木")
        nonNew = try await store.nonNewKanjiIDs()
        #expect(!nonNew.contains("木"))
    }

    @Test("Custom selection persists and retrieves accurately")
    func customSelectionPersistence() async throws {
        let store = try makeInMemoryStore()
        let selection: Set<String> = ["日", "月", "火"]

        try await store.setCustomSelection(selection, levelSystem: .jlpt)
        let retrieved = try await store.customSelectionIDs(for: .jlpt)

        #expect(retrieved == selection)

        // Overwrite custom selection.
        let newSelection: Set<String> = ["水", "木"]
        try await store.setCustomSelection(newSelection, levelSystem: .jlpt)
        let updated = try await store.customSelectionIDs(for: .jlpt)

        #expect(updated == newSelection)
    }

    @Test("reassignToday replaces unlearned assignment but preserves learned assignment")
    func reassignTodayPreservesLearned() async throws {
        let store = try makeInMemoryStore()
        let entry1 = KanjiEntry(
            id: "一",
            meanings: ["one"],
            onyomi: [],
            kunyomi: [],
            radical: KanjiRadical(character: "一", meaning: "one"),
            strokeCount: 1,
            strokePaths: [],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 2,
            listIndex: 2,
            exampleWords: []
        )
        let entry2 = KanjiEntry(
            id: "二",
            meanings: ["two"],
            onyomi: [],
            kunyomi: [],
            radical: KanjiRadical(character: "二", meaning: "two"),
            strokeCount: 2,
            strokePaths: [],
            jlptLevel: .n5,
            joyoGrade: .grade1,
            frequencyRank: 9,
            listIndex: 3,
            exampleWords: []
        )

        _ = try await store.createAssignment(calendarDay: "2026-10-28", kanjiID: "一", assignedAt: Date())

        // Reassign while still .assigned -> should swap to entry2.
        let swapped = try await store.reassignToday(day: "2026-10-28", from: [entry2])
        #expect(swapped?.kanjiID == "二")

        // Mark learned.
        _ = try await store.markLearned(day: "2026-10-28")

        // Try reassigning when learned -> must NOT overwrite learned kanji.
        let afterLearned = try await store.reassignToday(day: "2026-10-28", from: [entry1])
        #expect(afterLearned?.kanjiID == "二")
        #expect(afterLearned?.status == .learned)
    }
}
