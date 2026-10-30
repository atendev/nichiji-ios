import Foundation

/*---------------------------level-change---------------------------------*/

/// Shared reassignment path for level, order, and custom pool changes from Settings and onboarding replay.
enum LevelChangeCoordinator {
    /// Re-picks today's kanji from the updated pool, leaving a `.learned` assignment untouched.
    @discardableResult
    static func applyLevelChange(
        preferences: LearnerPreferencesSnapshot,
        dailyKanjiService: any DailyKanjiService,
        dayProvider: any DayProvider,
        reminderScheduler: any ReminderScheduler,
        widgetRefresher: any WidgetRefresher
    ) async throws -> DailyAssignmentSnapshot? {
        let day = dayProvider.calendarDay(for: dayProvider.now)
        let assignment = try await dailyKanjiService.refreshAssignmentAfterPreferenceChange(
            for: day,
            preferences: preferences
        )
        // Reload before the reminder rebuild so a reminder failure cannot leave the widget on the old kanji.
        widgetRefresher.reloadTimelines()
        try await ReminderRefresher.refresh(preferences: preferences, scheduler: reminderScheduler)
        return assignment
    }
}
