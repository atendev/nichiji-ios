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

    // TODO: Re-run DailyKanjiService.assignment(for:), rebuild ReminderScheduler, and reload WidgetCenter timelines when NSSystemTimeZoneDidChange or significantTimeChange fires.
    /// Refreshes rollover state, the 7-day notification window, and widget timelines after clock or time-zone changes.
    func handleTimeOrZoneChange(preferences: LearnerPreferencesSnapshot) async throws {
    }
}
