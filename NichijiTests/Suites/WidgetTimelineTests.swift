import Testing
import Foundation
@testable import Nichiji

/*------------------------------widget-tests------------------------------*/

@Suite("WidgetTimeline Tests")
struct WidgetTimelineTests {
    private struct Fixture {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let scheduler = TestReminderScheduler()
        let widgetRefresher = TestWidgetRefresher()
        let contentStore: TestKanjiContentStore
        let preferences: LearnerPreferencesSnapshot

        init(entries: [KanjiEntry] = SeedKanjiDataset.entries, onboarded: Bool = true) {
            contentStore = TestKanjiContentStore(entries: entries)
            preferences = LearnerPreferencesSnapshot(hasCompletedOnboarding: onboarded)
        }

        var today: String { dayProvider.calendarDay(for: dayProvider.now) }

        var service: DefaultDailyKanjiService {
            let preferences = preferences
            return DefaultDailyKanjiService(
                contentStore: contentStore,
                learnerStore: learnerStore,
                dayProvider: dayProvider,
                preferencesProvider: { preferences }
            )
        }

        var builder: DailyKanjiTimelineBuilder {
            let preferences = preferences
            return DailyKanjiTimelineBuilder(
                dailyKanjiService: service,
                dayProvider: dayProvider,
                preferencesProvider: { preferences }
            )
        }

        var environment: WidgetEnvironment {
            let preferences = preferences
            return WidgetEnvironment(
                dayProvider: dayProvider,
                learnerStore: learnerStore,
                dailyKanjiService: service,
                reminderScheduler: scheduler,
                widgetRefresher: widgetRefresher,
                preferencesProvider: { preferences }
            )
        }

        @MainActor
        var services: ServiceContainer {
            ServiceContainer(
                dayProvider: dayProvider,
                contentStore: contentStore,
                learnerStore: learnerStore,
                dailyKanjiService: service,
                pronunciationService: TestPronunciationService(),
                reminderScheduler: scheduler,
                reviewService: TestReviewService(),
                widgetRefresher: widgetRefresher
            )
        }
    }

    @Test("Widget snapshot creates cleanly with default values")
    func snapshotInitialization() {
        let snapshot = DailyKanjiWidgetSnapshot(
            calendarDay: "2026-10-28",
            kanjiID: "学",
            primaryMeaning: "study, learning",
            onyomiKana: ["ガク"],
            kunyomiKana: ["まな"],
            featuredWord: nil,
            isLearned: false
        )
        #expect(snapshot.kanjiID == "学")
        #expect(!snapshot.isLearned)
    }

    /*------------------------------timeline--------------------------------*/

    @Test("An assigned day builds a today entry that reloads at the next midnight")
    func assignedDayEntry() async {
        let fixture = Fixture()

        let plan = await fixture.builder.build()

        guard case .today(let snapshot) = plan.entry.content else {
            Issue.record("Expected a today entry, got \(plan.entry.content)")
            return
        }
        #expect(snapshot.kanjiID == "日")
        #expect(snapshot.primaryMeaning == "day")
        #expect(snapshot.calendarDay == fixture.today)
        #expect(!snapshot.isLearned)
        #expect(plan.entry.date == fixture.dayProvider.now)
        #expect(plan.reloadDate == fixture.dayProvider.nextMidnight(after: fixture.dayProvider.now))
        #expect(plan.timeline().entries.count == 1)
    }

    @Test("A learned day carries the learned flag for the widget")
    func learnedDayEntry() async throws {
        let fixture = Fixture()
        _ = try await fixture.service.assignment(for: fixture.today)
        _ = try await fixture.learnerStore.markLearned(day: fixture.today, nextReviewAt: Date())

        let plan = await fixture.builder.build()

        guard case .today(let snapshot) = plan.entry.content else {
            Issue.record("Expected a today entry, got \(plan.entry.content)")
            return
        }
        #expect(snapshot.isLearned)
    }

    @Test("A completed level builds the quiet placeholder without a today snapshot")
    func levelCompleteEntry() async {
        let fixture = Fixture(entries: [])

        let plan = await fixture.builder.build()

        #expect(plan.entry.content == .levelComplete)
        #expect(plan.reloadDate == fixture.dayProvider.nextMidnight(after: fixture.dayProvider.now))
    }

    @Test("Before onboarding the widget asks to open the app and creates no assignment")
    func unfinishedOnboardingEntry() async {
        let fixture = Fixture(onboarded: false)

        let plan = await fixture.builder.build()

        #expect(plan.entry.content == .openApp)
        #expect(fixture.learnerStore.assignments.isEmpty)
    }

    @Test("A store failure shows the placeholder and retries well before midnight")
    func readFailureRetriesSoon() async {
        let fixture = Fixture()
        fixture.learnerStore.shouldThrow = true

        let plan = await fixture.builder.build()

        #expect(plan.entry.content == .openApp)
        #expect(plan.reloadDate == fixture.dayProvider.now.addingTimeInterval(DailyKanjiTimelineBuilder.retryInterval))
    }

    /*-------------------------------got-it---------------------------------*/

    @Test("Got it marks the day learned, rebuilds reminders, and reloads timelines")
    func gotItUpdatesStoreRemindersAndWidgets() async throws {
        let fixture = Fixture()
        _ = try await fixture.service.assignment(for: fixture.today)

        let assignment = try await GotItAction.perform(
            day: fixture.today,
            preferences: fixture.preferences,
            dayProvider: fixture.dayProvider,
            learnerStore: fixture.learnerStore,
            reminderScheduler: fixture.scheduler,
            widgetRefresher: fixture.widgetRefresher
        )

        #expect(assignment.status == .learned)
        #expect(fixture.learnerStore.assignments[fixture.today]?.status == .learned)
        #expect(fixture.scheduler.rebuildCallCount == 1)
        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    @Test("A reminder failure does not undo Got it or skip the widget reload")
    func gotItSurvivesReminderFailure() async throws {
        let fixture = Fixture()
        fixture.scheduler.shouldThrowOnRebuild = true
        _ = try await fixture.service.assignment(for: fixture.today)

        try await GotItAction.perform(
            day: fixture.today,
            preferences: fixture.preferences,
            dayProvider: fixture.dayProvider,
            learnerStore: fixture.learnerStore,
            reminderScheduler: fixture.scheduler,
            widgetRefresher: fixture.widgetRefresher
        )

        #expect(fixture.learnerStore.assignments[fixture.today]?.status == .learned)
        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    @Test("A widget tap on today's kanji marks it learned")
    func widgetTapMarksTodayLearned() async throws {
        let fixture = Fixture()
        _ = try await fixture.service.assignment(for: fixture.today)

        try await GotItAction.performFromWidget(calendarDay: fixture.today, environment: fixture.environment)

        let kanjiID = try #require(fixture.learnerStore.assignments[fixture.today]?.kanjiID)
        #expect(fixture.learnerStore.assignments[fixture.today]?.status == .learned)
        #expect(fixture.learnerStore.nextReviewAt[kanjiID] == fixture.dayProvider.nextMidnight(after: fixture.dayProvider.now))
        #expect(fixture.scheduler.rebuildCallCount == 1)
        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    @Test("A widget left over from yesterday only reloads and marks nothing")
    func staleWidgetTapOnlyReloads() async throws {
        let fixture = Fixture()
        _ = try await fixture.service.assignment(for: fixture.today)

        try await GotItAction.performFromWidget(calendarDay: "2000-01-01", environment: fixture.environment)

        #expect(fixture.learnerStore.assignments[fixture.today]?.status == .assigned)
        #expect(fixture.scheduler.rebuildCallCount == 0)
        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    /*------------------------------triggers--------------------------------*/

    @Test("A level change reloads widget timelines")
    func levelChangeReloadsWidgets() async throws {
        let fixture = Fixture()

        _ = try await LevelChangeCoordinator.applyLevelChange(
            preferences: fixture.preferences,
            dailyKanjiService: fixture.service,
            dayProvider: fixture.dayProvider,
            reminderScheduler: fixture.scheduler,
            widgetRefresher: fixture.widgetRefresher
        )

        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    @Test("A level change still reloads widgets when the reminder rebuild fails")
    func levelChangeReloadsBeforeReminderFailure() async {
        let fixture = Fixture()
        fixture.scheduler.shouldThrowOnRebuild = true

        _ = try? await LevelChangeCoordinator.applyLevelChange(
            preferences: fixture.preferences,
            dailyKanjiService: fixture.service,
            dayProvider: fixture.dayProvider,
            reminderScheduler: fixture.scheduler,
            widgetRefresher: fixture.widgetRefresher
        )

        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    @MainActor
    @Test("A time-zone change reloads widget timelines")
    func timeZoneChangeReloadsWidgets() async throws {
        let fixture = Fixture()

        try await fixture.services.handleTimeOrZoneChange(preferences: fixture.preferences)

        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    @MainActor
    @Test("Today's Got it reloads widget timelines through the service container")
    func todayGotItReloadsWidgets() async throws {
        let fixture = Fixture()
        _ = try await fixture.service.assignment(for: fixture.today)

        try await fixture.services.markLearned(day: fixture.today, preferences: fixture.preferences)

        #expect(fixture.learnerStore.assignments[fixture.today]?.status == .learned)
        #expect(fixture.widgetRefresher.reloadCount == 1)
    }

    /*--------------------------------copy----------------------------------*/

    @Test("The Add Widget steps are one shared list that names the real menu path")
    func addWidgetCopyIsShared() {
        #expect(AddWidgetCopy.steps.count == 3)
        #expect(AddWidgetCopy.steps.contains { $0.contains("Add Widget") })
        #expect(AddWidgetCopy.steps.contains { $0.contains("Nichiji") })
    }
}
