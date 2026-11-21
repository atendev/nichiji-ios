import SwiftUI
import UIKit

/*--------------------------------typesetting---------------------------------*/

public extension UIFont {
    /// Zen Kaku Gothic New at body size with Hiragino Sans as the first fallback, which has Japanese shapes for every kanji the subset lacks.
    static var nichijiTypedBody: UIFont {
        nichijiTypedBody(boldText: BoldTextStore.shared.isEnabled)
    }

    static func nichijiTypedBody(boldText: Bool) -> UIFont {
        let japanese = UIFontDescriptor(fontAttributes: [.name: "HiraginoSans-W3"])
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: InterfaceFace.regular.resolved(boldText: boldText).rawValue,
            .cascadeList: [japanese]
        ])
        let base = UIFont(descriptor: descriptor, size: 16)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base)
    }
}

public extension View {
    /// Draws Han characters with Japanese glyph shapes in system-font text, even when the device has no Japanese language. Apply once at each root.
    func japaneseTypesetting() -> some View {
        typesettingLanguage(.explicit(Locale.Language(identifier: "ja")))
    }
}

public extension View {
    /// Makes interface fonts one weight heavier when the iPhone's Bold Text setting is on. Apply once at the app root, next to `japaneseTypesetting()`. `didUpdate` runs after the store takes the value, on first appearance and on every change, so the app can reload the widget timelines.
    func honoursBoldText(didUpdate: (() -> Void)? = nil) -> some View {
        modifier(BoldTextModifier(didUpdate: didUpdate))
    }

    /// The widget form of `honoursBoldText()`. Apply once at the widget root.
    func honoursBoldTextInWidget() -> some View {
        modifier(WidgetBoldTextModifier())
    }
}

private struct BoldTextModifier: ViewModifier {
    let didUpdate: (() -> Void)?

    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        content
            .onChange(of: legibilityWeight, initial: true) {
                BoldTextStore.shared.update(isEnabled: legibilityWeight == .bold)
                didUpdate?()
            }
    }
}

private struct WidgetBoldTextModifier: ViewModifier {
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        // WidgetKit renders each entry as a snapshot, so `onChange` and `onAppear` cannot be relied on to run before the views read the tokens. This body runs before its content's bodies, so it sets the store first. `update` does nothing when the value is unchanged.
        // swiftlint:disable:next redundant_discardable_let
        let _ = BoldTextStore.shared.update(isEnabled: legibilityWeight == .bold)
        content
    }
}
