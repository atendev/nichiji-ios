import Foundation
import Testing
@testable import Nichiji

/*----------------------------onboarding-tests----------------------------*/

@MainActor
@Suite("Onboarding Flow Tests")
struct OnboardingFlowTests {
    @MainActor
    private struct Fixture {
        let suiteName: String
        let defaults: UserDefaults
        let dayProvider = TestDayProvider()
        let learnerStore = TestLearnerStore()
        let contentStore = TestKanjiContentStore(entries: SeedKanjiDataset.entries + [OnboardingFlowTests.n4Entry])
        let scheduler = TestReminderScheduler()

        var service: DefaultDailyKanjiService {
            DefaultDailyKanjiService(
                contentStore: contentStore,
                learnerStore: learnerStore,
                dayProvider: dayProvider
            )
        }

        var today: String { dayProvider.calendarDay(for: dayProvider.now) }

        init() throws {
            suiteName = "com.aten.nichiji.tests.onboarding.\(UUID().uuidString)"
            defaults = try #require(UserDefaults(suiteName: suiteName))
        }

        func makeFlow() -> OnboardingFlow {
            OnboardingFlow(
                defaults: defaults,
                contentStore: contentStore,
                reminderScheduler: scheduler,
                dayProvider: dayProvider,
                learnerStore: learnerStore,
                dailyKanjiService: service
            )
        }

        func tearDown() {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }

    private static let n4Entry = KanjiEntry(
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

    private func advance(_ flow: OnboardingFlow, to step: OnboardingStep) {
        while flow.step != step {
            flow.advance()
        }
    }

    @Test("Steps run in order, Welcome shows no progress, and steps 1 to 6 fill 1 to 6 segments")
    func testStepOrderAndProgressFill() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let flow = fixture.makeFlow()

        #expect(flow.step == .welcome)
        #expect(flow.showsProgress == false)
        #expect(flow.progressFill == 0)

        var visited = [flow.step]
        for expectedFill in 1...OnboardingFlow.progressSegmentCount {
            flow.advance()
            visited.append(flow.step)
            #expect(flow.showsProgress)
            #expect(flow.progressFill == expectedFill)
        }

        #expect(visited == OnboardingStep.allCases)
        flow.advance()
        #expect(flow.step == .ready)
    }

    @Test("Back walks the steps in reverse without skipping and reaches Welcome")
    func testBackFromDailyKanjiReachesWelcome() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let flow = fixture.makeFlow()
        advance(flow, to: .ready)

        var visited = [flow.step]
        while flow.step != .welcome {
            flow.goBack()
            visited.append(flow.step)
            #expect(flow.direction == .backward)
        }

        #expect(visited == Array(OnboardingStep.allCases.reversed()))
        flow.goBack()
        #expect(flow.step == .welcome)
    }

    @Test("Switching level system selects its first level and clears the custom pool")
    func testLevelSystemSwitchSelectsFirstLevel() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let defaults = fixture.defaults
        defaults.set(LevelSystem.jlpt.rawValue, forKey: LearnerPreferenceKey.levelSystem.rawValue)
        defaults.set(JLPTLevel.n3.rawValue, forKey: LearnerPreferenceKey.selectedJLPTLevel.rawValue)
        defaults.set(JoyoGrade.grade3.rawValue, forKey: LearnerPreferenceKey.selectedJoyoGrade.rawValue)
        defaults.set(true, forKey: LearnerPreferenceKey.isCustomPoolActive.rawValue)
        let flow = fixture.makeFlow()

        #expect(flow.selectedJLPTLevel == .n3)
        #expect(flow.isCustomPoolActive)

        flow.selectLevelSystem(.joyo)
        var stored = LearnerPreferencesSnapshot.load(from: defaults)
        #expect(stored.levelSystem == .joyo)
        #expect(stored.selectedJoyoGrade == .grade1)
        #expect(stored.isCustomPoolActive == false)

        defaults.set(true, forKey: LearnerPreferenceKey.isCustomPoolActive.rawValue)
        flow.selectLevelSystem(.jlpt)
        stored = LearnerPreferencesSnapshot.load(from: defaults)
        #expect(stored.levelSystem == .jlpt)
        #expect(stored.selectedJLPTLevel == .n5)
        #expect(stored.isCustomPoolActive == false)
    }

    @Test("Choosing a level writes the level system and the matching level key")
    func testLevelSelectionWritesPreferences() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let flow = fixture.makeFlow()

        flow.selectLevel(.joyo(.grade2))
        var stored = LearnerPreferencesSnapshot.load(from: fixture.defaults)
        #expect(stored.levelSystem == .joyo)
        #expect(stored.selectedJoyoGrade == .grade2)
        #expect(flow.levelRows.first(where: \.isSelected)?.level == .joyo(.grade2))

        flow.selectLevel(.jlpt(.n4))
        stored = LearnerPreferencesSnapshot.load(from: fixture.defaults)
        #expect(stored.levelSystem == .jlpt)
        #expect(stored.selectedJLPTLevel == .n4)
        #expect(stored.selectedJoyoGrade == .grade2)
        #expect(stored.isCustomPoolActive == false)
    }

    @Test("Level row counts come from the content store, not hardcoded samples")
    func testLevelCountsComeFromContentStore() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let flow = fixture.makeFlow()

        let jlptCounts = Dictionary(uniqueKeysWithValues: flow.levelRows.map { ($0.level, $0.kanjiCount) })
        #expect(jlptCounts[.jlpt(.n5)] == (try fixture.contentStore.entries(for: .n5).count))
        #expect(jlptCounts[.jlpt(.n4)] == 1)
        #expect(jlptCounts[.jlpt(.n3)] == 0)

        flow.selectLevelSystem(.joyo)
        let joyoCounts = Dictionary(uniqueKeysWithValues: flow.levelRows.map { ($0.level, $0.kanjiCount) })
        #expect(joyoCounts.count == JoyoGrade.allCases.count)
        #expect(joyoCounts[.joyo(.grade1)] == (try fixture.contentStore.entries(for: .grade1).count))
        #expect(joyoCounts[.joyo(.grade1)] != 80)
        #expect(joyoCounts[.joyo(.grade2)] == 1)
    }

    @Test("Reminder permission is requested only while undecided, and Continue never blocks")
    func testReminderAuthorizationOnlyWhenUndecided() async throws {
        let undecided = try Fixture()
        defer { undecided.tearDown() }
        undecided.scheduler.stubbedAuthorizationStatus = .notDetermined
        let undecidedFlow = undecided.makeFlow()
        advance(undecidedFlow, to: .reminder)
        await undecidedFlow.requestReminderAuthorizationIfNeeded()

        #expect(undecided.scheduler.requestAuthorizationCallCount == 1)
        #expect(undecidedFlow.reminderAuthorization == .notDetermined)
        #expect(!undecidedFlow.isRequestingAuthorization)

        for decided in [ReminderAuthorizationStatus.denied, .authorized] {
            let fixture = try Fixture()
            defer { fixture.tearDown() }
            fixture.scheduler.stubbedAuthorizationStatus = decided
            let flow = fixture.makeFlow()
            advance(flow, to: .reminder)
            await flow.requestReminderAuthorizationIfNeeded()

            #expect(fixture.scheduler.requestAuthorizationCallCount == 0)
            #expect(flow.reminderAuthorization == decided)

            flow.advance()
            #expect(flow.step == .widgetIntro)
        }
    }

    @Test("Completion sets the onboarding flag and makes no learner store write")
    func testCompletionSetsFlagWithoutCreatingAssignment() async throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let flow = fixture.makeFlow()
        flow.selectLevel(.jlpt(.n4))
        advance(flow, to: .ready)

        await flow.complete()

        #expect(fixture.defaults.bool(forKey: LearnerPreferenceKey.hasCompletedOnboarding.rawValue))
        #expect(fixture.learnerStore.assignments.isEmpty)
        #expect(fixture.learnerStore.progress.isEmpty)
        #expect(fixture.scheduler.rebuildCallCount == 0)
    }

    @Test("Replay rebuilds reminders even with no assignment today or level change")
    func testReplayRebuildsRemindersWithoutAssignment() async throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        fixture.defaults.set(true, forKey: LearnerPreferenceKey.hasCompletedOnboarding.rawValue)
        let flow = fixture.makeFlow()
        advance(flow, to: .ready)

        await flow.complete()

        #expect(fixture.scheduler.rebuildCallCount == 1)
    }

    @Test("Replay keeps progress, reassigns an unlearned today on level change, and leaves a learned today alone")
    func testReplayPreservesProgressAndReassignsOnLevelChange() async throws {
        let assignedFixture = try Fixture()
        defer { assignedFixture.tearDown() }
        let today = assignedFixture.today
        _ = try await assignedFixture.service.assignment(for: today)
        assignedFixture.learnerStore.progress["山"] = .learning

        let assignedFlow = assignedFixture.makeFlow()
        assignedFlow.selectLevel(.jlpt(.n4))
        advance(assignedFlow, to: .ready)
        await assignedFlow.complete()

        #expect(assignedFixture.learnerStore.assignments[today]?.kanjiID == "会")
        #expect(assignedFixture.learnerStore.assignments[today]?.status == .assigned)
        #expect(assignedFixture.learnerStore.progress["山"] == .learning)
        #expect(assignedFixture.scheduler.rebuildCallCount == 1)

        let learnedFixture = try Fixture()
        defer { learnedFixture.tearDown() }
        _ = try await learnedFixture.service.assignment(for: today)
        _ = try await learnedFixture.learnerStore.markLearned(day: today)

        let learnedFlow = learnedFixture.makeFlow()
        learnedFlow.selectLevel(.jlpt(.n4))
        advance(learnedFlow, to: .ready)
        await learnedFlow.complete()

        #expect(learnedFixture.learnerStore.assignments[today]?.kanjiID == "日")
        #expect(learnedFixture.learnerStore.assignments[today]?.status == .learned)
    }
}
