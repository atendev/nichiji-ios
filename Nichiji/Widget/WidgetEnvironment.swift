import Foundation
import SwiftData

/*------------------------------environment-----------------------------------*/

/// Dependencies the widget extension needs, built per timeline request or intent run.
struct WidgetEnvironment: Sendable {
    let dayProvider: any DayProvider
    let learnerStore: any LearnerStore
    let dailyKanjiService: any DailyKanjiService
    let reminderScheduler: any ReminderScheduler
    let widgetRefresher: any WidgetRefresher
    let preferencesProvider: @Sendable () -> LearnerPreferencesSnapshot

    var timelineBuilder: DailyKanjiTimelineBuilder {
        DailyKanjiTimelineBuilder(
            dailyKanjiService: dailyKanjiService,
            dayProvider: dayProvider,
            preferencesProvider: preferencesProvider
        )
    }

    /// Opens the shared App Group store. Throws when the group container is missing, such as on a sideloaded install.
    static func live() throws -> WidgetEnvironment {
        // SwiftData traps instead of throwing when the group container is missing, so probe first.
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppStorageGroup.suiteName) != nil else {
            throw NichijiError.storeUnavailable
        }
        let schema = Schema.nichijiLearner
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(AppStorageGroup.suiteName),
                cloudKitDatabase: .none
            )
        )
        let dayProvider = SystemDayProvider()
        let learnerStore = SwiftDataLearnerStore(modelContainer: container)
        let dailyKanjiService = DefaultDailyKanjiService(
            contentStore: BundledKanjiContentStore(),
            learnerStore: learnerStore,
            dayProvider: dayProvider,
            preferencesProvider: { Self.sharedPreferences() }
        )
        return WidgetEnvironment(
            dayProvider: dayProvider,
            learnerStore: learnerStore,
            dailyKanjiService: dailyKanjiService,
            reminderScheduler: SystemReminderScheduler(
                dailyKanjiService: dailyKanjiService,
                dayProvider: dayProvider,
                reviewService: DefaultReviewService(learnerStore: learnerStore, dayProvider: dayProvider)
            ),
            widgetRefresher: SystemWidgetRefresher(),
            preferencesProvider: { Self.sharedPreferences() }
        )
    }

    /// Reads the shared suite on demand because `UserDefaults` is not `Sendable` and cannot be captured.
    private static func sharedPreferences() -> LearnerPreferencesSnapshot {
        LearnerPreferencesSnapshot.load(from: UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard)
    }
}

extension Schema {
    /// Learner models shared by the app and the widget extension.
    static var nichijiLearner: Schema {
        Schema([
            KanjiProgress.self,
            DailyAssignment.self,
            CustomKanjiSelection.self,
            StudyLogEntry.self
        ])
    }
}
