import Foundation
@testable import Nichiji

/*----------------------------test-learner--------------------------------*/

final class TestLearnerStore: LearnerStore, @unchecked Sendable {
    var assignments: [String: DailyAssignmentSnapshot] = [:]
    var progress: [String: StudyStage] = [:]
    var customSelections: [LevelSystem: Set<String>] = [:]
    var nextReviewAt: [String: Date] = [:]
    var loggedActions: [(kanjiID: String, action: StudyAction, calendarDay: String)] = []
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
        if progress[kanjiID] == nil {
            progress[kanjiID] = .new
        }
        return snapshot
    }

    func nonNewKanjiIDs() async throws -> Set<String> {
        try checkForError()
        return Set(progress.compactMap { $0.value == .new ? nil : $0.key })
    }

    func customSelectionIDs(for levelSystem: LevelSystem) async throws -> Set<String> {
        try checkForError()
        return customSelections[levelSystem] ?? []
    }

    func markLearned(day: String, nextReviewAt: Date) async throws -> DailyAssignmentSnapshot {
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
        self.nextReviewAt[existing.kanjiID] = nextReviewAt
        loggedActions.append((kanjiID: existing.kanjiID, action: .learnedDaily, calendarDay: day))
        return learned
    }

    func forgetIt(kanjiID: String, calendarDay: String) async throws {
        try checkForError()
        progress[kanjiID] = .new
        nextReviewAt[kanjiID] = nil
        loggedActions.append((kanjiID: kanjiID, action: .resetToNew, calendarDay: calendarDay))
    }

    func progress(for kanjiID: String) async throws -> KanjiProgressSnapshot? {
        try checkForError()
        guard let stage = progress[kanjiID] else { return nil }
        return KanjiProgressSnapshot(kanjiID: kanjiID, stage: stage, nextReviewAt: nextReviewAt[kanjiID])
    }

    func reviewableProgress() async throws -> [KanjiProgressSnapshot] {
        try checkForError()
        return progress
            .filter { $0.value == .learning || $0.value == .familiar }
            .map { KanjiProgressSnapshot(kanjiID: $0.key, stage: $0.value, nextReviewAt: nextReviewAt[$0.key]) }
    }

    func recordReview(
        kanjiID: String,
        answer: ReviewAnswer,
        outcome: ReviewOutcome?,
        reviewedAt: Date,
        calendarDay: String
    ) async throws {
        try checkForError()
        if let outcome {
            progress[kanjiID] = outcome.stage
            nextReviewAt[kanjiID] = outcome.nextReviewAt
        }
        loggedActions.append((kanjiID: kanjiID, action: answer.logAction, calendarDay: calendarDay))
    }

    func setCustomSelection(_ kanjiIDs: Set<String>, levelSystem: LevelSystem) async throws {
        try checkForError()
        customSelections[levelSystem] = kanjiIDs
    }

    func reassignToday(from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot? {
        try checkForError()
        return try await reassignToday(day: "2026-10-28", from: pool)
    }

    func reassignToday(day: String, from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot? {
        try checkForError()
        if let existing = assignments[day] {
            if existing.status == .learned {
                return existing
            }
            guard let replacement = pool.first else {
                assignments.removeValue(forKey: day)
                return nil
            }
            if replacement.id == existing.kanjiID {
                return existing
            }
            return try await createAssignment(calendarDay: day, kanjiID: replacement.id, assignedAt: existing.assignedAt)
        } else {
            guard let first = pool.first else { return nil }
            return try await createAssignment(calendarDay: day, kanjiID: first.id, assignedAt: Date())
        }
    }

    private func checkForError() throws {
        if shouldThrow {
            throw NichijiError.contentMissing(kanjiID: "test")
        }
    }
}
