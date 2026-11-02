import Foundation
import Testing
@testable import Nichiji

/*------------------------------test-helpers------------------------------*/

@MainActor
private final class SessionHarness {
    let service = TestReviewService()
    let content = TestKanjiContentStore(entries: SeedKanjiDataset.entries + [SessionHarness.kunOnly])
    let speech = TestPronunciationService()
    var preferences = ReviewPreferencesSnapshot(cardTypes: [.kanjiToMeaning])
    var rebuildCount = 0

    // Kun'yomi only and no example word, like the 11 dataset kanji without one.
    static let kunOnly = KanjiEntry(
        id: "学",
        meanings: ["study"],
        onyomi: [],
        kunyomi: [KanjiReading(kind: .kunyomi, kana: "まな.ぶ", romaji: "mana.bu")],
        radical: KanjiRadical(character: "子", meaning: "child"),
        strokeCount: 8,
        jlptLevel: .n5,
        joyoGrade: .grade1,
        frequencyRank: nil,
        listIndex: 99,
        exampleWords: []
    )

    func makeModel() -> ReviewSessionModel {
        ReviewSessionModel(
            reviewService: service,
            contentStore: content,
            pronunciationService: speech,
            loadPreferences: { [unowned self] in self.preferences },
            rebuildReminders: { [unowned self] in self.rebuildCount += 1 }
        )
    }

    func started(_ queue: [String]) async -> ReviewSessionModel {
        service.queue = queue
        let model = makeModel()
        await model.start()
        return model
    }
}

@MainActor
private func answer(_ model: ReviewSessionModel, _ value: ReviewAnswer) async {
    #expect(await model.record(value))
    model.advance()
}

/*------------------------------model-tests-------------------------------*/

@MainActor
@Suite("Review Session Model Tests")
struct ReviewSessionModelTests {
    @Test("Start passes the saved order and size and builds the deck with the card types")
    func startBuildsDeck() async {
        let harness = SessionHarness()
        harness.preferences = ReviewPreferencesSnapshot(cardTypes: [.kanjiToReading], order: .hardestFirst, sessionSize: .five)
        let model = await harness.started(["日", "一"])

        #expect(model.phase == .active)
        #expect(model.deck.cards.map(\.type) == [.kanjiToReading, .kanjiToReading])
        #expect(model.currentEntry?.id == "日")
        #expect(harness.service.startedPreferences.last?.order == .hardestFirst)
        #expect(harness.service.startedPreferences.last?.sessionSize == .five)
    }

    @Test("An empty queue shows the empty state")
    func emptyQueue() async {
        let model = await SessionHarness().started([])
        #expect(model.phase == .empty)
        #expect(model.currentCard == nil)
    }

    @Test("A failed start shows the error and Retry starts again")
    func startFailureRetries() async {
        let harness = SessionHarness()
        harness.service.shouldThrow = true
        let model = await harness.started(["日"])
        guard case .failed = model.phase else {
            Issue.record("Expected the failed phase")
            return
        }

        harness.service.shouldThrow = false
        await model.start()
        #expect(model.phase == .active)
    }

    @Test("An answer calls the service once and the card moves on after it settles")
    func answerAdvances() async {
        let harness = SessionHarness()
        let model = await harness.started(["日", "一"])

        #expect(await model.record(.gotIt))
        #expect(model.currentCard?.kanjiID == "日")
        model.advance()

        #expect(harness.service.answers.count == 1)
        #expect(harness.service.answers.first?.kanjiID == "日")
        #expect(model.currentCard?.kanjiID == "一")
    }

    @Test("A repeat answer logs again with the first verdict already in the session")
    func repeatKeepsFirstVerdict() async {
        let harness = SessionHarness()
        let model = await harness.started(["日"])

        await answer(model, .forgotIt)
        #expect(model.currentCard?.isRepeat == true)
        await answer(model, .gotIt)

        #expect(harness.service.answers.map { $0.answer } == [.forgotIt, .gotIt])
        #expect(harness.service.answeredSessions[0].hasVerdict(for: "日") == false)
        #expect(harness.service.answeredSessions[1].hasVerdict(for: "日"))
        #expect(model.phase == .finished)
        #expect(model.deck.summary == ReviewDeckSummary(reviewed: 1, gotIt: 0, forgot: 1))
    }

    @Test("A new session starts with no verdicts")
    func newSessionIsFresh() async {
        let harness = SessionHarness()
        let first = await harness.started(["日"])
        await answer(first, .gotIt)
        let second = await harness.started(["日"])
        await answer(second, .gotIt)

        #expect(harness.service.answeredSessions.count == 2)
        #expect(harness.service.answeredSessions[1].hasVerdict(for: "日") == false)
    }

    @Test("Finishing rebuilds reminders once, even when closed afterwards")
    func finishRebuildsOnce() async {
        let harness = SessionHarness()
        let model = await harness.started(["日"])
        await answer(model, .gotIt)
        #expect(model.phase == .finished)

        await model.endSession()
        await model.endSession()
        #expect(harness.rebuildCount == 1)
    }

    @Test("Closing after one answer rebuilds reminders; closing with none does not")
    func closeRebuildsOnlyAfterAnswers() async {
        let untouched = SessionHarness()
        await untouched.started(["日", "一"]).endSession()
        #expect(untouched.rebuildCount == 0)

        let answered = SessionHarness()
        let model = await answered.started(["日", "一"])
        await answer(model, .gotIt)
        await model.endSession()
        #expect(answered.rebuildCount == 1)
    }

    @Test("Closing while the answered card is still flying off rebuilds reminders")
    func closeDuringFlyOff() async {
        let harness = SessionHarness()
        let model = await harness.started(["日", "一"])
        #expect(await model.record(.gotIt))
        await model.endSession()
        #expect(harness.rebuildCount == 1)
    }

    @Test("A failed answer keeps the card and shows a notice")
    func failedAnswerKeepsCard() async {
        let harness = SessionHarness()
        let model = await harness.started(["日", "一"])
        harness.service.shouldThrow = true

        #expect(await model.record(.gotIt) == false)
        model.advance()
        #expect(model.currentCard?.kanjiID == "日")
        #expect(model.notice != nil)
    }

    @Test("Reloaded preferences retype unseen cards only and leave order and size alone")
    func reloadPreferences() async {
        let harness = SessionHarness()
        let model = await harness.started(["日", "一", "二"])
        harness.preferences = ReviewPreferencesSnapshot(cardTypes: [.meaningToKanji], order: .random, sessionSize: .five)
        model.reloadPreferences()

        #expect(model.deck.cards.map(\.kanjiID) == ["日", "一", "二"])
        #expect(model.deck.cards.map(\.type) == [.kanjiToMeaning, .meaningToKanji, .meaningToKanji])
        #expect(harness.service.startedPreferences.count == 1)
    }

    @Test("The speaker plays the reading whatever the audio setting")
    func speakerPlaysReading() async throws {
        let harness = SessionHarness()
        harness.preferences = ReviewPreferencesSnapshot(audioContent: .readingAndWord)
        let model = await harness.started(["日"])
        let entry = try #require(model.currentEntry)

        model.playReading(for: entry)
        #expect(harness.speech.spokenUtterances.last?.reading == "ニチ")
    }

    @Test("Autoplay follows the setting and the audio content")
    func autoplay() async throws {
        let harness = SessionHarness()
        let model = await harness.started(["日"])
        let entry = try #require(model.currentEntry)

        model.autoplay(for: entry)
        #expect(harness.speech.spokenUtterances.isEmpty)

        harness.preferences = ReviewPreferencesSnapshot(autoplaysAudio: true, audioContent: .readingAndWord)
        model.reloadPreferences()
        model.autoplay(for: entry)
        #expect(harness.speech.spokenUtterances.last?.reading == "ニチ、きょう")
    }

    @Test("Audio falls back to kun'yomi and to the reading alone without an example word")
    func audioFallbacks() {
        let entry = SessionHarness.kunOnly
        #expect(ReviewSessionModel.audioText(for: entry, content: .reading) == "まなぶ")
        #expect(ReviewSessionModel.audioText(for: entry, content: .readingAndWord) == "まなぶ")
    }
}
