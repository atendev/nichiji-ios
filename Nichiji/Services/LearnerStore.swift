import Foundation
import SwiftData

/*--------------------------------structs-------------------------------------*/

/// Sendable value projection of a DailyAssignment row for crossing actor boundaries.
public struct DailyAssignmentSnapshot: Codable, Equatable, Sendable {
    public let calendarDay: String
    public let kanjiID: String
    public let status: DailyAssignmentStatus
    public let assignedAt: Date
    public let completedAt: Date?

    public init(
        calendarDay: String,
        kanjiID: String,
        status: DailyAssignmentStatus,
        assignedAt: Date,
        completedAt: Date? = nil
    ) {
        self.calendarDay = calendarDay
        self.kanjiID = kanjiID
        self.status = status
        self.assignedAt = assignedAt
        self.completedAt = completedAt
    }
}

/*-------------------------------protocols------------------------------------*/

/// Actor-isolated persistence boundary owning every SwiftData read and write.
public protocol LearnerStore: Sendable {
    /// Fetches the assignment snapshot for a specific local calendar day (yyyy-MM-dd).
    func assignment(for calendarDay: String) async throws -> DailyAssignmentSnapshot?

    /// Marks any still-assigned rows strictly before the given day as missed.
    func markPastAssignedAsMissed(before calendarDay: String) async throws -> [DailyAssignmentSnapshot]

    /// Creates and persists a new daily assignment row for the given calendar day.
    func createAssignment(
        calendarDay: String,
        kanjiID: String,
        assignedAt: Date
    ) async throws -> DailyAssignmentSnapshot

    /// Returns kanji identifiers whose progress stage has moved past new.
    func nonNewKanjiIDs() async throws -> Set<String>

    /// Returns the kanji identifiers selected in the learner's custom study pool for a level system.
    func customSelectionIDs(for levelSystem: LevelSystem) async throws -> Set<String>

    /// Marks the given day's assignment as learned from Today or the interactive widget.
    func markLearned(day: String) async throws -> DailyAssignmentSnapshot

    /// Resets a kanji's progress back to the unlearned new stage.
    func forgetIt(kanjiID: String) async throws

    /// Replaces the custom kanji study pool for the given level system.
    func setCustomSelection(_ kanjiIDs: Set<String>, levelSystem: LevelSystem) async throws

    /// Swaps today's assignment from the updated pool when today's kanji is still unlearned.
    func reassignToday(from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot?

    /// Swaps an explicit day's assignment from the updated pool when still unlearned.
    func reassignToday(day: String, from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot?
}

public extension LearnerStore {
    func reassignToday(from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let today = formatter.string(from: Date())
        return try await reassignToday(day: today, from: pool)
    }
}

/*----------------------------------store-------------------------------------*/

@ModelActor
public actor SwiftDataLearnerStore: LearnerStore {
    public func assignment(for calendarDay: String) async throws -> DailyAssignmentSnapshot? {
        let descriptor = FetchDescriptor<DailyAssignment>(
            predicate: #Predicate { $0.calendarDay == calendarDay }
        )
        let matches = try modelContext.fetch(descriptor)
        return matches.first.map(makeSnapshot)
    }

    public func markPastAssignedAsMissed(before calendarDay: String) async throws -> [DailyAssignmentSnapshot] {
        let descriptor = FetchDescriptor<DailyAssignment>(
            predicate: #Predicate { $0.calendarDay < calendarDay }
        )
        let pastAssignments = try modelContext.fetch(descriptor)
        var updatedSnapshots: [DailyAssignmentSnapshot] = []

        for assignment in pastAssignments where assignment.status == .assigned {
            assignment.status = .missed
            updatedSnapshots.append(makeSnapshot(from: assignment))
        }

        if !updatedSnapshots.isEmpty {
            try modelContext.save()
        }
        return updatedSnapshots
    }

    public func createAssignment(
        calendarDay: String,
        kanjiID: String,
        assignedAt: Date
    ) async throws -> DailyAssignmentSnapshot {
        if let existing = try await assignment(for: calendarDay) {
            return existing
        }

        let assignment = DailyAssignment(
            calendarDay: calendarDay,
            kanjiID: kanjiID,
            status: .assigned,
            assignedAt: assignedAt
        )
        modelContext.insert(assignment)

        // Ensure a KanjiProgress row exists at stage .new.
        let progressDescriptor = FetchDescriptor<KanjiProgress>(
            predicate: #Predicate { $0.kanjiID == kanjiID }
        )
        let existingProgress = try modelContext.fetch(progressDescriptor)
        if existingProgress.isEmpty {
            let progress = KanjiProgress(kanjiID: kanjiID, stage: .new)
            modelContext.insert(progress)
        }

        try modelContext.save()
        return makeSnapshot(from: assignment)
    }

    public func nonNewKanjiIDs() async throws -> Set<String> {
        let newRaw = StudyStage.new.rawValue
        let descriptor = FetchDescriptor<KanjiProgress>(
            predicate: #Predicate { $0.stageRaw != newRaw }
        )
        let matches = try modelContext.fetch(descriptor)
        return Set(matches.map(\.kanjiID))
    }

    public func customSelectionIDs(for levelSystem: LevelSystem) async throws -> Set<String> {
        let raw = levelSystem.rawValue
        let descriptor = FetchDescriptor<CustomKanjiSelection>(
            predicate: #Predicate { $0.levelSystemRaw == raw }
        )
        let matches = try modelContext.fetch(descriptor)
        return Set(matches.map(\.kanjiID))
    }

    public func markLearned(day: String) async throws -> DailyAssignmentSnapshot {
        let descriptor = FetchDescriptor<DailyAssignment>(
            predicate: #Predicate { $0.calendarDay == day }
        )
        guard let assignment = try modelContext.fetch(descriptor).first else {
            throw NichijiError.contentMissing(kanjiID: day)
        }

        assignment.status = .learned
        assignment.completedAt = Date()

        // Progress mutation: advance stage to .learning.
        let kanjiID = assignment.kanjiID
        let progressDescriptor = FetchDescriptor<KanjiProgress>(
            predicate: #Predicate { $0.kanjiID == kanjiID }
        )
        let progressRows = try modelContext.fetch(progressDescriptor)
        let progress: KanjiProgress
        if let existing = progressRows.first {
            progress = existing
        } else {
            progress = KanjiProgress(kanjiID: kanjiID)
            modelContext.insert(progress)
        }

        if progress.firstLearnedAt == nil {
            progress.firstLearnedAt = Date()
        }
        progress.stage = .learning
        progress.gotItCount += 1

        let logEntry = StudyLogEntry(
            kanjiID: kanjiID,
            action: .learnedDaily,
            timestamp: Date(),
            calendarDay: day
        )
        modelContext.insert(logEntry)

        try modelContext.save()
        return makeSnapshot(from: assignment)
    }

    public func forgetIt(kanjiID: String) async throws {
        let progressDescriptor = FetchDescriptor<KanjiProgress>(
            predicate: #Predicate { $0.kanjiID == kanjiID }
        )
        let progressRows = try modelContext.fetch(progressDescriptor)
        let progress: KanjiProgress
        if let existing = progressRows.first {
            progress = existing
        } else {
            progress = KanjiProgress(kanjiID: kanjiID)
            modelContext.insert(progress)
        }

        progress.stage = .new
        progress.forgotItCount += 1

        let logEntry = StudyLogEntry(
            kanjiID: kanjiID,
            action: .resetToNew,
            timestamp: Date(),
            calendarDay: ""
        )
        modelContext.insert(logEntry)

        try modelContext.save()
    }

    public func setCustomSelection(_ kanjiIDs: Set<String>, levelSystem: LevelSystem) async throws {
        let raw = levelSystem.rawValue
        let descriptor = FetchDescriptor<CustomKanjiSelection>(
            predicate: #Predicate { $0.levelSystemRaw == raw }
        )
        let existing = try modelContext.fetch(descriptor)
        for row in existing {
            modelContext.delete(row)
        }

        for id in kanjiIDs {
            let row = CustomKanjiSelection(kanjiID: id, levelSystem: levelSystem)
            modelContext.insert(row)
        }

        try modelContext.save()
    }

    public func reassignToday(day: String, from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot? {
        let descriptor = FetchDescriptor<DailyAssignment>(
            predicate: #Predicate { $0.calendarDay == day }
        )
        let matches = try modelContext.fetch(descriptor)

        if let existing = matches.first {
            // If already learned, never overwrite today's achievement.
            if existing.status == .learned {
                return makeSnapshot(from: existing)
            }

            guard let replacement = pool.first(where: { $0.id != existing.kanjiID }) else {
                return makeSnapshot(from: existing)
            }
            existing.kanjiID = replacement.id
            existing.status = .assigned
            try modelContext.save()
            return makeSnapshot(from: existing)
        } else {
            guard let first = pool.first else { return nil }
            return try await createAssignment(calendarDay: day, kanjiID: first.id, assignedAt: Date())
        }
    }

    // MARK: - Private Helpers

    private func makeSnapshot(from assignment: DailyAssignment) -> DailyAssignmentSnapshot {
        DailyAssignmentSnapshot(
            calendarDay: assignment.calendarDay,
            kanjiID: assignment.kanjiID,
            status: assignment.status,
            assignedAt: assignment.assignedAt,
            completedAt: assignment.completedAt
        )
    }
}
