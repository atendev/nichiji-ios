import Testing
import Foundation
@testable import Nichiji

/*------------------------------speech-tests------------------------------*/

@Suite("PronunciationService Tests")
@MainActor
struct PronunciationServiceTests {
    @Test("Speaking records utterance when voice is available")
    func speakRecordsUtterance() throws {
        let service = TestPronunciationService()
        try service.speak("日", reading: "にち")
        #expect(service.spokenUtterances.count == 1)
        #expect(service.spokenUtterances.first?.reading == "にち")
    }

    @Test("Speaking throws when Japanese voice is unavailable")
    func speakThrowsWhenVoiceUnavailable() {
        let service = TestPronunciationService()
        service.isJapaneseVoiceAvailable = false
        #expect(throws: NichijiError.self) {
            try service.speak("日", reading: "にち")
        }
    }

    // TODO: Verify live AVSpeechSynthesizer delegates update isSpeaking state accurately in Slice 5.
}
