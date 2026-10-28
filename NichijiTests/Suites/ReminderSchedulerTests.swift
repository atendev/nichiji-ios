import Testing
import Foundation
@testable import Nichiji

/*-----------------------------reminder-tests-----------------------------*/

@Suite("ReminderScheduler Tests")
struct ReminderSchedulerTests {
    @Test("Rebuilding schedule schedules 7 rolling window requests")
    func rebuildScheduleSetsSevenRequests() async throws {
        let scheduler = TestReminderScheduler()
        let prefs = LearnerPreferencesSnapshot(
            hasCompletedOnboarding: true,
            appearanceMode: .system,
            showsRomaji: true,
            streakFreezeEnabled: false,
            reminderEnabled: true,
            reminderHour: 8,
            reminderMinute: 0,
            levelSystem: .jlpt,
            selectedJLPTLevel: .n5,
            selectedJoyoGrade: .grade1,
            dailyOrder: .mostCommon,
            isCustomPoolActive: false
        )
        try await scheduler.rebuildSchedule(preferences: prefs)
        #expect(scheduler.scheduledRequestsCount == 7)
    }

    // TODO: Verify day 1 request contains kanji-led copy when learned and missed-day copy when assigned in Slice 10.
    // TODO: Verify denied permission preserves user toggle without silent notification drops in Slice 10.
}
