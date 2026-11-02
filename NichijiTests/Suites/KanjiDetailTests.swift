import Foundation
import Testing
@testable import Nichiji

/*-----------------------------detail-tests-------------------------------*/

@MainActor
@Suite("Kanji Detail Tests")
struct KanjiDetailTests {
    private func makeContainer(
        learnerStore: TestLearnerStore = TestLearnerStore(),
        reviewService: TestReviewService = TestReviewService(),
        scheduler: TestReminderScheduler = TestReminderScheduler()
    ) -> ServiceContainer {
        let dayProvider = TestDayProvider()
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        return ServiceContainer(
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
            reviewService: reviewService
        )
    }

    @Test("Detail loads the entry, stroke paths and stage")
    func loadsContent() async throws {
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries, strokePaths: ["日": ["M1,1", "M2,2"]])
        let learnerStore = TestLearnerStore()
        learnerStore.progress["日"] = .familiar

        let content = try await KanjiDetailContent.load(kanjiID: "日", contentStore: contentStore, learnerStore: learnerStore)

        #expect(content.entry.id == "日")
        #expect(content.strokePaths == ["M1,1", "M2,2"])
        #expect(content.stage == .familiar)
    }

    @Test("Missing strokes and progress only hide their parts")
    func loadsWithoutStrokesOrProgress() async throws {
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)

        let content = try await KanjiDetailContent.load(kanjiID: "日", contentStore: contentStore, learnerStore: TestLearnerStore())

        #expect(content.strokePaths.isEmpty)
        #expect(content.stage == nil)
    }

    @Test("An unknown kanji throws contentMissing")
    func unknownKanjiThrows() async {
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)

        await #expect(throws: NichijiError.self) {
            _ = try await KanjiDetailContent.load(kanjiID: "鬱", contentStore: contentStore, learnerStore: TestLearnerStore())
        }
    }

    @Test("Forget it shows only for kanji past new")
    func forgetItAvailability() {
        #expect(!ForgetItControl.isAvailable(for: nil))
        #expect(!ForgetItControl.isAvailable(for: .new))
        #expect(ForgetItControl.isAvailable(for: .learning))
        #expect(ForgetItControl.isAvailable(for: .familiar))
        #expect(ForgetItControl.isAvailable(for: .known))
    }

    @Test("Forget it resets the kanji, then rebuilds reminders")
    func forgetItRebuildsReminders() async throws {
        let reviewService = TestReviewService()
        let scheduler = TestReminderScheduler()
        let container = makeContainer(reviewService: reviewService, scheduler: scheduler)

        try await container.forgetIt(kanjiID: "日", preferences: .standard)

        #expect(reviewService.forgottenIDs == ["日"])
        #expect(scheduler.rebuildCallCount == 1)
    }

    @Test("A failing reminder rebuild does not fail Forget it")
    func forgetItSurvivesReminderFailure() async throws {
        let reviewService = TestReviewService()
        let scheduler = TestReminderScheduler()
        scheduler.shouldThrowOnRebuild = true
        let container = makeContainer(reviewService: reviewService, scheduler: scheduler)

        try await container.forgetIt(kanjiID: "日", preferences: .standard)

        #expect(reviewService.forgottenIDs == ["日"])
    }

    @Test("A failing reset throws and skips the reminder rebuild")
    func forgetItFailureThrows() async {
        let reviewService = TestReviewService()
        reviewService.shouldThrow = true
        let scheduler = TestReminderScheduler()
        let container = makeContainer(reviewService: reviewService, scheduler: scheduler)

        await #expect(throws: NichijiError.self) {
            try await container.forgetIt(kanjiID: "日", preferences: .standard)
        }
        #expect(scheduler.rebuildCallCount == 0)
    }

    @Test("Detail labels: estimated JLPT levels and Jōyō grades")
    func detailLabels() {
        #expect(DetailsCardView.jlptLabel("n1", isEstimated: true) == "N1 (est.)")
        #expect(DetailsCardView.jlptLabel("n5", isEstimated: false) == "N5")
        #expect(JoyoGrade.grade3.detailsLabel == "3")
        #expect(JoyoGrade.secondary.detailsLabel == "Secondary")
    }
}
