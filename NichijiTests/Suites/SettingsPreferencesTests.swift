import Foundation
import Testing
@testable import Nichiji

/*----------------------------settings-tests------------------------------*/

@Suite("Settings & Preferences Tests")
struct SettingsPreferencesTests {
    @Test("LearnerPreferencesSnapshot round-trips all preference keys through UserDefaults")
    func preferencesSnapshotRoundTrip() throws {
        let suiteName = "com.aten.nichiji.tests.preferences.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let initial = LearnerPreferencesSnapshot.load(from: defaults)
        #expect(initial == .standard)
        #expect(initial.reminderHour == 8)
        #expect(initial.reminderSummary == "On · 8:00 am")
        #expect(initial.levelSummary(customCount: 0) == "N5 · Beginner")

        let updated = LearnerPreferencesSnapshot(
            hasCompletedOnboarding: true,
            appearanceMode: .dark,
            showsRomaji: false,
            streakFreezeEnabled: true,
            reminderEnabled: true,
            reminderHour: 20,
            reminderMinute: 30,
            levelSystem: .joyo,
            selectedJLPTLevel: .n3,
            selectedJoyoGrade: .grade2,
            dailyOrder: .random,
            isCustomPoolActive: true
        )
        updated.save(to: defaults)

        let reloaded = LearnerPreferencesSnapshot.load(from: defaults)
        #expect(reloaded == updated)
        #expect(reloaded.appearanceMode.displayName == "Dark")
        #expect(reloaded.reminderSummary == "On · 8:30 pm")
        #expect(reloaded.levelSummary(customCount: 12) == "Custom · 12 kanji")
    }

    @Test("Switching level or daily order reassigns an unlearned today kanji")
    func levelSwitchReassignsUnlearnedToday() async throws {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let n4Entry = KanjiEntry(
            id: "会",
            meanings: ["meeting", "association"],
            onyomi: [KanjiReading(kind: .onyomi, kana: "カイ", romaji: "kai")],
            kunyomi: [KanjiReading(kind: .kunyomi, kana: "あ.う", romaji: "a.u")],
            radical: KanjiRadical(character: "人", meaning: "person"),
            strokeCount: 6,
            strokePaths: ["M50,15 L20,50"],
            jlptLevel: .n4,
            joyoGrade: .grade2,
            frequencyRank: 4,
            listIndex: 100,
            exampleWords: []
        )
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries + [n4Entry])
        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: learnerStore,
            dayProvider: dayProvider
        )

        let today = dayProvider.calendarDay(for: dayProvider.now)
        let initial = try await service.assignment(for: today)
        #expect(initial?.kanjiID == "日")
        #expect(initial?.status == .assigned)

        var n4Preferences = LearnerPreferencesSnapshot.standard
        n4Preferences.selectedJLPTLevel = .n4
        let reassigned = try await service.refreshAssignmentAfterPreferenceChange(
            for: today,
            preferences: n4Preferences
        )
        #expect(reassigned?.kanjiID == "会")
        #expect(reassigned?.status == .assigned)
    }

    @Test("Switching level or custom pool preserves today's assignment when already learned")
    func levelSwitchPreservesLearnedToday() async throws {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let n4Entry = KanjiEntry(
            id: "会",
            meanings: ["meeting"],
            onyomi: [KanjiReading(kind: .onyomi, kana: "カイ", romaji: "kai")],
            kunyomi: [],
            radical: KanjiRadical(character: "人", meaning: "person"),
            strokeCount: 6,
            strokePaths: ["M50,15 L20,50"],
            jlptLevel: .n4,
            joyoGrade: .grade2,
            frequencyRank: 4,
            listIndex: 100,
            exampleWords: []
        )
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries + [n4Entry])
        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: learnerStore,
            dayProvider: dayProvider
        )

        let today = dayProvider.calendarDay(for: dayProvider.now)
        _ = try await service.assignment(for: today)
        _ = try await learnerStore.markLearned(day: today, nextReviewAt: Date())

        var n4Preferences = LearnerPreferencesSnapshot.standard
        n4Preferences.selectedJLPTLevel = .n4
        let afterSwitch = try await service.refreshAssignmentAfterPreferenceChange(
            for: today,
            preferences: n4Preferences
        )

        #expect(afterSwitch?.kanjiID == "日")
        #expect(afterSwitch?.status == .learned)
    }

    @Test("Custom kanji selection persists per level system and drives the active study pool")
    func customKanjiSelectionPersistenceAndPool() async throws {
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries)
        let service = DefaultDailyKanjiService(
            contentStore: contentStore,
            learnerStore: learnerStore,
            dayProvider: dayProvider
        )

        try await learnerStore.setCustomSelection(["山", "学"], levelSystem: .jlpt)
        let storedIDs = try await learnerStore.customSelectionIDs(for: .jlpt)
        #expect(storedIDs == ["山", "学"])

        var preferences = LearnerPreferencesSnapshot.standard
        preferences.isCustomPoolActive = true
        preferences.dailyOrder = .mostCommon

        let pool = try await service.activePool(preferences: preferences)
        #expect(Set(pool.map(\.id)) == ["山", "学"])

        let today = dayProvider.calendarDay(for: dayProvider.now)
        let reassigned = try await service.refreshAssignmentAfterPreferenceChange(
            for: today,
            preferences: preferences
        )
        // 学 has frequencyRank 60 vs 山 frequencyRank 131
        #expect(reassigned?.kanjiID == "学")
    }

    @Test("ReminderSettingsCoordinator rebuilds schedule, cancels when disabled, and preserves toggle on denied status")
    func reminderSettingsAuthorizationAndRebuild() async throws {
        let scheduler = TestReminderScheduler()
        scheduler.stubbedAuthorizationStatus = .authorized

        var enabledPrefs = LearnerPreferencesSnapshot.standard
        enabledPrefs.reminderEnabled = true
        enabledPrefs.reminderHour = 12
        enabledPrefs.reminderMinute = 0

        try await ReminderSettingsCoordinator.applyReminderPreferences(enabledPrefs, scheduler: scheduler)
        #expect(scheduler.scheduledRequestsCount == 7)
        #expect(scheduler.lastRebuiltPreferences?.reminderHour == 12)

        var disabledPrefs = enabledPrefs
        disabledPrefs.reminderEnabled = false
        try await ReminderSettingsCoordinator.applyReminderPreferences(disabledPrefs, scheduler: scheduler)
        #expect(scheduler.didCancelAll == true)
        #expect(scheduler.scheduledRequestsCount == 0)

        scheduler.didCancelAll = false
        scheduler.stubbedAuthorizationStatus = .denied
        try await ReminderSettingsCoordinator.applyReminderPreferences(enabledPrefs, scheduler: scheduler)
        #expect(scheduler.didCancelAll == false)
        #expect(enabledPrefs.reminderEnabled == true)
    }
}
