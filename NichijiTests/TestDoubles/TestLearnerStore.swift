import Foundation
@testable import Nichiji

/*----------------------------test-learner--------------------------------*/

final class TestLearnerStore: LearnerStore, @unchecked Sendable {
    var assignments: [String: DailyAssignmentSnapshot] = [:]
    var progress: [String: StudyStage] = [:]
    var shouldThrow = false

    func assignment(for calendarDay: String) async throws -> DailyAssignmentSnapshot? {
        try checkForError()
        return assignments[calendarDay]
    }

    func markPastAssignedAsMissed(before calendarDay: String) async throws -> [DailyAssignmentSnapshot] {
        try checkForError()
        let missed = assignments.values.filter { $0.calendarDay < calendarDay && $0.status == .assigned }
            .map {
                DailyAssignmentSnapshot(
                    calendarDay: $0.calendarDay,
                    kanjiID: $0.kanjiID,
                    status: .missed,
                    assignedAt: $0.assignedAt,
                    completedAt: $0.completedAt
                )
            }
        for snapshot in missed {
            assignments[snapshot.calendarDay] = snapshot
        }
        return missed
    }

    func createAssignment(calendarDay: String, kanjiID: String, assignedAt: Date) async throws -> DailyAssignmentSnapshot {
        try checkForError()
        let snapshot = DailyAssignmentSnapshot(
            calendarDay: calendarDay,
            kanjiID: kanjiID,
            status: .assigned,
            assignedAt: assignedAt
        )
        assignments[calendarDay] = snapshot
        progress[kanjiID] = .new
        return snapshot
    }

    func nonNewKanjiIDs() async throws -> Set<String> {
        try checkForError()
        return Set(progress.compactMap { $0.value == .new ? nil : $0.key })
    }

    func customSelectionIDs(for levelSystem: LevelSystem) async throws -> Set<String> {
        try checkForError()
        return []
    }

    func markLearned(day: String) async throws -> DailyAssignmentSnapshot {
        try checkForError()
        guard let existing = assignments[day] else {
            throw NichijiError.contentMissing(kanjiID: day)
        }
        let learned = DailyAssignmentSnapshot(
            calendarDay: existing.calendarDay,
            kanjiID: existing.kanjiID,
            status: .learned,
            assignedAt: existing.assignedAt,
            completedAt: Date()
        )
        assignments[day] = learned
        progress[existing.kanjiID] = .learning
        return learned
    }

    func forgetIt(kanjiID: String) async throws {
        try checkForError()
        progress[kanjiID] = .new
    }

    func setCustomSelection(_ kanjiIDs: Set<String>, levelSystem: LevelSystem) async throws {}

    func reassignToday(from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot? {
        try checkForError()
        return try await reassignToday(day: "2026-10-28", from: pool)
    }

    func reassignToday(day: String, from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot? {
        try checkForError()
        guard let first = pool.first else { return nil }
        return try await createAssignment(calendarDay: day, kanjiID: first.id, assignedAt: Date())
    }

    private func checkForError() throws {
        if shouldThrow {
            throw NichijiError.contentMissing(kanjiID: "test")
        }
    }
}
