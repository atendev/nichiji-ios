import Foundation

/*--------------------------------structs-------------------------------------*/

/// One review session: its day, its queue, and the verdicts given so far.
struct ReviewSession: Equatable, Sendable {
    /// Local calendar day (yyyy-MM-dd) the session started on. Every answer logs under it.
    let calendarDay: String
    /// Instant the session started; due dates count from its day even past midnight.
    let startedAt: Date
    /// Kanji identifiers to review, in order.
    let queue: [String]
    /// First answer per kanji. Only these change stage and schedule.
    private(set) var verdicts: [String: ReviewAnswer] = [:]

    init(calendarDay: String, startedAt: Date, queue: [String]) {
        self.calendarDay = calendarDay
        self.startedAt = startedAt
        self.queue = queue
    }

    func hasVerdict(for kanjiID: String) -> Bool {
        verdicts[kanjiID] != nil
    }

    mutating func recordVerdict(_ answer: ReviewAnswer, for kanjiID: String) {
        guard verdicts[kanjiID] == nil else { return }
        verdicts[kanjiID] = answer
    }
}

/*-------------------------------protocols------------------------------------*/

/// Builds review sessions and applies answers through the Leitner rules.
protocol ReviewService: Sendable {
    /// Starts a session from the kanji due today, ordered and capped by the preferences.
    func startSession(preferences: ReviewPreferencesSnapshot) async throws -> ReviewSession

    /// Records an answer. The first answer per kanji moves its stage; repeats only log and count.
    func answer(_ answer: ReviewAnswer, kanjiID: String, in session: ReviewSession) async throws -> ReviewSession

    /// Number of kanji due on the given instant's local day or earlier.
    func dueCount(on date: Date) async throws -> Int

    /// Returns a kanji to the new stage and the study pool, clearing its schedule.
    func forgetIt(kanjiID: String) async throws
}

/*--------------------------------service-------------------------------------*/

/// Live review service over the learner store, with the clock from the injected day provider.
struct DefaultReviewService: ReviewService {
    private let learnerStore: any LearnerStore
    private let dayProvider: any DayProvider

    init(learnerStore: any LearnerStore, dayProvider: any DayProvider) {
        self.learnerStore = learnerStore
        self.dayProvider = dayProvider
    }

    func startSession(preferences: ReviewPreferencesSnapshot) async throws -> ReviewSession {
        let now = dayProvider.now
        let candidates = try await learnerStore.reviewableProgress()
        var generator = SystemRandomNumberGenerator()
        let queue = ReviewScheduler.dueQueue(
            from: candidates,
            on: now,
            calendar: dayProvider.calendar,
            preferences: preferences,
            using: &generator
        )
        return ReviewSession(
            calendarDay: dayProvider.calendarDay(for: now),
            startedAt: now,
            queue: queue.map(\.kanjiID)
        )
    }

    func answer(_ answer: ReviewAnswer, kanjiID: String, in session: ReviewSession) async throws -> ReviewSession {
        var session = session
        var outcome: ReviewOutcome?
        if !session.hasVerdict(for: kanjiID) {
            let stage = try await learnerStore.progress(for: kanjiID)?.stage ?? .new
            outcome = ReviewScheduler.outcome(for: answer, from: stage, on: session.startedAt, calendar: dayProvider.calendar)
        }
        try await learnerStore.recordReview(
            kanjiID: kanjiID,
            answer: answer,
            outcome: outcome,
            reviewedAt: dayProvider.now,
            calendarDay: session.calendarDay
        )
        session.recordVerdict(answer, for: kanjiID)
        return session
    }

    func dueCount(on date: Date) async throws -> Int {
        let candidates = try await learnerStore.reviewableProgress()
        return candidates.filter { ReviewScheduler.isDue($0, on: date, calendar: dayProvider.calendar) }.count
    }

    func forgetIt(kanjiID: String) async throws {
        try await learnerStore.forgetIt(kanjiID: kanjiID, calendarDay: dayProvider.calendarDay(for: dayProvider.now))
    }
}
