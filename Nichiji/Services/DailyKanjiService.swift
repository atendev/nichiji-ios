import Foundation

/*-------------------------------protocols------------------------------------*/

/// Resolves the active study pool, runs lazy day rollover, and selects each day's kanji.
protocol DailyKanjiService: Sendable {
    /// Returns or creates the assignment for a local calendar day after rolling over past days.
    // TODO: Idempotently mark .assigned rows before day as .missed, then return the existing row for day or create one from the active .new pool (returning nil if the pool is empty).
    func assignment(for day: String) async throws -> DailyAssignmentSnapshot?

    /// Resolves the unlearned study pool for the learner's current level or custom selection.
    // TODO: Load candidate entries from KanjiContentStore for the active level or custom set and filter to kanji still at StudyStage.new.
    func activePool(preferences: LearnerPreferencesSnapshot) async throws -> [KanjiEntry]

    /// Deterministically picks one kanji identifier from the candidate pool.
    // TODO: Pure selection from pool minus excludedIDs using frequencyRank, listIndex, or a generator seeded by day so app and widget always agree.
    func selectKanjiID(
        from pool: [KanjiEntry],
        order: DailyOrder,
        excluding excludedIDs: Set<String>,
        day: String
    ) -> String?

    /// Builds the self-contained snapshot rendered by the small and medium WidgetKit families.
    // TODO: Run lazy rollover via assignment(for:) and combine the assigned KanjiEntry with its learned state, returning nil when the study pool is empty.
    func widgetSnapshot(for day: String) async throws -> DailyKanjiWidgetSnapshot?
}
