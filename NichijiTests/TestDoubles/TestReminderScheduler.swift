import Foundation
@testable import Nichiji

/*----------------------------test-reminders------------------------------*/

final class TestReminderScheduler: ReminderScheduler, @unchecked Sendable {
    var stubbedAuthorizationStatus: ReminderAuthorizationStatus = .authorized
    var scheduledRequestsCount: Int = 0
    var lastRebuiltPreferences: LearnerPreferencesSnapshot?
    var didCancelAll: Bool = false
    var requestAuthorizationCallCount: Int = 0
    var rebuildCallCount: Int = 0
    var shouldThrowOnRebuild: Bool = false

    func authorizationStatus() async -> ReminderAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCallCount += 1
        if stubbedAuthorizationStatus == .denied {
            throw NichijiError.notificationsDenied
        }
        return stubbedAuthorizationStatus == .authorized
    }

    func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws {
        rebuildCallCount += 1
        if shouldThrowOnRebuild { throw NichijiError.notificationsDenied }
        lastRebuiltPreferences = preferences
        scheduledRequestsCount = 7
    }

    func cancelAllReminders() async {
        didCancelAll = true
        scheduledRequestsCount = 0
    }
}
