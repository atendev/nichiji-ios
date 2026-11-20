import SwiftUI

/*--------------------------------typesetting---------------------------------*/

public extension View {
    /// Draws Han characters with Japanese glyph shapes in system-font text, even when the device has no Japanese language. Apply once at each root.
    func japaneseTypesetting() -> some View {
        typesettingLanguage(.explicit(Locale.Language(identifier: "ja")))
    }
}
