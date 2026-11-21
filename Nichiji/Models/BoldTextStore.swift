import Foundation
import Observation

/*-------------------------------bold-text-----------------------------------*/

/// Holds whether the iPhone's Bold Text setting is on. Static font tokens read `isEnabled` while a view body runs, so Observation re-renders those views when it changes. The app seeds it at launch and a root view feeds it from the `legibilityWeight` environment value, which the app and the widgets both receive.
@Observable
public final class BoldTextStore: @unchecked Sendable {
    public static let shared = BoldTextStore()

    /// Shared `UserDefaults` key for the Bold Text value the app last saw.
    public static let lastSeenKey = "boldTextLastSeen"

    public private(set) var isEnabled = false

    public init() {}

    public func update(isEnabled: Bool) {
        guard isEnabled != self.isEnabled else { return }
        self.isEnabled = isEnabled
    }

    /// Saves `isEnabled` as the value the app last saw and returns whether it differs from the value saved before.
    public func recordSeen(in defaults: UserDefaults) -> Bool {
        let lastSeen = defaults.object(forKey: Self.lastSeenKey) as? Bool
        defaults.set(isEnabled, forKey: Self.lastSeenKey)
        return Self.changed(from: lastSeen, to: isEnabled)
    }

    /// True when Bold Text differs from the value the app last saw. No saved value counts as a change, so the first launch after an update redraws widgets drawn before it.
    public static func changed(from lastSeen: Bool?, to current: Bool) -> Bool {
        lastSeen != current
    }
}
