import Foundation
import Observation

/*------------------------------kanji-font-style------------------------------*/

/// Holds the learner's kanji style in the shared App Group `UserDefaults`. Static font tokens read `style` while a view body runs, so Observation re-renders those views when it changes.
@Observable
public final class KanjiFontStyleStore: @unchecked Sendable {
    public static let shared = KanjiFontStyleStore()

    public private(set) var style: KanjiFontStyle

    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard) {
        self.defaults = defaults
        self.style = Self.stored(in: defaults)
    }

    /// Saves the style and updates every view that read it. Callers that show a widget reload its timelines afterwards.
    public func select(_ style: KanjiFontStyle) {
        guard style != self.style else { return }
        defaults.set(style.rawValue, forKey: LearnerPreferenceKey.kanjiFontStyle.rawValue)
        self.style = style
    }

    /// Re-reads the saved style. The widget process outlives a timeline reload, so it calls this before it builds an entry.
    public func reload() {
        let saved = Self.stored(in: defaults)
        guard saved != style else { return }
        style = saved
    }

    private static func stored(in defaults: UserDefaults) -> KanjiFontStyle {
        KanjiFontStyle(rawValue: defaults.string(forKey: LearnerPreferenceKey.kanjiFontStyle.rawValue) ?? "") ?? .standard
    }
}

public extension KanjiFontStyle {
    /// The learner's saved style. Reading it inside a view body makes that view follow later changes.
    static var current: KanjiFontStyle {
        KanjiFontStyleStore.shared.style
    }
}
