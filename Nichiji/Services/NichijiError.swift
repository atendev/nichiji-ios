import Foundation

/*---------------------------------enums--------------------------------------*/

/// Typed domain errors thrown by content, persistence, speech, and notification services.
enum NichijiError: Error, Equatable, Sendable {
    /// The shared App Group SwiftData store or UserDefaults suite could not be opened or saved.
    case storeUnavailable
    /// A bundled kanji JSON or stroke SVG resource was not found for the requested identifier.
    case contentMissing(kanjiID: String)
    /// System notification authorization was denied by the learner.
    case notificationsDenied
    /// No Japanese (ja-JP) speech synthesis voice is available on the device.
    case speechUnavailable
}
