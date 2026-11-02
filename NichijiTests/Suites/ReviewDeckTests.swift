import CoreGraphics
import Testing
@testable import Nichiji

/*-------------------------------deck-tests-------------------------------*/

@Suite("Review Deck Tests")
struct ReviewDeckTests {
    @Test("One enabled type gives every card that type")
    func singleType() {
        let deck = ReviewDeck(queue: ["日", "一", "二"], cardTypes: [.kanjiToReading])
        #expect(deck.cards.map(\.type) == [.kanjiToReading, .kanjiToReading, .kanjiToReading])
    }

    @Test("Two types alternate in all-cases order")
    func twoTypesAlternate() {
        let deck = ReviewDeck(queue: ["日", "一", "二"], cardTypes: [.kanjiToReading, .kanjiToMeaning])
        #expect(deck.cards.map(\.type) == [.kanjiToMeaning, .kanjiToReading, .kanjiToMeaning])
    }

    @Test("Three types cycle and keep the queue order")
    func threeTypesCycle() {
        let deck = ReviewDeck(queue: ["日", "一", "二", "三"], cardTypes: Set(ReviewCardType.allCases))
        #expect(deck.cards.map(\.kanjiID) == ["日", "一", "二", "三"])
        #expect(deck.cards.map(\.type) == [.kanjiToMeaning, .kanjiToReading, .meaningToKanji, .kanjiToMeaning])
    }

    @Test("Got it advances without adding cards")
    func gotItAdvances() {
        var deck = ReviewDeck(queue: ["日", "一"], cardTypes: [.kanjiToMeaning])
        deck.answer(.gotIt, repeatsForgotten: true)
        #expect(deck.current?.kanjiID == "一")
        #expect(deck.cards.count == 2)
        #expect(deck.counterLabel == "2 / 2")
        #expect(deck.progress == 0.5)
    }

    @Test("A forgotten kanji comes back once at the end and grows the total")
    func forgottenRepeatsOnce() {
        var deck = ReviewDeck(queue: ["日", "一"], cardTypes: [.kanjiToMeaning])
        deck.answer(.forgotIt, repeatsForgotten: true)
        #expect(deck.cards.count == 3)
        #expect(deck.cards.last?.kanjiID == "日")
        #expect(deck.cards.last?.isRepeat == true)

        deck.answer(.gotIt, repeatsForgotten: true)
        deck.answer(.forgotIt, repeatsForgotten: true)
        #expect(deck.cards.count == 3)
        #expect(deck.isFinished)
    }

    @Test("Repeats off adds nothing")
    func repeatsOff() {
        var deck = ReviewDeck(queue: ["日"], cardTypes: [.kanjiToMeaning])
        deck.answer(.forgotIt, repeatsForgotten: false)
        #expect(deck.cards.count == 1)
        #expect(deck.isFinished)
    }

    @Test("A repeat answer leaves the summary on the first answer")
    func summaryUsesFirstAnswer() {
        var deck = ReviewDeck(queue: ["日", "一"], cardTypes: [.kanjiToMeaning])
        deck.answer(.forgotIt, repeatsForgotten: true)
        deck.answer(.gotIt, repeatsForgotten: true)
        deck.answer(.gotIt, repeatsForgotten: true)

        #expect(deck.isFinished)
        #expect(deck.summary == ReviewDeckSummary(reviewed: 2, gotIt: 1, forgot: 1))
        #expect(deck.summary.gotIt + deck.summary.forgot == deck.summary.reviewed)
    }

    @Test("An empty deck is finished with zero counts")
    func emptyDeck() {
        let deck = ReviewDeck(queue: [], cardTypes: [.kanjiToMeaning])
        #expect(deck.isFinished)
        #expect(deck.current == nil)
        #expect(!deck.hasAnswers)
        #expect(deck.summary == ReviewDeckSummary(reviewed: 0, gotIt: 0, forgot: 0))
    }

    @Test("New card types only reach cards not shown yet")
    func cardTypeChangeSkipsCurrent() {
        var deck = ReviewDeck(queue: ["日", "一", "二"], cardTypes: [.kanjiToMeaning])
        deck.answer(.gotIt, repeatsForgotten: true)
        deck.setCardTypes([.meaningToKanji])

        #expect(deck.cards[0].type == .kanjiToMeaning)
        #expect(deck.cards[1].type == .kanjiToMeaning)
        #expect(deck.cards[2].type == .meaningToKanji)
    }

    @Test("Turning repeats off mid-session keeps repeats already queued")
    func repeatsOffMidSession() {
        var deck = ReviewDeck(queue: ["日", "一"], cardTypes: [.kanjiToMeaning])
        deck.answer(.forgotIt, repeatsForgotten: true)
        deck.answer(.forgotIt, repeatsForgotten: false)
        #expect(deck.cards.map(\.kanjiID) == ["日", "一", "日"])
    }

    @Test("A disabled type never appears")
    func disabledTypeNeverAppears() {
        var deck = ReviewDeck(queue: ["日", "一", "二", "三"], cardTypes: [.kanjiToMeaning, .meaningToKanji])
        deck.answer(.forgotIt, repeatsForgotten: true)
        #expect(!deck.cards.contains { $0.type == .kanjiToReading })
    }
}

/*-------------------------------swipe-tests------------------------------*/

@Suite("Flashcard Swipe Tests")
struct FlashcardSwipeTests {
    @Test("Badges preview only once the card is flipped and past 40 pt")
    func badgePreview() {
        #expect(FlashcardSwipe.previewAnswer(dragWidth: 60, isFlipped: false) == nil)
        #expect(FlashcardSwipe.previewAnswer(dragWidth: 30, isFlipped: true) == nil)
        #expect(FlashcardSwipe.previewAnswer(dragWidth: 41, isFlipped: true) == .gotIt)
        #expect(FlashcardSwipe.previewAnswer(dragWidth: -41, isFlipped: true) == .forgotIt)
    }

    @Test("A release past 100 pt answers, otherwise the card springs back")
    func releaseAnswers() {
        #expect(FlashcardSwipe.answer(releasedAt: 150, isFlipped: false) == nil)
        #expect(FlashcardSwipe.answer(releasedAt: 90, isFlipped: true) == nil)
        #expect(FlashcardSwipe.answer(releasedAt: 101, isFlipped: true) == .gotIt)
        #expect(FlashcardSwipe.answer(releasedAt: -101, isFlipped: true) == .forgotIt)
    }

    @Test("Tilt is capped at 10 degrees")
    func tiltCapped() {
        #expect(FlashcardSwipe.tiltDegrees(forOffset: 200) == 5)
        #expect(FlashcardSwipe.tiltDegrees(forOffset: 600) == 10)
        #expect(FlashcardSwipe.tiltDegrees(forOffset: -600) == -10)
    }
}
