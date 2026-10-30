import Foundation

/*---------------------------------enums--------------------------------------*/

/// System notification permission state surfaced in onboarding and reminder settings.
enum ReminderAuthorizationStatus: String, Codable, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
}

/*-------------------------------protocols------------------------------------*/

/// Schedules and refreshes the rolling 7-day window of local reminder notifications.
protocol ReminderScheduler: Sendable {
    /// Queries the current system notification permission status without prompting.
    func authorizationStatus() async -> ReminderAuthorizationStatus

    /// Requests notification permission from the learner when enabling reminders.
    func requestAuthorization() async throws -> Bool

    /// Rebuilds the rolling 7-day window of pending daily reminder notifications.
    func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws

    /// Cancels all pending Nichiji reminder requests when the learner turns reminders off.
    func cancelAllReminders() async
}
