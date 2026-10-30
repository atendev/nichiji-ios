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
        reminderScheduler: any ReminderScheduler
    ) async throws -> DailyAssignmentSnapshot? {
        let day = dayProvider.calendarDay(for: dayProvider.now)
        let assignment = try await dailyKanjiService.refreshAssignmentAfterPreferenceChange(
            for: day,
            preferences: preferences
        )
        try await ReminderRefresher.refresh(preferences: preferences, scheduler: reminderScheduler)
        // TODO: Reload WidgetKit timelines after level or order changes in Slice 11.
        return assignment
    }
}
