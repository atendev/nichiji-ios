import Foundation
import UserNotifications

/*------------------------------system-scheduler------------------------------*/

/// Live scheduler backed by `UNUserNotificationCenter`.
struct SystemReminderScheduler: ReminderScheduler {
    private let dailyKanjiService: any DailyKanjiService
    private let dayProvider: any DayProvider

    init(dailyKanjiService: any DailyKanjiService, dayProvider: any DayProvider) {
        self.dailyKanjiService = dailyKanjiService
        self.dayProvider = dayProvider
    }

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

    func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws {
        let now = dayProvider.now
        let day = dayProvider.calendarDay(for: now)

        // With no assignment the level is complete, so there is nothing to remind about.
        guard let assignment = try await dailyKanjiService.assignment(for: day) else {
            await cancelAllReminders()
            return
        }

        let today: ReminderTodayState = assignment.status == .learned
            ? .learned
            : .assigned(kanji: assignment.kanjiID)
        let plans = ReminderPlanBuilder.plans(
            now: now,
            calendar: dayProvider.calendar,
            hour: preferences.reminderHour,
            minute: preferences.reminderMinute,
            today: today
        )

        // Add first, then prune, so the learner is never left with an empty window.
        let center = UNUserNotificationCenter.current()
        for plan in plans {
            try await center.add(Self.request(for: plan))
        }
        await removePendingReminders(keeping: Set(plans.map(\.identifier)))
    }

    func cancelAllReminders() async {
        await removePendingReminders(keeping: [])
    }

    /*-------------------------------helpers--------------------------------*/

    private func removePendingReminders(keeping kept: Set<String>) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter {
            $0.hasPrefix(ReminderPlanBuilder.identifierPrefix) && !kept.contains($0)
        }
        center.removePendingNotificationRequests(withIdentifiers: stale)
    }

    private static func request(for plan: ReminderPlan) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Nichiji"
        content.body = plan.copy.body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: plan.fireComponents, repeats: false)
        return UNNotificationRequest(identifier: plan.identifier, content: content, trigger: trigger)
    }
}
