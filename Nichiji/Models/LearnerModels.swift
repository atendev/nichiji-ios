import Foundation
import SwiftData

/*---------------------------------enums--------------------------------------*/

/// Familiarity tier for a kanji entry across Today and Review.
public enum StudyStage: String, Codable, CaseIterable, Sendable {
    case new
    case learning
    case familiar
    case known
}

/// Lifecycle state of a single day's kanji assignment.
public enum DailyAssignmentStatus: String, Codable, CaseIterable, Sendable {
    case assigned
    case learned
    case missed
}

/// Discrete learner study event recorded in the activity log.
public enum StudyAction: String, Codable, CaseIterable, Sendable {
    case learnedDaily
    case gotItReview
    case forgotItReview
    case resetToNew
}

/*---------------------------------models-------------------------------------*/

/// Mutable learner progress and review schedule for a single kanji character.
@Model
public final class KanjiProgress {
    @Attribute(.unique) public var kanjiID: String
    public var stageRaw: String
    public var firstLearnedAt: Date?
    public var lastReviewedAt: Date?
    public var nextReviewAt: Date?
    public var gotItCount: Int
    public var forgotItCount: Int

    public var stage: StudyStage {
        get { StudyStage(rawValue: stageRaw) ?? .new }
        set { stageRaw = newValue.rawValue }
    }

    public init(
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
public final class DailyAssignment {
    @Attribute(.unique) public var calendarDay: String
    public var kanjiID: String
    public var statusRaw: String
    public var assignedAt: Date
    public var completedAt: Date?

    public var status: DailyAssignmentStatus {
        get { DailyAssignmentStatus(rawValue: statusRaw) ?? .assigned }
        set { statusRaw = newValue.rawValue }
    }

    public init(
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
public final class CustomKanjiSelection {
    @Attribute(.unique) public var kanjiID: String
    public var levelSystemRaw: String
    public var selectedAt: Date

    public var levelSystem: LevelSystem {
        get { LevelSystem(rawValue: levelSystemRaw) ?? .jlpt }
        set { levelSystemRaw = newValue.rawValue }
    }

    public init(
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
public final class StudyLogEntry {
    @Attribute(.unique) public var id: UUID
    public var kanjiID: String
    public var actionRaw: String
    public var timestamp: Date
    public var calendarDay: String

    public var action: StudyAction {
        get { StudyAction(rawValue: actionRaw) ?? .learnedDaily }
        set { actionRaw = newValue.rawValue }
    }

    public init(
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
