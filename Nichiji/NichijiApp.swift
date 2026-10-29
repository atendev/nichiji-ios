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
        (AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme
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
        do {
            let container = try Self.makeModelContainer(for: schema)
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
                    preferencesProvider: { LearnerPreferencesSnapshot.load(from: defaults) }
                ),
                pronunciationService: AVSpeechPronunciationService(),
                reminderScheduler: SystemReminderScheduler()
            )
        } catch {
            fatalError("Unable to initialize the learner store: \(error)")
        }
    }

    /// Builds the shared store, falling back to the app sandbox when the App Group
    /// container is unavailable (hosted unit tests and sideloaded installs).
    private static func makeModelContainer(for schema: Schema) throws -> ModelContainer {
        // Hosted unit tests launch the app unsigned, so the App Group container is unavailable.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
        }

        // SwiftData traps (rather than throwing) when the App Group container is
        // missing, so probe availability before attempting the grouped configuration.
        let groupAvailable = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppStorageGroup.suiteName
        ) != nil

        if groupAvailable {
            do {
                let shared = ModelConfiguration(
                    schema: schema,
                    groupContainer: .identifier(AppStorageGroup.suiteName),
                    cloudKitDatabase: .none
                )
                return try ModelContainer(for: schema, configurations: shared)
            } catch {
                // Sideloaded re-signing can strip the App Group entitlement; run standalone.
            }
        }

        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        )
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
