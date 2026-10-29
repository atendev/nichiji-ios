import Foundation

/*---------------------------level-change---------------------------------*/

/// Shared reassignment path for level, order, and custom pool changes from Settings and onboarding replay.
enum LevelChangeCoordinator {
    /// Re-picks today's kanji from the updated pool, leaving a `.learned` assignment untouched.
    @discardableResult
    static func applyLevelChange(
        preferences: LearnerPreferencesSnapshot,
        dailyKanjiService: any DailyKanjiService,
        dayProvider: any DayProvider
    ) async throws -> DailyAssignmentSnapshot? {
        let day = dayProvider.calendarDay(for: dayProvider.now)
        // TODO: Rebuild reminder notification schedule and reload WidgetKit timelines after level or order changes in Slices 10 and 11.
        return try await dailyKanjiService.refreshAssignmentAfterPreferenceChange(
            for: day,
            preferences: preferences
        )
    }
}
