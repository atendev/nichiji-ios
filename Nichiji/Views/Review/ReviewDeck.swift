import Foundation

/*--------------------------------structs-------------------------------------*/

/// One card in a review session. Repeats are forgotten cards shown again at the end.
struct ReviewCard: Equatable, Identifiable, Sendable {
    let id: Int
    let kanjiID: String
    var type: ReviewCardType
    let isRepeat: Bool
}

/// Session totals by each kanji's first answer, so a repeat never changes them.
struct ReviewDeckSummary: Equatable, Sendable {
    let reviewed: Int
    let gotIt: Int
    let forgot: Int
}

/// The cards of one session in play order, with the card types rotating through the enabled types.
struct ReviewDeck: Equatable, Sendable {
    private(set) var cards: [ReviewCard]
    private(set) var position = 0
    private var enabledTypes: [ReviewCardType]
    private var firstAnswers: [String: ReviewAnswer] = [:]
    private var repeatedKanji: Set<String> = []

    init(queue: [String], cardTypes: Set<ReviewCardType>) {
        let types = Self.ordered(cardTypes)
        self.enabledTypes = types
        self.cards = queue.enumerated().map { index, kanjiID in
            ReviewCard(id: index, kanjiID: kanjiID, type: types[index % types.count], isRepeat: false)
        }
    }

    var current: ReviewCard? {
        cards.indices.contains(position) ? cards[position] : nil
    }

    var isFinished: Bool { position >= cards.count }

    var hasAnswers: Bool { position > 0 }

    /// Share of cards answered, from 0 to 1. An empty deck counts as done.
    var progress: Double {
        cards.isEmpty ? 1 : Double(position) / Double(cards.count)
    }

    /// Counter shown in the session bar, such as `1 / 10`.
    var counterLabel: String {
        "\(min(position + 1, cards.count)) / \(cards.count)"
    }

    var summary: ReviewDeckSummary {
        let gotIt = firstAnswers.values.filter { $0 == .gotIt }.count
        return ReviewDeckSummary(reviewed: firstAnswers.count, gotIt: gotIt, forgot: firstAnswers.count - gotIt)
    }

    /// Records the answer to the current card and moves on. A forgotten kanji comes back once at the end when repeats are on.
    mutating func answer(_ answer: ReviewAnswer, repeatsForgotten: Bool) {
        guard let card = current else { return }
        if firstAnswers[card.kanjiID] == nil {
            firstAnswers[card.kanjiID] = answer
        }
        if answer == .forgotIt, repeatsForgotten, !repeatedKanji.contains(card.kanjiID) {
            repeatedKanji.insert(card.kanjiID)
            let index = cards.count
            cards.append(ReviewCard(id: index, kanjiID: card.kanjiID, type: type(at: index), isRepeat: true))
        }
        position += 1
    }

    /// Applies new card types to the cards not shown yet. The current card keeps its type.
    mutating func setCardTypes(_ cardTypes: Set<ReviewCardType>) {
        enabledTypes = Self.ordered(cardTypes)
        for index in cards.indices where index > position {
            cards[index].type = type(at: index)
        }
    }

    private func type(at index: Int) -> ReviewCardType {
        enabledTypes[index % enabledTypes.count]
    }

    private static func ordered(_ cardTypes: Set<ReviewCardType>) -> [ReviewCardType] {
        let ordered = ReviewCardType.allCases.filter(cardTypes.contains)
        return ordered.isEmpty ? ReviewCardType.allCases.filter(ReviewPreferencesSnapshot.defaultCardTypes.contains) : ordered
    }
}
