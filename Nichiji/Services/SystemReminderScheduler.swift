import UserNotifications

/*------------------------------system-scheduler------------------------------*/

/// Live notification permission handling. Scheduling and cancelling arrive in Slice 10.
struct SystemReminderScheduler: ReminderScheduler {
    func authorizationStatus() async -> ReminderAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    func requestAuthorization() async throws -> Bool {
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        guard granted else { throw NichijiError.notificationsDenied }
        return true
    }

    // TODO: Slice 10 schedules the rolling 7-day window here.
    func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws {}

    // TODO: Slice 10 removes pending Nichiji requests here.
    func cancelAllReminders() async {}
}
