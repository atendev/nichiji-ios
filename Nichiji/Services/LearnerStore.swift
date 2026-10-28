import Foundation

/*--------------------------------structs-------------------------------------*/

/// Sendable value projection of a DailyAssignment row for crossing actor boundaries.
struct DailyAssignmentSnapshot: Codable, Equatable, Sendable {
    let calendarDay: String
    let kanjiID: String
    let status: DailyAssignmentStatus
    let assignedAt: Date
    let completedAt: Date?
}

/*-------------------------------protocols------------------------------------*/

/// Actor-isolated persistence boundary owning every SwiftData read and write.
protocol LearnerStore: Sendable {
    /// Fetches the assignment snapshot for a specific local calendar day (yyyy-MM-dd).
    // TODO: Query the shared App Group ModelContainer for calendarDay and map the row to DailyAssignmentSnapshot.
    func assignment(for calendarDay: String) async throws -> DailyAssignmentSnapshot?

    /// Marks any still-assigned rows strictly before the given day as missed.
    // TODO: Transition rows with calendarDay < today and status == .assigned to .missed, leaving .learned or .missed rows untouched and keeping KanjiProgress at .new.
    func markPastAssignedAsMissed(before calendarDay: String) async throws -> [DailyAssignmentSnapshot]

    /// Creates and persists a new daily assignment row for the given calendar day.
    // TODO: Insert a .assigned DailyAssignment row for calendarDay and kanjiID, save the context, and return its snapshot.
    func createAssignment(calendarDay: String, kanjiID: String, assignedAt: Date) async throws -> DailyAssignmentSnapshot

    /// Returns kanji identifiers whose progress stage has moved past new.
    // TODO: Fetch all KanjiProgress rows where stageRaw != StudyStage.new.rawValue so daily selection excludes learned kanji.
    func nonNewKanjiIDs() async throws -> Set<String>

    /// Returns the kanji identifiers selected in the learner's custom study pool for a level system.
    // TODO: Fetch CustomKanjiSelection rows matching levelSystem and return their kanjiID set.
    func customSelectionIDs(for levelSystem: LevelSystem) async throws -> Set<String>

    /// Marks the given day's assignment as learned from Today or the interactive widget.
    // TODO: Set the day's assignment to .learned, advance KanjiProgress from .new to .learning with firstLearnedAt, append a .learnedDaily StudyLogEntry, and return the updated snapshot.
    func markLearned(day: String) async throws -> DailyAssignmentSnapshot

    /// Resets a kanji's progress back to the unlearned new stage.
    // TODO: Reset KanjiProgress for kanjiID to .new and append a .resetToNew StudyLogEntry.
    func forgetIt(kanjiID: String) async throws

    /// Replaces the custom kanji study pool for the given level system.
    // TODO: Replace all CustomKanjiSelection rows for levelSystem with kanjiIDs and save the context.
    func setCustomSelection(_ kanjiIDs: Set<String>, levelSystem: LevelSystem) async throws

    /// Swaps today's assignment from the updated pool when today's kanji is still unlearned.
    // TODO: Leave today's row untouched if already .learned; otherwise replace or clear the .assigned row from pool and save.
    func reassignToday(from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot?
}
