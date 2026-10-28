import Foundation

/*-------------------------------protocols------------------------------------*/

/// Main-actor Japanese speech synthesis service for kanji readings and example words.
@MainActor
protocol PronunciationService: Sendable {
    /// Indicates whether the synthesizer is currently speaking an utterance.
    // TODO: Observe AVSpeechSynthesizer delegate callbacks to keep isSpeaking in sync with playback.
    var isSpeaking: Bool { get }

    /// Indicates whether a Japanese (ja-JP) voice is installed on the device.
    // TODO: Check AVSpeechSynthesisVoice(language: "ja-JP") so views can disable speaker controls with a footnote when unavailable.
    var isJapaneseVoiceAvailable: Bool { get }

    /// Speaks a kana reading when available or falls back to the written kanji text.
    // TODO: Stop any active utterance and speak reading ?? text with AVSpeechSynthesizer in ja-JP, throwing NichijiError.speechUnavailable if no voice exists.
    func speak(_ text: String, reading: String?) throws

    /// Stops any active speech synthesis immediately.
    // TODO: Call stopSpeaking(at: .immediate) when the learner taps stop or the current screen disappears.
    func stop()
}
