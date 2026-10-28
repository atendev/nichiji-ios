import Foundation
@testable import Nichiji

/*-----------------------------test-speech--------------------------------*/

@MainActor
final class TestPronunciationService: PronunciationService {
    var isSpeaking: Bool = false
    var isJapaneseVoiceAvailable: Bool = true
    var spokenUtterances: [(text: String, reading: String?)] = []
    var didStop: Bool = false

    func speak(_ text: String, reading: String?) throws {
        guard isJapaneseVoiceAvailable else {
            throw NichijiError.speechUnavailable
        }
        isSpeaking = true
        didStop = false
        spokenUtterances.append((text: text, reading: reading))
    }

    func stop() {
        isSpeaking = false
        didStop = true
    }
}
