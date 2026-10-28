import Foundation
import SwiftData

/*---------------------------------enums--------------------------------------*/

/// Familiarity tier for a kanji entry across Today and Review.
enum StudyStage: String, Codable, CaseIterable, Sendable {
    case new
    case learning
    case familiar
    case known
}

/// Lifecycle state of a single day's kanji assignment.
enum DailyAssignmentStatus: String, Codable, CaseIterable, Sendable {
    case assigned
    case learned
    case missed
}

/// Discrete learner study event recorded in the activity log.
enum StudyAction: String, Codable, CaseIterable, Sendable {
    case learnedDaily
    case gotItReview
    case forgotItReview
    case resetToNew
}

/*---------------------------------models-------------------------------------*/

/// Mutable learner progress and review schedule for a single kanji character.
@Model
final class KanjiProgress {
    @Attribute(.unique) var kanjiID: String
    var stageRaw: String
    var firstLearnedAt: Date?
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var gotItCount: Int
    var forgotItCount: Int

    init(
        kanjiID: String,
        stage: StudyStage = .new,
        firstLearnedAt: Date? = nil,
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        gotItCount: Int = 0,
        forgotItCount: Int = 0
    ) {
        self.kanjiID = kanjiID
        self.stageRaw = stage.rawValue
        self.firstLearnedAt = firstLearnedAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.gotItCount = gotItCount
        self.forgotItCount = forgotItCount
    }
}

/// Record assigning one kanji entry to a local calendar day (yyyy-MM-dd).
@Model
final class DailyAssignment {
    @Attribute(.unique) var calendarDay: String
    var kanjiID: String
    var statusRaw: String
    var assignedAt: Date
    var completedAt: Date?

    init(
        calendarDay: String,
        kanjiID: String,
        status: DailyAssignmentStatus = .assigned,
        assignedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.calendarDay = calendarDay
        self.kanjiID = kanjiID
        self.statusRaw = status.rawValue
        self.assignedAt = assignedAt
        self.completedAt = completedAt
    }
}

/// Membership record for a kanji toggled on in the custom study pool.
@Model
final class CustomKanjiSelection {
    @Attribute(.unique) var kanjiID: String
    var levelSystemRaw: String
    var selectedAt: Date

    init(
        kanjiID: String,
        levelSystem: LevelSystem,
        selectedAt: Date = .now
    ) {
        self.kanjiID = kanjiID
        self.levelSystemRaw = levelSystem.rawValue
        self.selectedAt = selectedAt
    }
}

/// Append-only history entry for daily completions, review answers, and resets.
@Model
final class StudyLogEntry {
    @Attribute(.unique) var id: UUID
    var kanjiID: String
    var actionRaw: String
    var timestamp: Date
    var calendarDay: String

    init(
        id: UUID = UUID(),
        kanjiID: String,
        action: StudyAction,
        timestamp: Date = .now,
        calendarDay: String
    ) {
        self.id = id
        self.kanjiID = kanjiID
        self.actionRaw = action.rawValue
        self.timestamp = timestamp
        self.calendarDay = calendarDay
    }
}
