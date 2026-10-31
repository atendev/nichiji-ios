import SwiftUI

/*--------------------------------structs-------------------------------------*/

/// Dependency container injected into the SwiftUI environment for app and test targets.
struct ServiceContainer: Sendable {
    let dayProvider: any DayProvider
    let contentStore: any KanjiContentStore
    let learnerStore: any LearnerStore
    let dailyKanjiService: any DailyKanjiService
    let pronunciationService: any PronunciationService
    let reminderScheduler: any ReminderScheduler
    let reviewService: any ReviewService
    var widgetRefresher: any WidgetRefresher = NoopWidgetRefresher()

    /// Refreshes Today rollover state and the reminder window after a clock or time-zone change.
    func handleTimeOrZoneChange(preferences: LearnerPreferencesSnapshot) async throws {
        _ = try await dailyKanjiService.assignment(for: dayProvider.calendarDay(for: dayProvider.now))
        // A reminder failure must not surface as a Today error after a successful rollover.
        try? await rebuildReminders(preferences: preferences)
        widgetRefresher.reloadTimelines()
    }

    /// Re-picks today's kanji after a level, order, or pool change, then rebuilds reminders and reloads widgets.
    @discardableResult
    func applyLevelChange(preferences: LearnerPreferencesSnapshot) async throws -> DailyAssignmentSnapshot? {
        try await LevelChangeCoordinator.applyLevelChange(
            preferences: preferences,
            dailyKanjiService: dailyKanjiService,
            dayProvider: dayProvider,
            reminderScheduler: reminderScheduler,
            widgetRefresher: widgetRefresher
        )
    }

    /// Marks the day learned, then rebuilds reminders and reloads widget timelines.
    @discardableResult
    func markLearned(day: String, preferences: LearnerPreferencesSnapshot) async throws -> DailyAssignmentSnapshot {
        try await GotItAction.perform(
            day: day,
            preferences: preferences,
            dayProvider: dayProvider,
            learnerStore: learnerStore,
            effects: GotItEffects(reminderScheduler: reminderScheduler, widgetRefresher: widgetRefresher)
        )
    }

    /// Rebuilds or cancels the reminder window without ever prompting for permission.
    func rebuildReminders(preferences: LearnerPreferencesSnapshot) async throws {
        try await ReminderRefresher.refresh(preferences: preferences, scheduler: reminderScheduler)
    }
}

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer? = nil
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer? {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

struct NoopReminderScheduler: ReminderScheduler {
    func authorizationStatus() async -> ReminderAuthorizationStatus { .notDetermined }

    func requestAuthorization() async throws -> Bool { false }

    func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws {}

    func cancelAllReminders() async {}
}
