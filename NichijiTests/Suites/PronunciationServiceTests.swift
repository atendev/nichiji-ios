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
        #expect(service.spokenUtterances.first?.text == "日")
        #expect(service.isSpeaking == true)
    }

    @Test("Speaking falls back to kanji text when reading is missing")
    func speakFallsBackToText() throws {
        let service = TestPronunciationService()
        try service.speak("山", reading: nil)
        #expect(service.spokenUtterances.count == 1)
        #expect(service.spokenUtterances.first?.reading == nil)
        #expect(service.spokenUtterances.first?.text == "山")
    }

    @Test("Speaking throws when Japanese voice is unavailable")
    func speakThrowsWhenVoiceUnavailable() {
        let service = TestPronunciationService()
        service.isJapaneseVoiceAvailable = false
        #expect(throws: NichijiError.self) {
            try service.speak("日", reading: "にち")
        }
    }

    @Test("Stop halts speech immediately and resets state")
    func stopHaltsPlayback() throws {
        let service = TestPronunciationService()
        try service.speak("川", reading: "かわ")
        #expect(service.isSpeaking == true)

        service.stop()
        #expect(service.isSpeaking == false)
        #expect(service.didStop == true)
    }

    @Test("Live AVSpeechPronunciationService initializes with valid defaults")
    func liveServiceVoiceAvailability() {
        let liveService = AVSpeechPronunciationService()
        #expect(liveService.isSpeaking == false)

        // Calling stop on idle service should be completely safe and idempotent
        liveService.stop()
        #expect(liveService.isSpeaking == false)

        // Querying voice availability should return a stable boolean without crashing
        _ = liveService.isJapaneseVoiceAvailable
    }
}
