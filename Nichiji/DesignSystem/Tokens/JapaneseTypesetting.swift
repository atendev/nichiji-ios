import SwiftUI
import UIKit

/*--------------------------------typesetting---------------------------------*/

public extension UIFont {
    /// Zen Kaku Gothic New at body size with Hiragino Sans as the first fallback, which has Japanese shapes for every kanji the subset lacks.
    static var nichijiTypedBody: UIFont {
        let japanese = UIFontDescriptor(fontAttributes: [.name: "HiraginoSans-W3"])
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: "ZenKakuGothicNew-Regular",
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
