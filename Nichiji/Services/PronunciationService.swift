import Foundation
import AVFoundation

/*-------------------------------protocols------------------------------------*/

/// Main-actor Japanese speech synthesis service for kanji readings and example words.
@MainActor
public protocol PronunciationService: AnyObject, Sendable {
    /// Indicates whether the synthesizer is currently speaking an utterance.
    var isSpeaking: Bool { get }

    /// Indicates whether a Japanese (ja-JP) voice is installed on the device.
    var isJapaneseVoiceAvailable: Bool { get }

    /// Speaks a kana reading when available or falls back to the written kanji text.
    func speak(_ text: String, reading: String?) throws

    /// Stops any active speech synthesis immediately.
    func stop()
}

/*--------------------------------services------------------------------------*/

/// Production pronunciation service backed by AVFoundation's AVSpeechSynthesizer.
@MainActor
public final class AVSpeechPronunciationService: NSObject, PronunciationService, AVSpeechSynthesizerDelegate {
    private let synthesizer: AVSpeechSynthesizer
    public private(set) var isSpeaking: Bool = false

    public override init() {
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        self.synthesizer.delegate = self
    }

    public var isJapaneseVoiceAvailable: Bool {
        AVSpeechSynthesisVoice(language: "ja-JP") != nil
    }

    public func speak(_ text: String, reading: String?) throws {
        stop()

        guard let voice = AVSpeechSynthesisVoice(language: "ja-JP") else {
            throw NichijiError.speechUnavailable
        }

        let spokenText: String
        if let reading, !reading.isEmpty {
            spokenText = reading
        } else {
            spokenText = text
        }

        let utterance = AVSpeechUtterance(string: spokenText)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
