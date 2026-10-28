import Foundation

/*-------------------------------protocols------------------------------------*/

/// Resolves the active study pool, runs lazy day rollover, and selects each day's kanji.
public protocol DailyKanjiService: Sendable {
    /// Returns or creates the assignment for a local calendar day after rolling over past days.
    func assignment(for day: String) async throws -> DailyAssignmentSnapshot?

    /// Resolves the unlearned study pool for the learner's current level or custom selection.
    func activePool(preferences: LearnerPreferencesSnapshot) async throws -> [KanjiEntry]

    /// Deterministically picks one kanji identifier from the candidate pool.
    func selectKanjiID(
        from pool: [KanjiEntry],
        order: DailyOrder,
        excluding excludedIDs: Set<String>,
        day: String
    ) -> String?

    /// Re-evaluates the active pool and swaps the day's assignment if still unlearned.
    func refreshAssignmentAfterPreferenceChange(
        for day: String,
        preferences: LearnerPreferencesSnapshot
    ) async throws -> DailyAssignmentSnapshot?

    /// Builds the self-contained snapshot rendered by the small and medium WidgetKit families.
    func widgetSnapshot(for day: String) async throws -> DailyKanjiWidgetSnapshot?
}

/*--------------------------------service-------------------------------------*/

/// Primary implementation of DailyKanjiService coordinating stores, clock, and preferences.
public final class DefaultDailyKanjiService: DailyKanjiService, Sendable {
    private let contentStore: KanjiContentStore
    private let learnerStore: LearnerStore
    private let dayProvider: DayProvider
    private let preferencesProvider: @Sendable () -> LearnerPreferencesSnapshot

    public init(
        contentStore: KanjiContentStore,
        learnerStore: LearnerStore,
        dayProvider: DayProvider,
        preferencesProvider: @escaping @Sendable () -> LearnerPreferencesSnapshot = { .standard }
    ) {
        self.contentStore = contentStore
        self.learnerStore = learnerStore
        self.dayProvider = dayProvider
        self.preferencesProvider = preferencesProvider
    }

    public func assignment(for day: String) async throws -> DailyAssignmentSnapshot? {
        // 1. Lazy rollover: transition past assigned rows to .missed
        _ = try await learnerStore.markPastAssignedAsMissed(before: day)

        // 2. Return existing assignment for day if already created
        if let existing = try await learnerStore.assignment(for: day) {
            return existing
        }

        // 3. Resolve active unlearned pool
        let preferences = preferencesProvider()
        let pool = try await activePool(preferences: preferences)
        guard !pool.isEmpty else {
            return nil // Quiet level complete
        }

        // 4. Select deterministic kanji
        guard let pickedID = selectKanjiID(from: pool, order: preferences.dailyOrder, excluding: [], day: day) else {
            return nil
        }

        // 5. Persist daily assignment
        return try await learnerStore.createAssignment(
            calendarDay: day,
            kanjiID: pickedID,
            assignedAt: dayProvider.now
        )
    }

    public func activePool(preferences: LearnerPreferencesSnapshot) async throws -> [KanjiEntry] {
        let nonNewIDs = try await learnerStore.nonNewKanjiIDs()
        let candidateEntries: [KanjiEntry]

        if preferences.isCustomPoolActive {
            let customIDs = try await learnerStore.customSelectionIDs(for: preferences.levelSystem)
            var entries: [KanjiEntry] = []
            for id in customIDs {
                if let entry = try? contentStore.entry(for: id) {
                    entries.append(entry)
                }
            }
            candidateEntries = entries.sorted { $0.listIndex < $1.listIndex }
        } else {
            switch preferences.levelSystem {
            case .jlpt:
                candidateEntries = try contentStore.entries(for: preferences.selectedJLPTLevel)
            case .joyo:
                candidateEntries = try contentStore.entries(for: preferences.selectedJoyoGrade)
            }
        }

        return candidateEntries.filter { !nonNewIDs.contains($0.id) }
    }

    public func selectKanjiID(
        from pool: [KanjiEntry],
        order: DailyOrder,
        excluding excludedIDs: Set<String>,
        day: String
    ) -> String? {
        let candidates = orderedCandidates(from: pool, order: order, day: day)
            .filter { !excludedIDs.contains($0.id) }
        return candidates.first?.id
    }

    public func refreshAssignmentAfterPreferenceChange(
        for day: String,
        preferences: LearnerPreferencesSnapshot
    ) async throws -> DailyAssignmentSnapshot? {
        let pool = try await activePool(preferences: preferences)
        let ordered = orderedCandidates(from: pool, order: preferences.dailyOrder, day: day)
        return try await learnerStore.reassignToday(day: day, from: ordered)
    }

    public func widgetSnapshot(for day: String) async throws -> DailyKanjiWidgetSnapshot? {
        guard let assignment = try await assignment(for: day) else {
            return nil
        }

        let kanji = try contentStore.entry(for: assignment.kanjiID)
        return DailyKanjiWidgetSnapshot(
            calendarDay: day,
            kanjiID: kanji.id,
            primaryMeaning: kanji.meanings.first ?? "",
            onyomiKana: kanji.onyomi.map(\.kana),
            kunyomiKana: kanji.kunyomi.map(\.kana),
            featuredWord: kanji.exampleWords.first,
            isLearned: assignment.status == .learned
        )
    }

    // MARK: - Private Helpers

    private func orderedCandidates(
        from pool: [KanjiEntry],
        order: DailyOrder,
        day: String
    ) -> [KanjiEntry] {
        switch order {
        case .mostCommon:
            return pool.sorted {
                let rank0 = $0.frequencyRank ?? Int.max
                let rank1 = $1.frequencyRank ?? Int.max
                if rank0 == rank1 {
                    return $0.listIndex < $1.listIndex
                }
                return rank0 < rank1
            }

        case .listOrder:
            return pool.sorted { $0.listIndex < $1.listIndex }

        case .random:
            return pool.sorted {
                let hash0 = deterministicHash(day: day, kanjiID: $0.id)
                let hash1 = deterministicHash(day: day, kanjiID: $1.id)
                if hash0 == hash1 {
                    return $0.listIndex < $1.listIndex
                }
                return hash0 < hash1
            }
        }
    }

    private func deterministicHash(day: String, kanjiID: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in (day + ":" + kanjiID).utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return hash
    }
}
