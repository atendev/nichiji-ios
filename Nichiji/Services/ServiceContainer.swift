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

    /// Refreshes Today rollover state after a clock or time-zone change.
    func handleTimeOrZoneChange(preferences: LearnerPreferencesSnapshot) async throws {
        _ = try await dailyKanjiService.assignment(for: dayProvider.calendarDay(for: dayProvider.now))
        // Reminder and WidgetKit rebuilds remain deferred to their dedicated slices.
    }
}

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer? = nil
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer? {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

struct NoopReminderScheduler: ReminderScheduler {
    func authorizationStatus() async -> ReminderAuthorizationStatus { .notDetermined }

    func requestAuthorization() async throws -> Bool { false }

    func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws {}

    func cancelAllReminders() async {}
}
