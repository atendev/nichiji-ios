import Foundation

/*---------------------------------got-it-------------------------------------*/

/// Side effects that follow a successful Got it.
struct GotItEffects: Sendable {
    let reminderScheduler: any ReminderScheduler
    let widgetRefresher: any WidgetRefresher
}

/// Shared Got it path for Today and the interactive widget.
enum GotItAction {
    /// Marks the day learned with its first review due tomorrow, rebuilds the reminder window, and reloads widget timelines.
    @discardableResult
    static func perform(
        day: String,
        preferences: LearnerPreferencesSnapshot,
        dayProvider: any DayProvider,
        learnerStore: any LearnerStore,
        effects: GotItEffects
    ) async throws -> DailyAssignmentSnapshot {
        let nextReviewAt = ReviewScheduler.firstReviewDate(learnedOn: dayProvider.now, calendar: dayProvider.calendar)
        let assignment = try await learnerStore.markLearned(day: day, nextReviewAt: nextReviewAt)
        // A reminder failure must not undo a successful Got it.
        try? await ReminderRefresher.refresh(preferences: preferences, scheduler: effects.reminderScheduler)
        effects.widgetRefresher.reloadTimelines()
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
            dayProvider: environment.dayProvider,
            learnerStore: environment.learnerStore,
            effects: GotItEffects(reminderScheduler: environment.reminderScheduler, widgetRefresher: environment.widgetRefresher)
        )
    }
}
