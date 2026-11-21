import Observation
import SwiftUI
import Testing
import UIKit
@testable import Nichiji

/*-------------------------------bundled-fonts-tests--------------------------*/

/// `Font.custom` falls back to the system font without a word when a face is missing, so these catch an unbundled font.
@Suite("Bundled fonts Tests", .serialized)
struct BundledFontsTests {
    @Test("Every design-token face is registered", arguments: [
        "ShipporiMincho-Regular",
        "ZenKakuGothicNew-Regular",
        "ZenKakuGothicNew-Medium",
        "ZenKakuGothicNew-Bold",
        "HiraginoSans-W3"
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

    @Test("Typed search text falls back to Hiragino Sans for kanji the interface font lacks", arguments: ["直", "骨", "角"])
    func typedBodyFallsBackToJapaneseFont(kanji: String) {
        let ctFont = UIFont.nichijiTypedBody as CTFont
        let fallback = CTFontCreateForString(ctFont, kanji as CFString, CFRange(location: 0, length: 1))
        #expect((CTFontCopyPostScriptName(fallback) as String).hasPrefix("HiraginoSans"))
    }

    @Test("Kanji styles map to their fonts and serif is the default")
    func styleFonts() {
        #expect(KanjiFontStyle.standard == .serif)
        #expect(KanjiFontStyle.serif.postScriptName == "ShipporiMincho-Regular")
        #expect(KanjiFontStyle.gothic.postScriptName == "HiraginoSans-W3")
    }

    @Test("Interface weights pick the Zen Kaku Gothic New file of that weight", arguments: [
        (Font.Weight.regular, InterfaceFace.regular),
        (.light, .regular),
        (.medium, .medium),
        (.semibold, .bold),
        (.bold, .bold),
        (.black, .bold)
    ])
    func interfaceFaceByWeight(weight: Font.Weight, expected: InterfaceFace) {
        #expect(InterfaceFace(weight: weight) == expected)
        #expect(Font.uiText(size: 16, weight: weight) == Font.custom(expected.rawValue, size: 16, relativeTo: .body))
    }

    @Test("Interface tokens use Bold for headings, Medium for body and Regular for captions")
    func interfaceTokens() {
        #expect(Font.nichijiTitle == Font.custom("ZenKakuGothicNew-Bold", size: 28, relativeTo: .title))
        #expect(Font.nichijiHeading == Font.custom("ZenKakuGothicNew-Bold", size: 20, relativeTo: .headline))
        #expect(Font.nichijiBody == Font.custom("ZenKakuGothicNew-Medium", size: 16, relativeTo: .body))
        #expect(Font.nichijiCallout == Font.custom("ZenKakuGothicNew-Medium", size: 14, relativeTo: .callout))
        #expect(Font.nichijiCaption == Font.custom("ZenKakuGothicNew-Regular", size: 12, relativeTo: .caption))
    }

    @Test("Each kanji token picks the font for its style", arguments: KanjiFontStyle.allCases)
    func kanjiTokensFollowStyle(style: KanjiFontStyle) {
        for token in KanjiFontToken.allCases {
            #expect(Font.kanji(token, style: style) == Font.custom(style.postScriptName, size: token.size, relativeTo: token.textStyle))
        }
        #expect(Font.kanjiDisplay(size: 80, style: style) == Font.custom(style.postScriptName, size: 80, relativeTo: .title))
        #expect(Font.kanjiGuide(size: 200, style: style) == Font.custom(style.postScriptName, fixedSize: 200))
    }
}

/*-------------------------------kanji-style-store----------------------------*/

@Suite("Kanji font style store Tests", .serialized)
struct KanjiFontStyleStoreTests {
    @Test("The style defaults to serif and persists to the suite")
    func persists() throws {
        let suiteName = "com.aten.nichiji.tests.kanjistyle.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = KanjiFontStyleStore(defaults: defaults)
        #expect(store.style == .serif)

        store.select(.gothic)
        #expect(store.style == .gothic)
        #expect(KanjiFontStyleStore(defaults: defaults).style == .gothic)

        defaults.set("serif", forKey: LearnerPreferenceKey.kanjiFontStyle.rawValue)
        store.reload()
        #expect(store.style == .serif)
    }

    @Test("An unknown saved value falls back to serif")
    func unknownValue() throws {
        let suiteName = "com.aten.nichiji.tests.kanjistyle.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("comic", forKey: LearnerPreferenceKey.kanjiFontStyle.rawValue)
        #expect(KanjiFontStyleStore(defaults: defaults).style == .serif)
    }

    @Test("Reading a kanji token in a view body is tracked, so a style change re-renders it")
    func tokensAreObservable() {
        let store = KanjiFontStyleStore.shared
        let original = store.style
        defer { store.select(original) }
        store.select(.serif)

        var changed = false
        withObservationTracking {
            _ = Font.kanjiHero
        } onChange: {
            changed = true
        }
        store.select(.gothic)
        #expect(changed)
    }
}
