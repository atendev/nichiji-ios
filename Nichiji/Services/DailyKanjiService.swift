import Foundation

/*-------------------------------protocols------------------------------------*/

/// The fields the daily picker orders by; the pool holds index summaries so a large level never decodes its records.
public protocol PoolCandidate {
    var id: String { get }
    var listIndex: Int { get }
    var frequencyRank: Int? { get }
}

extension KanjiIndexEntry: PoolCandidate {}
extension KanjiEntry: PoolCandidate {}

/// Resolves the active study pool, runs lazy day rollover, and selects each day's kanji.
public protocol DailyKanjiService: Sendable {
    /// Returns or creates the assignment for a local calendar day after rolling over past days.
    func assignment(for day: String) async throws -> DailyAssignmentSnapshot?

    /// Resolves the unlearned study pool for the learner's current level or custom selection.
    func activePool(preferences: LearnerPreferencesSnapshot) async throws -> [KanjiIndexEntry]

    /// Deterministically picks one kanji identifier from the candidate pool.
    func selectKanjiID(
        from pool: [some PoolCandidate],
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
        #if DEBUG || DEV_UNLOCK
        WidgetMemoryProbe.mark("rollover") // MEASURE-PROBE
        #endif

        // 2. Return existing assignment for day if already created
        let existingAssignment = try await learnerStore.assignment(for: day)
        #if DEBUG || DEV_UNLOCK
        WidgetMemoryProbe.mark("assignment-lookup") // MEASURE-PROBE
        #endif
        if let existing = existingAssignment {
            return existing
        }

        // 3. Resolve active unlearned pool
        let preferences = preferencesProvider()
        let pool = try await activePool(preferences: preferences)
        #if DEBUG || DEV_UNLOCK
        WidgetMemoryProbe.mark("pool") // MEASURE-PROBE
        #endif
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

    public func activePool(preferences: LearnerPreferencesSnapshot) async throws -> [KanjiIndexEntry] {
        let nonNewIDs = try await learnerStore.nonNewKanjiIDs()
        #if DEBUG || DEV_UNLOCK
        WidgetMemoryProbe.mark("progress-ids") // MEASURE-PROBE
        #endif
        let index = try contentStore.indexEntries()
        #if DEBUG || DEV_UNLOCK
        WidgetMemoryProbe.mark("index") // MEASURE-PROBE
        #endif
        let candidateEntries: [KanjiIndexEntry]

        if preferences.isCustomPoolActive {
            let customIDs = try await learnerStore.customSelectionIDs(for: preferences.levelSystem)
            candidateEntries = index.filter { customIDs.contains($0.id) }
        } else {
            switch preferences.levelSystem {
            case .jlpt:
                candidateEntries = index.filter { preferences.selectedJLPTLevel.includes($0) }
            case .joyo:
                candidateEntries = index.filter { preferences.selectedJoyoGrade.includes($0) }
            }
        }

        return candidateEntries.filter { !nonNewIDs.contains($0.id) }
    }

    public func selectKanjiID(
        from pool: [some PoolCandidate],
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
        // The store reads only the head of the pool, so decode just that one record.
        let head = try ordered.first.map { [try contentStore.entry(for: $0.id)] } ?? []
        return try await learnerStore.reassignToday(day: day, from: head)
    }

    public func widgetSnapshot(for day: String) async throws -> DailyKanjiWidgetSnapshot? {
        guard let assignment = try await assignment(for: day) else {
            return nil
        }

        #if DEBUG || DEV_UNLOCK
        WidgetMemoryProbe.mark("assignment") // MEASURE-PROBE
        #endif
        let kanji = try contentStore.entry(for: assignment.kanjiID)
        #if DEBUG || DEV_UNLOCK
        WidgetMemoryProbe.mark("record") // MEASURE-PROBE
        #endif
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

    private func orderedCandidates<Candidate: PoolCandidate>(
        from pool: [Candidate],
        order: DailyOrder,
        day: String
    ) -> [Candidate] {
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
