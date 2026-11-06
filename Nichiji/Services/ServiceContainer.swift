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

    /// Stats over the learner store; stateless, so it is built from the other services on demand.
    var statsService: any StatsService {
        DefaultStatsService(learnerStore: learnerStore, contentStore: contentStore, dayProvider: dayProvider)
    }

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

    /// A level pick: marks the easier levels known, then re-picks today's kanji. A failed mark never blocks the re-pick.
    @discardableResult
    func applyLevelPick(preferences: LearnerPreferencesSnapshot) async throws -> DailyAssignmentSnapshot? {
        try? await markEasierLevelsKnown(preferences: preferences)
        return try await applyLevelChange(preferences: preferences)
    }

    /// Makes the automatic known marks match the learner's level. Hand marks stay.
    func markEasierLevelsKnown(preferences: LearnerPreferencesSnapshot) async throws {
        guard let ids = AutoKnownLevels.kanjiIDs(in: try contentStore.indexEntries(), preferences: preferences) else { return }
        try await learnerStore.syncAutoKnown(ids, at: dayProvider.now)
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

    /// Returns a kanji to the new stage, then rebuilds reminders so their due-review count stays right.
    func forgetIt(kanjiID: String, preferences: LearnerPreferencesSnapshot) async throws {
        try await reviewService.forgetIt(kanjiID: kanjiID)
        // The reset already saved, so a reminder failure must not surface as a Forget it error.
        try? await rebuildReminders(preferences: preferences)
    }

    /// Marks and unmarks already-known kanji, then refreshes what depends on today's pool.
    /// The store write throws; the reminder rebuild never does. A first run creates no assignment, since Today's rollover picks from the updated pool later.
    func setKnown(declare: Set<String>, undeclare: Set<String>, preferences: LearnerPreferencesSnapshot) async throws {
        guard !declare.isEmpty || !undeclare.isEmpty else { return }
        try await learnerStore.undeclareKnown(undeclare)
        try await learnerStore.declareKnown(declare, at: dayProvider.now)

        let day = dayProvider.calendarDay(for: dayProvider.now)
        if try await learnerStore.assignment(for: day) != nil {
            _ = try await dailyKanjiService.refreshAssignmentAfterPreferenceChange(for: day, preferences: preferences)
        } else if preferences.hasCompletedOnboarding {
            _ = try await dailyKanjiService.assignment(for: day)
        } else {
            return
        }
        widgetRefresher.reloadTimelines()
        try? await rebuildReminders(preferences: preferences)
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
