import Foundation
@testable import Nichiji

/*-----------------------------test-review--------------------------------*/

final class TestReviewService: ReviewService, @unchecked Sendable {
    var queue: [String] = []
    var dueCountResult = 0
    var shouldThrow = false
    private(set) var answers: [(kanjiID: String, answer: ReviewAnswer)] = []
    private(set) var forgottenIDs: [String] = []
    private(set) var dueCountDates: [Date] = []

    func startSession(preferences: ReviewPreferencesSnapshot) async throws -> ReviewSession {
        try checkForError()
        return ReviewSession(calendarDay: "2026-10-28", startedAt: Date(), queue: queue)
    }

    func answer(_ answer: ReviewAnswer, kanjiID: String, in session: ReviewSession) async throws -> ReviewSession {
        try checkForError()
        answers.append((kanjiID: kanjiID, answer: answer))
        var session = session
        session.recordVerdict(answer, for: kanjiID)
        return session
    }

    func dueCount(on date: Date) async throws -> Int {
        try checkForError()
        dueCountDates.append(date)
        return dueCountResult
    }

    func forgetIt(kanjiID: String) async throws {
        try checkForError()
        forgottenIDs.append(kanjiID)
    }

    private func checkForError() throws {
        if shouldThrow {
            throw NichijiError.contentMissing(kanjiID: "test")
        }
    }
}
