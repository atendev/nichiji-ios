import SwiftUI
import SwiftData

/*-----------------------------------app----------------------------------*/

@main
@MainActor
struct NichijiApp: App {
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearanceModeRaw) {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system, .none:
            return nil
        }
    }

    private let modelContainer: ModelContainer
    private let services: ServiceContainer

    init() {
        let schema = Schema([
            KanjiProgress.self,
            DailyAssignment.self,
            CustomKanjiSelection.self,
            StudyLogEntry.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppStorageGroup.suiteName),
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let contentStore = BundledKanjiContentStore()
            let learnerStore = SwiftDataLearnerStore(modelContainer: container)
            let dayProvider = SystemDayProvider()
            let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
            self.modelContainer = container
            self.services = ServiceContainer(
                dayProvider: dayProvider,
                contentStore: contentStore,
                learnerStore: learnerStore,
                dailyKanjiService: DefaultDailyKanjiService(
                    contentStore: contentStore,
                    learnerStore: learnerStore,
                    dayProvider: dayProvider,
                    preferencesProvider: {
                        var preferences = LearnerPreferencesSnapshot.standard
                        preferences.levelSystem = LevelSystem(
                            rawValue: defaults.string(forKey: LearnerPreferenceKey.levelSystem.rawValue) ?? ""
                        ) ?? .jlpt
                        preferences.selectedJLPTLevel = JLPTLevel(
                            rawValue: defaults.string(forKey: LearnerPreferenceKey.selectedJLPTLevel.rawValue) ?? ""
                        ) ?? .n5
                        preferences.selectedJoyoGrade = JoyoGrade(
                            rawValue: defaults.string(forKey: LearnerPreferenceKey.selectedJoyoGrade.rawValue) ?? ""
                        ) ?? .grade1
                        preferences.dailyOrder = DailyOrder(
                            rawValue: defaults.string(forKey: LearnerPreferenceKey.dailyOrder.rawValue) ?? ""
                        ) ?? .mostCommon
                        preferences.isCustomPoolActive = defaults.bool(
                            forKey: LearnerPreferenceKey.isCustomPoolActive.rawValue
                        )
                        return preferences
                    }
                ),
                pronunciationService: AVSpeechPronunciationService(),
                reminderScheduler: NoopReminderScheduler()
            )
        } catch {
            fatalError("Unable to initialize the learner store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredColorScheme)
                .modelContainer(modelContainer)
                .environment(\.serviceContainer, services)
        }
    }
}
