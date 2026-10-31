import Testing
import SwiftData
import Foundation
@testable import Nichiji

/*-----------------------------review-tests-------------------------------*/

@Suite("ReviewService Tests")
struct ReviewServiceTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        return calendar
    }()

    private static func date(_ day: Int, _ hour: Int = 10, _ minute: Int = 0) -> Date {
        let components = DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? .distantPast
    }

    private static func startOfDay(_ day: Int) -> Date {
        calendar.startOfDay(for: date(day))
    }

    private static func progress(
        _ kanjiID: String,
        _ stage: StudyStage,
        dueDay: Int?,
        learnedDay: Int = 1,
        forgotItCount: Int = 0
    ) -> KanjiProgressSnapshot {
        KanjiProgressSnapshot(
            kanjiID: kanjiID,
            stage: stage,
            firstLearnedAt: date(learnedDay),
            nextReviewAt: dueDay.map(startOfDay),
            forgotItCount: forgotItCount
        )
    }

    private final class Fixture: @unchecked Sendable {
        let container: ModelContainer
        let store: SwiftDataLearnerStore
        let dayProvider: TestDayProvider
        let service: DefaultReviewService

        init(now: Date = ReviewServiceTests.date(28)) throws {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: Schema.nichijiLearner, configurations: configuration)
            store = SwiftDataLearnerStore(modelContainer: container)
            dayProvider = TestDayProvider(simulatedDate: now)
            service = DefaultReviewService(learnerStore: store, dayProvider: dayProvider)
        }

        var today: String { dayProvider.calendarDay(for: dayProvider.now) }

        /// Assigns and learns a kanji today through the shared Got it rule.
        func learnToday(_ kanjiID: String) async throws {
            _ = try await store.createAssignment(calendarDay: today, kanjiID: kanjiID, assignedAt: dayProvider.now)
            try await GotItAction.perform(
                day: today,
                preferences: .standard,
                dayProvider: dayProvider,
                learnerStore: store,
                reminderScheduler: TestReminderScheduler(),
                widgetRefresher: TestWidgetRefresher()
            )
        }

        func logEntries() throws -> [(kanjiID: String, action: StudyAction, calendarDay: String)] {
            return try ModelContext(container).fetch(FetchDescriptor<StudyLogEntry>()).map { (kanjiID: $0.kanjiID, action: $0.action, calendarDay: $0.calendarDay) }
        }
    }

    /*-------------------------------scheduler--------------------------------*/

    @Test("Today's Got it schedules the first review for the start of tomorrow")
    func firstReviewIsTomorrow() {
        #expect(ReviewScheduler.firstReviewDate(learnedOn: Self.date(28, 23, 59), calendar: Self.calendar) == Self.startOfDay(29))
    }

    @Test("Got it on a learning kanji promotes it to familiar, due in 3 days")
    func learningGotItPromotesToFamiliar() {
        let outcome = ReviewScheduler.outcome(for: .gotIt, from: .learning, on: Self.date(28), calendar: Self.calendar)
        #expect(outcome == ReviewOutcome(stage: .familiar, nextReviewAt: Self.startOfDay(31)))
    }

    @Test("Got it on a familiar kanji makes it known and drops its due date")
    func familiarGotItGraduates() {
        let outcome = ReviewScheduler.outcome(for: .gotIt, from: .familiar, on: Self.date(28), calendar: Self.calendar)
        #expect(outcome == ReviewOutcome(stage: .known, nextReviewAt: nil))
    }

    @Test("Forgot it on a familiar kanji demotes it to learning, due tomorrow")
    func familiarForgotItDemotes() {
        let outcome = ReviewScheduler.outcome(for: .forgotIt, from: .familiar, on: Self.date(28), calendar: Self.calendar)
        #expect(outcome == ReviewOutcome(stage: .learning, nextReviewAt: Self.startOfDay(29)))
    }

    @Test("Forgot it on a learning kanji keeps it learning, due tomorrow")
    func learningForgotItStaysLearning() {
        let outcome = ReviewScheduler.outcome(for: .forgotIt, from: .learning, on: Self.date(28), calendar: Self.calendar)
        #expect(outcome == ReviewOutcome(stage: .learning, nextReviewAt: Self.startOfDay(29)))
    }

    @Test("New and known kanji get no outcome, so an answer cannot move them")
    func newAndKnownHaveNoOutcome() {
        for answer in ReviewAnswer.allCases {
            #expect(ReviewScheduler.outcome(for: answer, from: .new, on: Self.date(28), calendar: Self.calendar) == nil)
            #expect(ReviewScheduler.outcome(for: answer, from: .known, on: Self.date(28), calendar: Self.calendar) == nil)
        }
    }

    @Test("Due is day-granular: a kanji is due from the start of its due day onward")
    func dueIsDayGranular() {
        let kanji = Self.progress("日", .learning, dueDay: 29)

        #expect(!ReviewScheduler.isDue(kanji, on: Self.date(28, 23, 59), calendar: Self.calendar))
        #expect(ReviewScheduler.isDue(kanji, on: Self.date(29, 0, 0), calendar: Self.calendar))
        #expect(ReviewScheduler.isDue(kanji, on: Self.date(29, 23, 59), calendar: Self.calendar))
        #expect(ReviewScheduler.isDue(kanji, on: Self.date(31), calendar: Self.calendar))
    }

    @Test("New and known kanji are never due; a learning kanji with no due date is due now")
    func onlyLearningAndFamiliarAreDue() {
        let day = Self.date(28)
        #expect(!ReviewScheduler.isDue(Self.progress("新", .new, dueDay: 1), on: day, calendar: Self.calendar))
        #expect(!ReviewScheduler.isDue(Self.progress("知", .known, dueDay: 1), on: day, calendar: Self.calendar))
        #expect(ReviewScheduler.isDue(Self.progress("古", .learning, dueDay: nil), on: day, calendar: Self.calendar))
        #expect(ReviewScheduler.isDue(Self.progress("熟", .familiar, dueDay: 28), on: day, calendar: Self.calendar))
    }

    @Test("Due first orders by oldest due day, skips kanji not yet due, and caps at the session size")
    func dueFirstOrdersAndCaps() {
        let kanji = "一二三四五六七八九十百千".map(String.init)
        var candidates = kanji.enumerated().map { index, id in Self.progress(id, .learning, dueDay: 28 - index) }
        candidates.append(Self.progress("明", .learning, dueDay: 29))
        var generator = SystemRandomNumberGenerator()

        let queue = ReviewScheduler.dueQueue(
            from: candidates.shuffled(),
            on: Self.date(28),
            calendar: Self.calendar,
            order: .dueFirst,
            limit: ReviewSessionSize.ten.limit,
            using: &generator
        )

        #expect(queue.map(\.kanjiID) == Array(kanji.reversed().prefix(10)))
    }

    @Test("Hardest first and newest first order by forgot count and learn date")
    func hardestAndNewestFirstOrders() {
        let candidates = [
            Self.progress("易", .learning, dueDay: 20, learnedDay: 1, forgotItCount: 0),
            Self.progress("難", .learning, dueDay: 25, learnedDay: 2, forgotItCount: 4),
            Self.progress("新", .familiar, dueDay: 27, learnedDay: 9, forgotItCount: 1)
        ]
        var generator = SystemRandomNumberGenerator()
        func queue(_ order: ReviewOrder) -> [String] {
            ReviewScheduler.dueQueue(
                from: candidates, on: Self.date(28), calendar: Self.calendar, order: order, limit: nil, using: &generator
            ).map(\.kanjiID)
        }

        #expect(queue(.hardestFirst) == ["難", "新", "易"])
        #expect(queue(.newestFirst) == ["新", "難", "易"])
        #expect(Set(queue(.random)) == ["易", "難", "新"])
    }

    /*--------------------------------service---------------------------------*/

    @Test("Today's Got it starts learning, due tomorrow, and joins tomorrow's session only")
    func todaysGotItJoinsTomorrowsQueue() async throws {
        let fixture = try Fixture()
        try await fixture.learnToday("学")

        let progress = try #require(try await fixture.store.progress(for: "学"))
        #expect(progress.stage == .learning)
        #expect(progress.nextReviewAt == Self.startOfDay(29))
        #expect(try await fixture.service.startSession(preferences: .standard).queue.isEmpty)

        fixture.dayProvider.advance(byDays: 1)
        let session = try await fixture.service.startSession(preferences: .standard)
        #expect(session.queue == ["学"])
        #expect(session.calendarDay == "2026-10-29")
    }

    @Test("The first answer in a session decides; a repeat only logs and counts")
    func firstAnswerDecides() async throws {
        let fixture = try Fixture()
        try await fixture.learnToday("学")
        fixture.dayProvider.advance(byDays: 1)

        var session = try await fixture.service.startSession(preferences: .standard)
        session = try await fixture.service.answer(.forgotIt, kanjiID: "学", in: session)
        session = try await fixture.service.answer(.gotIt, kanjiID: "学", in: session)

        let progress = try #require(try await fixture.store.progress(for: "学"))
        #expect(session.verdicts["学"] == .forgotIt)
        #expect(progress.stage == .learning)
        #expect(progress.nextReviewAt == Self.startOfDay(30))
        #expect(progress.lastReviewedAt == fixture.dayProvider.now)
        #expect(progress.gotItCount == 2)
        #expect(progress.forgotItCount == 1)
        let actions = try fixture.logEntries().map(\.action.rawValue).sorted()
        #expect(actions == [StudyAction.learnedDaily, .forgotItReview, .gotItReview].map(\.rawValue).sorted())
    }

    @Test("A session past midnight logs and schedules from the day it started")
    func sessionKeepsItsStartDay() async throws {
        let fixture = try Fixture(now: Self.date(28, 23, 30))
        try await fixture.learnToday("学")
        fixture.dayProvider.advance(byDays: 1)

        let session = try await fixture.service.startSession(preferences: .standard)
        fixture.dayProvider.advance(bySeconds: 3600)
        _ = try await fixture.service.answer(.gotIt, kanjiID: "学", in: session)

        let progress = try #require(try await fixture.store.progress(for: "学"))
        #expect(progress.stage == .familiar)
        #expect(progress.nextReviewAt == Self.calendar.date(byAdding: .day, value: 3, to: Self.startOfDay(29)))
        let review = try #require(try fixture.logEntries().first { $0.action == .gotItReview })
        #expect(review.calendarDay == "2026-10-29")
    }

    @Test("A known kanji leaves the due queue for good")
    func knownLeavesQueue() async throws {
        let fixture = try Fixture()
        try await fixture.learnToday("学")

        fixture.dayProvider.advance(byDays: 1)
        _ = try await fixture.service.answer(.gotIt, kanjiID: "学", in: fixture.service.startSession(preferences: .standard))
        fixture.dayProvider.advance(byDays: 3)
        _ = try await fixture.service.answer(.gotIt, kanjiID: "学", in: fixture.service.startSession(preferences: .standard))

        #expect(try await fixture.store.progress(for: "学")?.stage == .known)
        fixture.dayProvider.advance(byDays: 30)
        #expect(try await fixture.service.startSession(preferences: .standard).queue.isEmpty)
        #expect(try await fixture.service.dueCount(on: fixture.dayProvider.now) == 0)
    }

    @Test("Due count includes kanji due on or before the given day")
    func dueCountIsDayGranular() async throws {
        let fixture = try Fixture()
        try await fixture.learnToday("学")

        #expect(try await fixture.service.dueCount(on: Self.date(28, 23, 59)) == 0)
        #expect(try await fixture.service.dueCount(on: Self.startOfDay(29)) == 1)
    }

    @Test("Forget it returns the kanji to new, clears its schedule, keeps history and logs the day")
    func forgetItResetsScheduleAndKeepsHistory() async throws {
        let fixture = try Fixture()
        try await fixture.learnToday("学")
        fixture.dayProvider.advance(byDays: 1)
        _ = try await fixture.service.answer(.gotIt, kanjiID: "学", in: fixture.service.startSession(preferences: .standard))
        let before = try #require(try await fixture.store.progress(for: "学"))

        try await fixture.service.forgetIt(kanjiID: "学")

        let after = try #require(try await fixture.store.progress(for: "学"))
        #expect(after.stage == .new)
        #expect(after.nextReviewAt == nil)
        #expect(after.lastReviewedAt == nil)
        #expect(after.firstLearnedAt == before.firstLearnedAt)
        #expect(after.gotItCount == before.gotItCount)
        #expect(after.forgotItCount == before.forgotItCount)
        #expect(try await fixture.store.nonNewKanjiIDs().isEmpty)
        let reset = try #require(try fixture.logEntries().first { $0.action == .resetToNew })
        #expect(reset.calendarDay == "2026-10-29")
    }

    /*------------------------------preferences-------------------------------*/

    @Test("Review preferences default to the mock settings")
    func preferenceDefaults() {
        let standard = ReviewPreferencesSnapshot.standard
        #expect(standard.cardTypes == [.kanjiToMeaning, .kanjiToReading])
        #expect(standard.order == .dueFirst)
        #expect(standard.sessionSize == .ten)
        #expect(standard.showsExampleWord)
        #expect(standard.repeatsForgotten)
        #expect(!standard.autoplaysAudio)
        #expect(standard.audioContent == .reading)
    }

    @Test("Review preferences round-trip through UserDefaults")
    func preferencesRoundTrip() throws {
        let suiteName = "ReviewServiceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(ReviewPreferencesSnapshot.load(from: defaults) == .standard)

        let custom = ReviewPreferencesSnapshot(
            cardTypes: [.meaningToKanji],
            order: .random,
            sessionSize: .allDue,
            showsExampleWord: false,
            repeatsForgotten: false,
            autoplaysAudio: true,
            audioContent: .readingAndWord
        )
        custom.save(to: defaults)
        #expect(ReviewPreferencesSnapshot.load(from: defaults) == custom)
    }

    @Test("The last enabled card type cannot be turned off")
    func lastCardTypeStaysOn() {
        var preferences = ReviewPreferencesSnapshot.standard
        #expect(preferences.setCardType(.kanjiToMeaning, enabled: false))
        #expect(!preferences.setCardType(.kanjiToReading, enabled: false))
        #expect(preferences.cardTypes == [.kanjiToReading])
        #expect(ReviewPreferencesSnapshot(cardTypes: []).cardTypes == ReviewPreferencesSnapshot.defaultCardTypes)
    }
}
