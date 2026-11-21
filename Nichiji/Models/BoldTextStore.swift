import Foundation
import Observation

/*-------------------------------bold-text-----------------------------------*/

/// Holds whether the iPhone's Bold Text setting is on. Static font tokens read `isEnabled` while a view body runs, so Observation re-renders those views when it changes. A root view feeds it from the `legibilityWeight` environment value, which the app and the widgets both receive.
@Observable
public final class BoldTextStore: @unchecked Sendable {
    public static let shared = BoldTextStore()

    public private(set) var isEnabled = false

    public init() {}

    public func update(isEnabled: Bool) {
        guard isEnabled != self.isEnabled else { return }
        self.isEnabled = isEnabled
    }
}
