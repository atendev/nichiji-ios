import Foundation

/*---------------------------------enums--------------------------------------*/

/// The learner's verdict on one review card.
public enum ReviewAnswer: String, Codable, CaseIterable, Sendable {
    case gotIt
    case forgotIt

    /// Study log action recorded for this answer.
    public var logAction: StudyAction {
        switch self {
        case .gotIt: .gotItReview
        case .forgotIt: .forgotItReview
        }
    }
}

/*--------------------------------structs-------------------------------------*/

/// Sendable value projection of a KanjiProgress row for crossing actor boundaries.
public struct KanjiProgressSnapshot: Equatable, Sendable {
    public let kanjiID: String
    public let stage: StudyStage
    public let firstLearnedAt: Date?
    public let lastReviewedAt: Date?
    public let nextReviewAt: Date?
    public let gotItCount: Int
    public let forgotItCount: Int

    public init(
        kanjiID: String,
        stage: StudyStage,
        firstLearnedAt: Date? = nil,
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        gotItCount: Int = 0,
        forgotItCount: Int = 0
    ) {
        self.kanjiID = kanjiID
        self.stage = stage
        self.firstLearnedAt = firstLearnedAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.gotItCount = gotItCount
        self.forgotItCount = forgotItCount
    }
}

/// New stage and due date for a kanji after a verdict. A nil due date means it left the queue.
public struct ReviewOutcome: Equatable, Sendable {
    public let stage: StudyStage
    public let nextReviewAt: Date?

    public init(stage: StudyStage, nextReviewAt: Date?) {
        self.stage = stage
        self.nextReviewAt = nextReviewAt
    }
}

/*-------------------------------scheduler------------------------------------*/

/// Pure Leitner scheduler. Due dates are the start of a local day, so due is day-granular.
enum ReviewScheduler {
    static let learningIntervalDays = 1
    static let familiarIntervalDays = 3

    /// Today's Got it, from the app or the widget, starts the kanji learning with its first review tomorrow.
    static func firstReviewDate(learnedOn day: Date, calendar: Calendar) -> Date {
        dueDate(addingDays: learningIntervalDays, to: day, calendar: calendar)
    }

    /// Applies a session verdict to a learning or familiar kanji. New and known kanji are not reviewed, so they get nil.
    static func outcome(for answer: ReviewAnswer, from stage: StudyStage, on day: Date, calendar: Calendar) -> ReviewOutcome? {
        switch (answer, stage) {
        case (.gotIt, .learning):
            ReviewOutcome(stage: .familiar, nextReviewAt: dueDate(addingDays: familiarIntervalDays, to: day, calendar: calendar))
        case (.gotIt, .familiar):
            ReviewOutcome(stage: .known, nextReviewAt: nil)
        case (.forgotIt, .learning), (.forgotIt, .familiar):
            ReviewOutcome(stage: .learning, nextReviewAt: dueDate(addingDays: learningIntervalDays, to: day, calendar: calendar))
        case (_, .new), (_, .known):
            nil
        }
    }

    /// True when a learning or familiar kanji's due day is the given day or earlier.
    static func isDue(_ progress: KanjiProgressSnapshot, on day: Date, calendar: Calendar) -> Bool {
        guard progress.stage == .learning || progress.stage == .familiar else { return false }
        // Rows learned before scheduling existed have no due date; they are due now.
        guard let next = progress.nextReviewAt else { return true }
        return calendar.startOfDay(for: next) <= calendar.startOfDay(for: day)
    }

    /// Picks the due kanji for a session in the requested order, capped at the session size.
    static func dueQueue<Generator: RandomNumberGenerator>(
        from candidates: [KanjiProgressSnapshot],
        on day: Date,
        calendar: Calendar,
        order: ReviewOrder,
        limit: Int?,
        using generator: inout Generator
    ) -> [KanjiProgressSnapshot] {
        let due = candidates.filter { isDue($0, on: day, calendar: calendar) }
        let ordered: [KanjiProgressSnapshot]
        switch order {
        case .dueFirst:
            ordered = due.sorted(by: dueFirst)
        case .hardestFirst:
            ordered = due.sorted { lhs, rhs in
                lhs.forgotItCount != rhs.forgotItCount ? lhs.forgotItCount > rhs.forgotItCount : dueFirst(lhs, rhs)
            }
        case .newestFirst:
            ordered = due.sorted { lhs, rhs in
                let lhsLearned = lhs.firstLearnedAt ?? .distantPast
                let rhsLearned = rhs.firstLearnedAt ?? .distantPast
                return lhsLearned != rhsLearned ? lhsLearned > rhsLearned : dueFirst(lhs, rhs)
            }
        case .random:
            ordered = due.sorted(by: dueFirst).shuffled(using: &generator)
        }
        guard let limit else { return ordered }
        return Array(ordered.prefix(max(limit, 0)))
    }

    /// Start of the local day the given number of days after `day`.
    static func dueDate(addingDays days: Int, to day: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .day, value: days, to: start) ?? start.addingTimeInterval(Double(days) * 86400)
    }

    private static func dueFirst(_ lhs: KanjiProgressSnapshot, _ rhs: KanjiProgressSnapshot) -> Bool {
        let lhsDue = lhs.nextReviewAt ?? .distantPast
        let rhsDue = rhs.nextReviewAt ?? .distantPast
        return lhsDue != rhsDue ? lhsDue < rhsDue : lhs.kanjiID < rhs.kanjiID
    }
}
