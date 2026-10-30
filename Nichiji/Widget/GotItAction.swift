import Foundation

/*---------------------------------got-it-------------------------------------*/

/// Shared Got it path for Today and the interactive widget.
enum GotItAction {
    /// Marks the day learned, rebuilds the reminder window, and reloads widget timelines.
    @discardableResult
    static func perform(
        day: String,
        preferences: LearnerPreferencesSnapshot,
        learnerStore: any LearnerStore,
        reminderScheduler: any ReminderScheduler,
        widgetRefresher: any WidgetRefresher
    ) async throws -> DailyAssignmentSnapshot {
        let assignment = try await learnerStore.markLearned(day: day)
        // A reminder failure must not undo a successful Got it.
        try? await ReminderRefresher.refresh(preferences: preferences, scheduler: reminderScheduler)
        widgetRefresher.reloadTimelines()
        return assignment
    }

    /// Handles a widget tap. A widget left over from yesterday only refreshes, so a kanji the learner never saw is not marked.
    static func performFromWidget(calendarDay: String, environment: WidgetEnvironment) async throws {
        let today = environment.dayProvider.calendarDay(for: environment.dayProvider.now)
        guard calendarDay == today else {
            environment.widgetRefresher.reloadTimelines()
            return
        }
        try await perform(
            day: today,
            preferences: environment.preferencesProvider(),
            learnerStore: environment.learnerStore,
            reminderScheduler: environment.reminderScheduler,
            widgetRefresher: environment.widgetRefresher
        )
    }
}
