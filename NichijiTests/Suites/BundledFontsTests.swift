import Testing
import UIKit
@testable import Nichiji

/*-------------------------------bundled-fonts-tests--------------------------*/

/// `Font.custom` falls back to the system font without a word when a face is missing, so these catch an unbundled font.
@Suite("Bundled fonts Tests")
struct BundledFontsTests {
    @Test("Every design-token face is registered", arguments: [
        "ShipporiMincho-Regular",
        "ZenKakuGothicNew-Regular",
        "ZenKakuGothicNew-Medium"
    ])
    func faceIsRegistered(name: String) {
        #expect(UIFont(name: name, size: 16) != nil)
    }

    @Test("Shippori Mincho draws the kanji that differ between Japanese and Chinese")
    func minchoCoversShapeSensitiveKanji() throws {
        let font = try #require(UIFont(name: "ShipporiMincho-Regular", size: 16))
        let ctFont = font as CTFont
        for character in "直骨角" {
            var glyph = CGGlyph()
            var unit = Array(String(character).utf16)
            #expect(CTFontGetGlyphsForCharacters(ctFont, &unit, &glyph, 1))
        }
    }
}
