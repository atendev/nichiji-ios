import Testing
import Foundation
@testable import Nichiji

/*---------------------------preferences-tests----------------------------*/

@Suite("ReviewPreferences Tests")
struct ReviewPreferencesTests {
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
        let suiteName = "ReviewPreferencesTests.\(UUID().uuidString)"
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
