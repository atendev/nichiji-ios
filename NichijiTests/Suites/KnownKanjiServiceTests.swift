import Foundation
import Testing
@testable import Nichiji

/*------------------------------known-service-----------------------------*/

@Suite("Known Kanji Service Tests")
struct KnownKanjiServiceTests {
    private struct Rig {
        let container: ServiceContainer
        let learnerStore: TestLearnerStore
        let widgets: TestWidgetRefresher
        let scheduler: TestReminderScheduler
        let day: String
    }

    private func makeRig(entries: [KanjiEntry] = SeedKanjiDataset.entries) -> Rig {
        let dayProvider = TestDayProvider()
        let contentStore = TestKanjiContentStore(entries: entries)
        let learnerStore = TestLearnerStore()
        let widgets = TestWidgetRefresher()
        let scheduler = TestReminderScheduler()
        let container = ServiceContainer(
            dayProvider: dayProvider,
            contentStore: contentStore,
            learnerStore: learnerStore,
            dailyKanjiService: DefaultDailyKanjiService(
                contentStore: contentStore,
                learnerStore: learnerStore,
                dayProvider: dayProvider
            ),
            pronunciationService: TestPronunciationService(),
            reminderScheduler: scheduler,
            reviewService: TestReviewService(),
            widgetRefresher: widgets
        )
        return Rig(
            container: container,
            learnerStore: learnerStore,
            widgets: widgets,
            scheduler: scheduler,
            day: dayProvider.calendarDay(for: dayProvider.now)
        )
    }

    private func completed() -> LearnerPreferencesSnapshot {
        var preferences = LearnerPreferencesSnapshot.standard
        preferences.hasCompletedOnboarding = true
        return preferences
    }

    @Test("A first run marks kanji without creating an assignment or touching widgets and reminders")
    func firstRunCreatesNothing() async throws {
        let rig = makeRig()

        try await rig.container.setKnown(declare: ["日"], undeclare: [], preferences: .standard)

        #expect(rig.learnerStore.declaredKnown == ["日"])
        #expect(rig.learnerStore.assignments.isEmpty)
        #expect(rig.widgets.reloadCount == 0)
        #expect(rig.scheduler.rebuildCallCount == 0)
    }

    @Test("After onboarding, marking with no assignment rolls today over from the updated pool")
    func completedOnboardingRollsOver() async throws {
        let rig = makeRig()

        try await rig.container.setKnown(declare: ["日"], undeclare: [], preferences: completed())

        let assignment = try #require(rig.learnerStore.assignments[rig.day])
        #expect(assignment.kanjiID != "日")
        #expect(rig.widgets.reloadCount == 1)
        #expect(rig.scheduler.rebuildCallCount == 1)
    }

    @Test("Marking today's unlearned kanji re-picks today's kanji")
    func marksTodaysKanji() async throws {
        let rig = makeRig()
        _ = try await rig.learnerStore.createAssignment(calendarDay: rig.day, kanjiID: "日", assignedAt: Date())

        try await rig.container.setKnown(declare: ["日"], undeclare: [], preferences: completed())

        let assignment = try #require(rig.learnerStore.assignments[rig.day])
        #expect(assignment.kanjiID != "日")
    }

    @Test("Unmarking a kanji after a whole level was marked brings Today back")
    func unmarkRestoresToday() async throws {
        let rig = makeRig()
        for entry in SeedKanjiDataset.entries {
            rig.learnerStore.progress[entry.id] = .known
            rig.learnerStore.declaredKnown.insert(entry.id)
        }

        try await rig.container.setKnown(declare: [], undeclare: ["日"], preferences: completed())

        #expect(rig.learnerStore.assignments[rig.day]?.kanjiID == "日")
    }

    @Test("An empty change writes and refreshes nothing")
    func emptyChangeIsANoOp() async throws {
        let rig = makeRig()

        try await rig.container.setKnown(declare: [], undeclare: [], preferences: completed())

        #expect(rig.learnerStore.assignments.isEmpty)
        #expect(rig.widgets.reloadCount == 0)
        #expect(rig.scheduler.rebuildCallCount == 0)
    }

    @Test("A failing reminder rebuild does not fail the mark")
    func reminderFailureIsSwallowed() async throws {
        let rig = makeRig()
        rig.scheduler.shouldThrowOnRebuild = true

        try await rig.container.setKnown(declare: ["日"], undeclare: [], preferences: completed())

        #expect(rig.learnerStore.declaredKnown == ["日"])
    }

    @Test("A declared kanji is skipped by the daily pool")
    func poolSkipsDeclared() async throws {
        let rig = makeRig()
        let service = DefaultDailyKanjiService(
            contentStore: TestKanjiContentStore(entries: SeedKanjiDataset.entries),
            learnerStore: rig.learnerStore,
            dayProvider: TestDayProvider()
        )
        let before = try await service.activePool(preferences: .standard).map(\.id)
        try await rig.learnerStore.declareKnown(["日"], at: Date())
        let after = try await service.activePool(preferences: .standard).map(\.id)

        #expect(before.contains("日"))
        #expect(!after.contains("日"))
    }

    @Test("TestLearnerStore clears its declared set the way the real store does")
    func doubleMatchesStore() async throws {
        let store = TestLearnerStore()
        try await store.declareKnown(["山", "川"], at: Date())
        try await store.forgetIt(kanjiID: "山", calendarDay: "2026-10-28")
        try await store.undeclareKnown(["川"])

        #expect(try await store.declaredKnownIDs().isEmpty)
        #expect(store.progress["山"] == .new)
        #expect(store.progress["川"] == .new)
    }

    /*------------------------------level-pick------------------------------*/

    private static func leveled(_ id: String, _ level: JLPTLevel, listIndex: Int) -> KanjiEntry {
        KanjiEntry(
            id: id,
            meanings: [id],
            onyomi: [],
            kunyomi: [],
            radical: KanjiRadical(character: id, meaning: id),
            strokeCount: 1,
            jlptLevel: level,
            joyoGrade: nil,
            frequencyRank: nil,
            listIndex: listIndex,
            exampleWords: []
        )
    }

    private static let ladder = [
        leveled("日", .n5, listIndex: 0),
        leveled("月", .n5, listIndex: 1),
        leveled("会", .n4, listIndex: 2),
        leveled("社", .n4, listIndex: 3),
        leveled("新", .n3, listIndex: 4)
    ]

    @Test("A level pick marks the easier levels, and moving down frees automatic marks but keeps hand marks")
    func levelPickSyncsAutomaticMarks() async throws {
        let rig = makeRig(entries: Self.ladder)
        try await rig.learnerStore.declareKnown(["社"], at: Date())
        var preferences = completed()
        preferences.selectedJLPTLevel = .n3

        try await rig.container.applyLevelPick(preferences: preferences)

        #expect(rig.learnerStore.declaredKnown == ["日", "月", "会", "社"])
        #expect(rig.learnerStore.autoKnown == ["日", "月", "会"])
        #expect(rig.learnerStore.assignments[rig.day]?.kanjiID == "新")

        preferences.selectedJLPTLevel = .n4
        try await rig.container.applyLevelPick(preferences: preferences)

        #expect(rig.learnerStore.declaredKnown == ["日", "月", "社"])
        #expect(rig.learnerStore.progress["会"] == .new)
        #expect(rig.learnerStore.assignments[rig.day]?.kanjiID == "会")
    }

    @Test("A daily order change is not a level pick and marks nothing")
    func levelChangeLeavesMarks() async throws {
        let rig = makeRig(entries: Self.ladder)
        var preferences = completed()
        preferences.selectedJLPTLevel = .n3

        try await rig.container.applyLevelChange(preferences: preferences)

        #expect(rig.learnerStore.declaredKnown.isEmpty)
    }
}
