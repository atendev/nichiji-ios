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
    /// Makes interface fonts one weight heavier when the iPhone's Bold Text setting is on. Apply once at each root, next to `japaneseTypesetting()`. A widget root passes `rendersOnce` because WidgetKit draws each entry once and does not run `onChange`, so the store must be set while the body runs. `didChange` runs when the setting changes while the view is on screen, so the app can reload the widget timelines.
    func honoursBoldText(rendersOnce: Bool = false, didChange: (() -> Void)? = nil) -> some View {
        modifier(BoldTextModifier(rendersOnce: rendersOnce, didChange: didChange))
    }
}

private struct BoldTextModifier: ViewModifier {
    let rendersOnce: Bool
    let didChange: (() -> Void)?

    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        let _ = rendersOnce ? sync() : ()
        content
            .onChange(of: legibilityWeight, initial: true) { old, new in
                sync()
                if old != new { didChange?() }
            }
    }

    private func sync() {
        BoldTextStore.shared.update(isEnabled: legibilityWeight == .bold)
    }
}
