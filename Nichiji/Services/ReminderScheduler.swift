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
    // TODO: Read UNUserNotificationCenter notificationSettings and map authorizationStatus to ReminderAuthorizationStatus.
    /// Queries the current system notification permission status without prompting.
    func authorizationStatus() async -> ReminderAuthorizationStatus

    // TODO: Request alert and sound authorization from UNUserNotificationCenter, throwing NichijiError.notificationsDenied if denied.
    /// Requests notification permission from the learner when enabling reminders.
    func requestAuthorization() async throws -> Bool

    // TODO: Schedule up to 7 daily requests where the next fire uses kanji-led or missed-day copy based on today's assignment status and days 2 through 7 use generic copy.
    /// Rebuilds the rolling 7-day window of pending daily reminder notifications.
    func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws

    // TODO: Remove pending notification requests created by Nichiji from UNUserNotificationCenter.
    /// Cancels all pending Nichiji reminder requests when the learner turns reminders off.
    func cancelAllReminders() async
}
