import Foundation
import Observation

/*---------------------------------types----------------------------------*/

/// Direction of the last step change, used to pick the slide edge.
enum OnboardingDirection: Sendable {
    case forward
    case backward
}

/// One selectable row on the onboarding level screen.
struct OnboardingLevelRow: Identifiable, Equatable {
    enum Level: Hashable {
        case jlpt(JLPTLevel)
        case joyo(JoyoGrade)
    }

    let level: Level
    let code: String
    let title: String
    let kanjiCount: Int
    let isSelected: Bool

    var id: Level { level }
}

/*----------------------------------flow----------------------------------*/

/// Step navigation, level and reminder choices, and completion for the seven-step onboarding.
@MainActor
@Observable
final class OnboardingFlow {
    static let progressSegmentCount = 6

    private(set) var step: OnboardingStep = .welcome
    private(set) var direction: OnboardingDirection = .forward

    private(set) var levelSystem: LevelSystem
    private(set) var selectedJLPTLevel: JLPTLevel
    private(set) var selectedJoyoGrade: JoyoGrade
    private(set) var isCustomPoolActive: Bool

    var reminderEnabled: Bool {
        didSet { defaults.set(reminderEnabled, forKey: LearnerPreferenceKey.reminderEnabled.rawValue) }
    }

    var reminderHour: Int {
        didSet { defaults.set(reminderHour, forKey: LearnerPreferenceKey.reminderHour.rawValue) }
    }

    var reminderMinute: Int {
        didSet { defaults.set(reminderMinute, forKey: LearnerPreferenceKey.reminderMinute.rawValue) }
    }

    private(set) var reminderAuthorization: ReminderAuthorizationStatus = .notDetermined
    private(set) var isRequestingAuthorization = false
    private(set) var isCompleting = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let reminderScheduler: any ReminderScheduler
    @ObservationIgnored private let dayProvider: any DayProvider
    @ObservationIgnored private let widgetRefresher: any WidgetRefresher
    @ObservationIgnored private let learnerStore: (any LearnerStore)?
    @ObservationIgnored private let dailyKanjiService: (any DailyKanjiService)?
    @ObservationIgnored private let initialPreferences: LearnerPreferencesSnapshot
    @ObservationIgnored private let jlptCounts: [JLPTLevel: Int]
    @ObservationIgnored private let joyoCounts: [JoyoGrade: Int]

    init(
        defaults: UserDefaults,
        contentStore: any KanjiContentStore,
        reminderScheduler: any ReminderScheduler,
        dayProvider: any DayProvider,
        widgetRefresher: any WidgetRefresher,
        learnerStore: (any LearnerStore)?,
        dailyKanjiService: (any DailyKanjiService)?
    ) {
        let preferences = LearnerPreferencesSnapshot.load(from: defaults)
        self.defaults = defaults
        self.reminderScheduler = reminderScheduler
        self.dayProvider = dayProvider
        self.widgetRefresher = widgetRefresher
        self.learnerStore = learnerStore
        self.dailyKanjiService = dailyKanjiService
        self.initialPreferences = preferences
        self.levelSystem = preferences.levelSystem
        self.selectedJLPTLevel = preferences.selectedJLPTLevel
        self.selectedJoyoGrade = preferences.selectedJoyoGrade
        self.isCustomPoolActive = preferences.isCustomPoolActive
        self.reminderEnabled = preferences.reminderEnabled
        self.reminderHour = preferences.reminderHour
        self.reminderMinute = preferences.reminderMinute
        self.jlptCounts = Dictionary(uniqueKeysWithValues: JLPTLevel.allCases.map { level in
            (level, (try? contentStore.entries(for: level).count) ?? 0)
        })
        self.joyoCounts = Dictionary(uniqueKeysWithValues: JoyoGrade.allCases.map { grade in
            (grade, (try? contentStore.entries(for: grade).count) ?? 0)
        })
    }

    convenience init(services: ServiceContainer, defaults: UserDefaults) {
        self.init(
            defaults: defaults,
            contentStore: services.contentStore,
            reminderScheduler: services.reminderScheduler,
            dayProvider: services.dayProvider,
            widgetRefresher: services.widgetRefresher,
            learnerStore: services.learnerStore,
            dailyKanjiService: services.dailyKanjiService
        )
    }

    // MARK: - Navigation

    var showsProgress: Bool { step != .welcome }

    /// Number of filled progress segments; Welcome fills none.
    var progressFill: Int { step.rawValue }

    func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        direction = .forward
        step = next
    }

    func goBack() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        direction = .backward
        step = previous
    }

    // MARK: - Level

    var levelRows: [OnboardingLevelRow] {
        switch levelSystem {
        case .jlpt:
            JLPTLevel.allCases.map { level in
                OnboardingLevelRow(
                    level: .jlpt(level),
                    code: level.codeLabel,
                    title: level.displayName,
                    kanjiCount: jlptCounts[level] ?? 0,
                    isSelected: !isCustomPoolActive && selectedJLPTLevel == level
                )
            }
        case .joyo:
            JoyoGrade.allCases.map { grade in
                OnboardingLevelRow(
                    level: .joyo(grade),
                    code: grade.codeLabel,
                    title: grade.displayName,
                    kanjiCount: joyoCounts[grade] ?? 0,
                    isSelected: !isCustomPoolActive && selectedJoyoGrade == grade
                )
            }
        }
    }

    func selectLevelSystem(_ system: LevelSystem) {
        guard system != levelSystem else { return }
        levelSystem = system
        switch system {
        case .jlpt: selectedJLPTLevel = .n5
        case .joyo: selectedJoyoGrade = .grade1
        }
        isCustomPoolActive = false
        persistLevel()
    }

    func selectLevel(_ level: OnboardingLevelRow.Level) {
        switch level {
        case .jlpt(let jlptLevel):
            levelSystem = .jlpt
            selectedJLPTLevel = jlptLevel
        case .joyo(let grade):
            levelSystem = .joyo
            selectedJoyoGrade = grade
        }
        isCustomPoolActive = false
        persistLevel()
    }

    private func persistLevel() {
        defaults.set(levelSystem.rawValue, forKey: LearnerPreferenceKey.levelSystem.rawValue)
        switch levelSystem {
        case .jlpt:
            defaults.set(selectedJLPTLevel.rawValue, forKey: LearnerPreferenceKey.selectedJLPTLevel.rawValue)
        case .joyo:
            defaults.set(selectedJoyoGrade.rawValue, forKey: LearnerPreferenceKey.selectedJoyoGrade.rawValue)
        }
        defaults.set(false, forKey: LearnerPreferenceKey.isCustomPoolActive.rawValue)
    }

    // MARK: - Reminder

    func refreshReminderAuthorization() async {
        reminderAuthorization = await reminderScheduler.authorizationStatus()
    }

    /// Shows the system permission prompt when the learner has not answered it yet.
    /// A decided status is only refreshed, since iOS never shows the prompt twice.
    func requestReminderAuthorizationIfNeeded() async {
        guard !isRequestingAuthorization else { return }
        await refreshReminderAuthorization()
        guard reminderAuthorization == .notDetermined else { return }
        isRequestingAuthorization = true
        _ = try? await reminderScheduler.requestAuthorization()
        reminderAuthorization = await reminderScheduler.authorizationStatus()
        isRequestingAuthorization = false
    }

    // MARK: - Completion

    /// Marks onboarding done. A replay that changed the level re-picks today's kanji; no assignment is created here.
    func complete() async {
        guard !isCompleting else { return }
        isCompleting = true

        let finalPreferences = LearnerPreferencesSnapshot.load(from: defaults)
        let today = dayProvider.calendarDay(for: dayProvider.now)
        var rebuiltReminders = false
        // First runs have no assignment yet, so Today's lazy rollover picks with the new level instead.
        if Self.levelChanged(from: initialPreferences, to: finalPreferences),
           let learnerStore,
           let dailyKanjiService,
           (try? await learnerStore.assignment(for: today)) != nil {
            do {
                _ = try await LevelChangeCoordinator.applyLevelChange(
                    preferences: finalPreferences,
                    dailyKanjiService: dailyKanjiService,
                    dayProvider: dayProvider,
                    reminderScheduler: reminderScheduler,
                    widgetRefresher: widgetRefresher
                )
                rebuiltReminders = true
            } catch {
                // Fall through to a plain reminder rebuild below.
            }
        }
        // A first run must not touch the learner store here: RootView rebuilds reminders once the flag flips.
        if !rebuiltReminders, initialPreferences.hasCompletedOnboarding {
            try? await ReminderRefresher.refresh(preferences: finalPreferences, scheduler: reminderScheduler)
        }

        defaults.set(true, forKey: LearnerPreferenceKey.hasCompletedOnboarding.rawValue)
        // The widget shows an open-app placeholder until this flag is set, so reload after it.
        widgetRefresher.reloadTimelines()
    }

    private static func levelChanged(
        from old: LearnerPreferencesSnapshot,
        to new: LearnerPreferencesSnapshot
    ) -> Bool {
        old.levelSystem != new.levelSystem
            || old.selectedJLPTLevel != new.selectedJLPTLevel
            || old.selectedJoyoGrade != new.selectedJoyoGrade
            || old.isCustomPoolActive != new.isCustomPoolActive
    }
}
