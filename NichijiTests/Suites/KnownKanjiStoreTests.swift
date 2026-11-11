import Foundation
import SwiftData
import Testing
@testable import Nichiji

/*------------------------------known-store-------------------------------*/

@Suite("Known Kanji Store Tests")
struct KnownKanjiStoreTests {
    private let day = "2026-10-28"

    private func makeStore() throws -> SwiftDataLearnerStore {
        try makeStoreAndContainer().store
    }

    private func makeStoreAndContainer() throws -> (store: SwiftDataLearnerStore, container: ModelContainer) {
        let schema = Schema([KanjiProgress.self, DailyAssignment.self, CustomKanjiSelection.self, StudyLogEntry.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return (SwiftDataLearnerStore(modelContainer: container), container)
    }

    /// The flag is not in the snapshot, so tests read the row through a fresh context on the same container.
    private func wasHandKnown(_ kanjiID: String, in container: ModelContainer) throws -> Bool? {
        let context = ModelContext(container)
        let rows = try context.fetch(FetchDescriptor<KanjiProgress>(predicate: #Predicate { $0.kanjiID == kanjiID }))
        return rows.first?.wasHandKnown
    }

    @Test("Declaring a new kanji puts it in learning, due the next day, with no log row")
    func declareMarksKnown() async throws {
        let store = try makeStore()
        let date = Date(timeIntervalSince1970: 1_793_000_000)

        try await store.declareKnown(["山", "川"], at: date)

        let progress = try #require(try await store.progress(for: "山"))
        #expect(progress.stage == .learning)
        #expect(progress.nextReviewAt == ReviewScheduler.firstReviewDate(learnedOn: date, calendar: .current))
        #expect(progress.declaredKnownAt == date)
        #expect(progress.declaredKnown)
        #expect(try await store.studyLog().isEmpty)
        #expect(try await store.declaredKnownIDs() == ["山", "川"])
        #expect(try await store.nonNewKanjiIDs() == ["山", "川"])
    }

    @Test("Kanji marked together come due ten a day from the next day")
    func declareStaggersDueDates() async throws {
        let store = try makeStore()
        let date = Date(timeIntervalSince1970: 1_793_000_000)
        let ids = Set((0..<25).map { "k\(String(format: "%02d", $0))" })

        try await store.declareKnown(ids, at: date)

        for (index, id) in ids.sorted().enumerated() {
            let expected = ReviewScheduler.dueDate(addingDays: 1 + index / 10, to: date, calendar: .current)
            #expect(try await store.progress(for: id)?.nextReviewAt == expected)
        }
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

    /*-------------------------------auto-----------------------------------*/

    @Test("Syncing marks new kanji as automatic and leaves kanji in study alone")
    func syncMarksNewKanji() async throws {
        let (store, container) = try makeStoreAndContainer()
        _ = try await store.createAssignment(calendarDay: day, kanjiID: "学", assignedAt: Date())
        _ = try await store.markLearned(day: day, nextReviewAt: Date())
        let context = ModelContext(container)
        context.insert(KanjiProgress(kanjiID: "月", stage: .familiar))
        context.insert(KanjiProgress(kanjiID: "火", stage: .known))
        try context.save()

        try await store.syncAutoKnown(["山", "学", "月", "火"], at: Date())

        #expect(try await store.declaredKnownIDs() == ["山"])
        #expect(try wasHandKnown("山", in: container) == false)
        #expect(try await store.progress(for: "学")?.stage == .learning)
        #expect(try await store.progress(for: "月")?.stage == .familiar)
        #expect(try await store.progress(for: "火")?.declaredKnownAt == nil)
        #expect(try await store.studyLog().count == 1)
    }

    @Test("Syncing drops automatic marks outside the set and keeps hand marks")
    func syncKeepsHandMarks() async throws {
        let (store, container) = try makeStoreAndContainer()
        try await store.declareKnown(["川"], at: Date())
        try await store.syncAutoKnown(["山", "日"], at: Date())

        try await store.syncAutoKnown(["日"], at: Date())

        #expect(try await store.declaredKnownIDs() == ["川", "日"])
        #expect(try await store.progress(for: "山")?.stage == .new)
        #expect(try wasHandKnown("川", in: container) == true)
        #expect(try wasHandKnown("日", in: container) == false)
        #expect(try wasHandKnown("山", in: container) == true)
    }

    @Test("A mark saved before the flag existed counts as a hand mark")
    func oldMarksStayHandMarks() async throws {
        let (store, container) = try makeStoreAndContainer()
        let context = ModelContext(container)
        context.insert(KanjiProgress(kanjiID: "川", stage: .known, declaredKnownAt: Date()))
        try context.save()

        try await store.syncAutoKnown([], at: Date())

        #expect(try await store.declaredKnownIDs() == ["川"])
        #expect(try wasHandKnown("川", in: container) == true)
    }

    @Test("Learning, review, Forget it and unmarking reset the flag")
    func clearingResetsTheFlag() async throws {
        let (store, container) = try makeStoreAndContainer()
        try await store.syncAutoKnown(["山", "川", "日", "月"], at: Date())

        try await store.forgetIt(kanjiID: "山", calendarDay: day)
        _ = try await store.createAssignment(calendarDay: day, kanjiID: "川", assignedAt: Date())
        _ = try await store.markLearned(day: day, nextReviewAt: Date())
        try await store.recordReview(
            kanjiID: "日",
            answer: .gotIt,
            outcome: ReviewOutcome(stage: .learning, nextReviewAt: Date()),
            reviewedAt: Date(),
            calendarDay: day
        )
        try await store.undeclareKnown(["月"])

        for id in ["山", "川", "日", "月"] {
            #expect(try wasHandKnown(id, in: container) == true)
        }
        #expect(try await store.declaredKnownIDs().isEmpty)
    }
}
