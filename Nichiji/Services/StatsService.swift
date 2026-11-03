import Foundation

/*-------------------------------protocols------------------------------------*/

/// Reads the study log and progress and computes the You tab's numbers, history and export.
protocol StatsService: Sendable {
    /// Every You tab number except history.
    func stats(preferences: LearnerPreferencesSnapshot) async throws -> LearnerStats

    /// Every log entry grouped by day, newest day first. Loaded apart from `stats` so the You tab can defer it.
    func history() async throws -> [HistoryDay]

    /// Figures for the level-complete screen of a finished level.
    func levelComplete(level: StudyLevel) async throws -> LevelCompleteFigures

    /// The history CSV and its file name.
    func historyExport() async throws -> HistoryExport
}

/*--------------------------------service-------------------------------------*/

/// Live stats service over the learner store and the bundled kanji index.
struct DefaultStatsService: StatsService {
    let learnerStore: any LearnerStore
    let contentStore: any KanjiContentStore
    let dayProvider: any DayProvider

    func stats(preferences: LearnerPreferencesSnapshot) async throws -> LearnerStats {
        let log = try await learnerStore.studyLog()
        let progress = try await learnerStore.allProgress()
        let index = try contentStore.indexEntries()
        return StatsCalculator.stats(log: log, progress: progress, index: index, preferences: preferences, dayProvider: dayProvider)
    }

    func history() async throws -> [HistoryDay] {
        let log = try await learnerStore.studyLog()
        return StudyHistory.days(log: log, dayProvider: dayProvider)
    }

    func levelComplete(level: StudyLevel) async throws -> LevelCompleteFigures {
        let log = try await learnerStore.studyLog()
        let progress = try await learnerStore.allProgress()
        let index = try contentStore.indexEntries()
        return StatsCalculator.levelComplete(level: level, log: log, progress: progress, index: index, dayProvider: dayProvider)
    }

    func historyExport() async throws -> HistoryExport {
        let log = try await learnerStore.studyLog()
        let pairs = try contentStore.indexEntries().map { ($0.id, $0.primaryMeaning) }
        let meanings = Dictionary(pairs, uniquingKeysWith: { first, _ in first })
        return HistoryExport(
            fileName: HistoryCSV.fileName(dayProvider: dayProvider),
            data: HistoryCSV.data(log: log, meanings: meanings, dayProvider: dayProvider)
        )
    }
}
