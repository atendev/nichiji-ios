import Testing
import Foundation
@testable import Nichiji

/*-----------------------------reminder-tests-----------------------------*/

@Suite("ReminderScheduler Tests")
struct ReminderSchedulerTests {
    private static func calendar(_ identifier: String = "UTC") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier) ?? .gmt
        return calendar
    }

    private static func date(
        _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int,
        calendar: Calendar = ReminderSchedulerTests.calendar()
    ) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? .distantPast
    }

    private static func plans(
        now: Date,
        today: ReminderTodayState,
        calendar: Calendar = ReminderSchedulerTests.calendar()
    ) -> [ReminderPlan] {
        ReminderPlanBuilder.plans(now: now, calendar: calendar, hour: 8, minute: 0, today: today)
    }

    @Test("The window holds 7 requests with one unique identifier per day")
    func windowHoldsSevenUniqueDays() {
        let result = Self.plans(now: Self.date(2026, 3, 10, 7, 0), today: .assigned(kanji: "日"))

        #expect(result.count == ReminderPlanBuilder.windowSize)
        #expect(Set(result.map(\.identifier)).count == 7)
        #expect(result.allSatisfy { $0.identifier.hasPrefix(ReminderPlanBuilder.identifierPrefix) })
    }

    /*--------------------------------planner---------------------------------*/

    @Test("Time ahead and unlearned today gives kanji-led copy first, then six generic days")
    func timeAheadAssignedIsKanjiLed() {
        let result = Self.plans(now: Self.date(2026, 3, 10, 7, 0), today: .assigned(kanji: "日"))

        #expect(result.count == 7)
        #expect(result[0].identifier == "nichiji.reminder.2026-03-10")
        #expect(result[0].copy == .kanjiLed("日"))
        #expect(result[0].copy.body == "日 · Today's kanji is ready")
        #expect(result.dropFirst().allSatisfy { $0.copy == .generic })
        #expect(result[6].identifier == "nichiji.reminder.2026-03-16")
    }

    @Test("Time ahead and learned today skips today and starts tomorrow with generic copy")
    func timeAheadLearnedSkipsToday() {
        let result = Self.plans(now: Self.date(2026, 3, 10, 7, 0), today: .learned)

        #expect(result.count == 7)
        #expect(result[0].identifier == "nichiji.reminder.2026-03-11")
        #expect(result.allSatisfy { $0.copy == .generic })
    }

    @Test("Time passed and unlearned today starts tomorrow with missed-day copy")
    func timePassedAssignedIsMissedDay() {
        let result = Self.plans(now: Self.date(2026, 3, 10, 9, 30), today: .assigned(kanji: "日"))

        #expect(result[0].identifier == "nichiji.reminder.2026-03-11")
        #expect(result[0].copy == .missedDay)
        #expect(result[0].copy.body == "You missed yesterday's kanji. That's okay, check it now.")
        #expect(result.dropFirst().allSatisfy { $0.copy == .generic })
    }

    @Test("Time passed and learned today starts tomorrow with generic copy")
    func timePassedLearnedIsGeneric() {
        let result = Self.plans(now: Self.date(2026, 3, 10, 9, 30), today: .learned)

        #expect(result[0].identifier == "nichiji.reminder.2026-03-11")
        #expect(result.allSatisfy { $0.copy == .generic })
    }

    @Test("A reminder time equal to now counts as passed")
    func timeEqualToNowCountsAsPassed() {
        let result = Self.plans(now: Self.date(2026, 3, 10, 8, 0), today: .assigned(kanji: "日"))

        #expect(result[0].identifier == "nichiji.reminder.2026-03-11")
        #expect(result[0].copy == .missedDay)
    }

    @Test("The window rolls over month and year boundaries")
    func windowRollsOverMonthAndYear() {
        let result = Self.plans(now: Self.date(2026, 12, 29, 9, 0), today: .learned)

        #expect(result.map(\.identifier) == [
            "nichiji.reminder.2026-12-30",
            "nichiji.reminder.2026-12-31",
            "nichiji.reminder.2027-01-01",
            "nichiji.reminder.2027-01-02",
            "nichiji.reminder.2027-01-03",
            "nichiji.reminder.2027-01-04",
            "nichiji.reminder.2027-01-05"
        ])
        #expect(result[2].fireComponents.year == 2027)
        #expect(result[2].fireComponents.month == 1)
    }

    @Test("Fire components carry the chosen hour and minute, clamped to valid ranges")
    func fireComponentsUseChosenTime() {
        let now = Self.date(2026, 3, 10, 7, 0)
        let custom = ReminderPlanBuilder.plans(
            now: now, calendar: Self.calendar(), hour: 20, minute: 45, today: .learned
        )
        #expect(custom.allSatisfy { $0.fireComponents.hour == 20 && $0.fireComponents.minute == 45 })

        let clamped = ReminderPlanBuilder.plans(
            now: now, calendar: Self.calendar(), hour: 99, minute: -5, today: .learned
        )
        #expect(clamped.allSatisfy { $0.fireComponents.hour == 23 && $0.fireComponents.minute == 0 })
    }

    @Test("The learner's time zone decides whether today's time is still ahead")
    func timeZoneShiftsFireDates() {
        // 2026-03-10 23:30 UTC is already 08:30 on 11 March in Tokyo, so 8:00 has passed there.
        let instant = Self.date(2026, 3, 10, 23, 30)
        let utc = Self.plans(now: instant, today: .assigned(kanji: "日"))
        let tokyo = Self.plans(
            now: instant,
            today: .assigned(kanji: "日"),
            calendar: Self.calendar("Asia/Tokyo")
        )

        #expect(utc[0].identifier == "nichiji.reminder.2026-03-11")
        #expect(utc[0].copy == .missedDay)
        #expect(tokyo[0].identifier == "nichiji.reminder.2026-03-12")
        #expect(tokyo[0].copy == .missedDay)
    }

    /*-------------------------------refresher--------------------------------*/

    @Test("Refresh cancels when reminders are off and never rebuilds")
    func refreshCancelsWhenDisabled() async throws {
        let scheduler = TestReminderScheduler()
        var prefs = LearnerPreferencesSnapshot.standard
        prefs.reminderEnabled = false

        try await ReminderRefresher.refresh(preferences: prefs, scheduler: scheduler)

        #expect(scheduler.didCancelAll)
        #expect(scheduler.rebuildCallCount == 0)
    }

    @Test("Refresh rebuilds when authorized")
    func refreshRebuildsWhenAuthorized() async throws {
        let scheduler = TestReminderScheduler()
        scheduler.stubbedAuthorizationStatus = .authorized

        try await ReminderRefresher.refresh(preferences: .standard, scheduler: scheduler)

        #expect(scheduler.rebuildCallCount == 1)
        #expect(scheduler.didCancelAll == false)
    }

    @Test("Refresh leaves the window alone when permission is denied or undecided, and never prompts")
    func refreshDoesNothingWithoutPermission() async throws {
        for status in [ReminderAuthorizationStatus.denied, .notDetermined] {
            let scheduler = TestReminderScheduler()
            scheduler.stubbedAuthorizationStatus = status

            try await ReminderRefresher.refresh(preferences: .standard, scheduler: scheduler)

            #expect(scheduler.rebuildCallCount == 0)
            #expect(scheduler.didCancelAll == false)
            #expect(scheduler.requestAuthorizationCallCount == 0)
        }
    }

    @Test("Denied permission neither rebuilds nor cancels pending reminders")
    func deniedPermissionPreservesToggle() async throws {
        let scheduler = TestReminderScheduler()
        scheduler.stubbedAuthorizationStatus = .denied
        var prefs = LearnerPreferencesSnapshot.standard
        prefs.reminderEnabled = true

        try await ReminderSettingsCoordinator.applyReminderPreferences(prefs, scheduler: scheduler)

        #expect(scheduler.rebuildCallCount == 0)
        #expect(scheduler.didCancelAll == false)
    }

    /*-------------------------------triggers---------------------------------*/

    @Test("A level change rebuilds the reminder window once")
    func levelChangeRebuildsReminders() async throws {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let service = DefaultDailyKanjiService(
            contentStore: TestKanjiContentStore(entries: SeedKanjiDataset.entries),
            learnerStore: learnerStore,
            dayProvider: dayProvider
        )
        let scheduler = TestReminderScheduler()

        _ = try await LevelChangeCoordinator.applyLevelChange(
            preferences: .standard,
            dailyKanjiService: service,
            dayProvider: dayProvider,
            reminderScheduler: scheduler,
            widgetRefresher: TestWidgetRefresher()
        )

        #expect(scheduler.rebuildCallCount == 1)
    }

    @MainActor
    @Test("A time-zone change reruns rollover and rebuilds the window")
    func timeZoneChangeRebuildsReminders() async throws {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: learnerStore,
            dayProvider: dayProvider
        )
        let scheduler = TestReminderScheduler()
        let container = ServiceContainer(
            dayProvider: dayProvider,
            contentStore: contentStore,
            learnerStore: learnerStore,
            dailyKanjiService: service,
            pronunciationService: TestPronunciationService(),
            reminderScheduler: scheduler
        )

        try await container.handleTimeOrZoneChange(preferences: .standard)

        #expect(scheduler.rebuildCallCount == 1)
        #expect(learnerStore.assignments[dayProvider.calendarDay(for: dayProvider.now)] != nil)
    }

    @MainActor
    @Test("A failing reminder rebuild does not fail the time-zone refresh")
    func reminderFailureDoesNotFailTimeZoneRefresh() async throws {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        let scheduler = TestReminderScheduler()
        scheduler.shouldThrowOnRebuild = true
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
            reminderScheduler: scheduler
        )

        try await container.handleTimeOrZoneChange(preferences: .standard)

        #expect(scheduler.rebuildCallCount == 1)
    }
}
