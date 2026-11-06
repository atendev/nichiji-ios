import Foundation
import SwiftData
import Testing
@testable import Nichiji

/*------------------------------known-store-------------------------------*/

@Suite("Known Kanji Store Tests")
struct KnownKanjiStoreTests {
    private let day = "2026-10-28"

    private func makeStore() throws -> SwiftDataLearnerStore {
        let schema = Schema([KanjiProgress.self, DailyAssignment.self, CustomKanjiSelection.self, StudyLogEntry.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return SwiftDataLearnerStore(modelContainer: container)
    }

    @Test("Declaring a new kanji makes it known with no review date and no log row")
    func declareMarksKnown() async throws {
        let store = try makeStore()
        let date = Date(timeIntervalSince1970: 1_793_000_000)

        try await store.declareKnown(["山", "川"], at: date)

        let progress = try #require(try await store.progress(for: "山"))
        #expect(progress.stage == .known)
        #expect(progress.nextReviewAt == nil)
        #expect(progress.declaredKnownAt == date)
        #expect(progress.declaredKnown)
        #expect(try await store.studyLog().isEmpty)
        #expect(try await store.declaredKnownIDs() == ["山", "川"])
        #expect(try await store.nonNewKanjiIDs() == ["山", "川"])
    }

    @Test("Declaring leaves kanji that are already in study alone")
    func declareSkipsStudiedKanji() async throws {
        let store = try makeStore()
        _ = try await store.createAssignment(calendarDay: day, kanjiID: "学", assignedAt: Date())
        _ = try await store.markLearned(day: day, nextReviewAt: Date())

        try await store.declareKnown(["学"], at: Date())

        let progress = try #require(try await store.progress(for: "学"))
        #expect(progress.stage == .learning)
        #expect(progress.declaredKnownAt == nil)
        #expect(try await store.declaredKnownIDs().isEmpty)
    }

    @Test("Undeclaring returns declared kanji to new, touches nothing else and logs nothing")
    func undeclareResetsOnlyDeclared() async throws {
        let store = try makeStore()
        _ = try await store.createAssignment(calendarDay: day, kanjiID: "学", assignedAt: Date())
        _ = try await store.markLearned(day: day, nextReviewAt: Date())
        try await store.declareKnown(["山"], at: Date())
        let logCount = try await store.studyLog().count

        try await store.undeclareKnown(["山", "学"])

        let mountain = try #require(try await store.progress(for: "山"))
        #expect(mountain.stage == .new)
        #expect(mountain.declaredKnownAt == nil)
        #expect(try await store.progress(for: "学")?.stage == .learning)
        #expect(try await store.studyLog().count == logCount)
        #expect(try await store.nonNewKanjiIDs() == ["学"])
    }

    @Test("Forget it, learning and a stage-changing review clear the declared mark")
    func otherPathsClearTheMark() async throws {
        let store = try makeStore()
        try await store.declareKnown(["山", "川", "日"], at: Date())

        try await store.forgetIt(kanjiID: "山", calendarDay: day)
        #expect(try await store.progress(for: "山")?.declaredKnownAt == nil)
        #expect(try await store.progress(for: "山")?.stage == .new)

        _ = try await store.createAssignment(calendarDay: day, kanjiID: "川", assignedAt: Date())
        _ = try await store.markLearned(day: day, nextReviewAt: Date())
        #expect(try await store.progress(for: "川")?.declaredKnown == false)
        #expect(try await store.progress(for: "川")?.stage == .learning)

        try await store.recordReview(
            kanjiID: "日",
            answer: .gotIt,
            outcome: ReviewOutcome(stage: .learning, nextReviewAt: Date()),
            reviewedAt: Date(),
            calendarDay: day
        )
        #expect(try await store.progress(for: "日")?.declaredKnownAt == nil)
        #expect(try await store.declaredKnownIDs().isEmpty)
    }
}
