import Foundation
import Observation

/*---------------------------------model----------------------------------*/

/// Runs one review session: starts it through the review service, records each answer, and advances the deck.
@MainActor
@Observable
final class ReviewSessionModel {
    enum Phase: Equatable {
        case loading
        case empty
        case active
        case finished
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private(set) var deck = ReviewDeck(queue: [], cardTypes: ReviewPreferencesSnapshot.defaultCardTypes)
    private(set) var preferences: ReviewPreferencesSnapshot
    /// Short message for a failed answer or audio request. The session keeps going.
    private(set) var notice: String?

    private var session: ReviewSession?
    private var entries: [String: KanjiEntry] = [:]
    private var recordedAnswer: ReviewAnswer?
    private var hasRecordedAnswer = false
    private var didRebuildReminders = false

    private let reviewService: any ReviewService
    private let contentStore: any KanjiContentStore
    private let pronunciationService: any PronunciationService
    private let loadPreferences: () -> ReviewPreferencesSnapshot
    private let rebuildReminders: () async -> Void

    init(
        reviewService: any ReviewService,
        contentStore: any KanjiContentStore,
        pronunciationService: any PronunciationService,
        loadPreferences: @escaping () -> ReviewPreferencesSnapshot = { ReviewPreferencesSnapshot.load() },
        rebuildReminders: @escaping () async -> Void
    ) {
        self.reviewService = reviewService
        self.contentStore = contentStore
        self.pronunciationService = pronunciationService
        self.loadPreferences = loadPreferences
        self.rebuildReminders = rebuildReminders
        self.preferences = loadPreferences()
    }

    var currentCard: ReviewCard? { deck.current }

    var currentEntry: KanjiEntry? {
        currentCard.flatMap { entries[$0.kanjiID] }
    }

    /// Starts a session with the saved order and size. Retry calls this again.
    func start() async {
        phase = .loading
        notice = nil
        preferences = loadPreferences()
        do {
            let started = try await reviewService.startSession(preferences: preferences)
            let ids = Set(started.queue)
            entries = try Dictionary(uniqueKeysWithValues: ids.map { id in (id, try contentStore.entry(for: id)) })
            session = started
            deck = ReviewDeck(queue: started.queue, cardTypes: preferences.cardTypes)
            phase = started.queue.isEmpty ? .empty : .active
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Records an answer for the current card. Returns false, leaving the card in place, when the service fails.
    func record(_ answer: ReviewAnswer) async -> Bool {
        guard let session, let card = deck.current, recordedAnswer == nil else { return false }
        do {
            self.session = try await reviewService.answer(answer, kanjiID: card.kanjiID, in: session)
            recordedAnswer = answer
            hasRecordedAnswer = true
            notice = nil
            return true
        } catch {
            notice = "Could not save that answer. Try again."
            return false
        }
    }

    /// Moves past the recorded card once it has left the screen.
    func advance() {
        guard let answer = recordedAnswer else { return }
        recordedAnswer = nil
        deck.answer(answer, repeatsForgotten: preferences.repeatsForgotten)
        if deck.isFinished {
            phase = .finished
        }
    }

    /// Rebuilds reminders once per session, and only after at least one answer, so review-due copy stays current.
    func endSession() async {
        // Counts an answer still flying off, so closing mid-animation still rebuilds.
        guard hasRecordedAnswer, !didRebuildReminders else { return }
        didRebuildReminders = true
        await rebuildReminders()
    }

    /// Re-reads preferences after the in-session settings sheet closes. Order and size wait for the next session.
    func reloadPreferences() {
        preferences = loadPreferences()
        deck.setCardTypes(preferences.cardTypes)
    }

    /// The speaker button always plays the reading.
    func playReading(for entry: KanjiEntry) {
        speak(entry, text: Self.audioText(for: entry, content: .reading))
    }

    /// Plays the chosen audio content on flip when autoplay is on.
    func autoplay(for entry: KanjiEntry) {
        guard preferences.autoplaysAudio else { return }
        speak(entry, text: Self.audioText(for: entry, content: preferences.audioContent))
    }

    func practiceTarget(for entry: KanjiEntry) -> PracticeTarget {
        PracticeTarget(entry: entry, strokePaths: (try? contentStore.strokePaths(for: entry.id)) ?? [])
    }

    /// Kana to speak: the first on'yomi, else the first kun'yomi, plus the first example word for reading and word.
    static func audioText(for entry: KanjiEntry, content: ReviewAudioContent) -> String? {
        let reading = (entry.onyomi.first ?? entry.kunyomi.first).map { spokenKana($0.kana) }
        guard content == .readingAndWord, let word = entry.exampleWords.first else { return reading }
        return [reading, word.kana].compactMap { $0 }.joined(separator: "、")
    }

    private static func spokenKana(_ kana: String) -> String {
        kana.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "-", with: "")
    }

    private func speak(_ entry: KanjiEntry, text: String?) {
        do {
            try pronunciationService.speak(entry.id, reading: text)
        } catch {
            notice = "Japanese speech is not available on this device."
        }
    }
}
