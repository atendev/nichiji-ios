import Foundation

/*-------------------------------refresher------------------------------------*/

/// Background rebuild path for the reminder window. Never prompts for permission.
enum ReminderRefresher {
    /// Cancels when reminders are off, rebuilds when authorized, and leaves the window alone otherwise.
    static func refresh(
        preferences: LearnerPreferencesSnapshot,
        scheduler: any ReminderScheduler
    ) async throws {
        guard preferences.reminderEnabled else {
            await scheduler.cancelAllReminders()
            return
        }
        guard await scheduler.authorizationStatus() == .authorized else { return }
        try await scheduler.rebuildSchedule(preferences: preferences)
    }
}
