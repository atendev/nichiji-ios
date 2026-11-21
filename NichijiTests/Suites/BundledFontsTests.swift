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

    @Test("Bold Text moves each interface face one weight up and Bold stays Bold", arguments: [
        (InterfaceFace.regular, InterfaceFace.medium),
        (.medium, .bold),
        (.bold, .bold)
    ])
    func boldTextStepsUp(face: InterfaceFace, expected: InterfaceFace) {
        #expect(face.steppedUp == expected)
        #expect(face.resolved(boldText: true) == expected)
        #expect(face.resolved(boldText: false) == face)
    }

    @Test("Interface tokens step up one weight while Bold Text is on")
    func interfaceTokensWithBoldText() {
        let store = BoldTextStore.shared
        let original = store.isEnabled
        defer { store.update(isEnabled: original) }

        store.update(isEnabled: false)
        #expect(Font.nichijiCaption == Font.custom("ZenKakuGothicNew-Regular", size: 12, relativeTo: .caption))

        store.update(isEnabled: true)
        #expect(Font.nichijiTitle == Font.custom("ZenKakuGothicNew-Bold", size: 28, relativeTo: .title))
        #expect(Font.nichijiHeading == Font.custom("ZenKakuGothicNew-Bold", size: 20, relativeTo: .headline))
        #expect(Font.nichijiBody == Font.custom("ZenKakuGothicNew-Bold", size: 16, relativeTo: .body))
        #expect(Font.nichijiCallout == Font.custom("ZenKakuGothicNew-Bold", size: 14, relativeTo: .callout))
        #expect(Font.nichijiCaption == Font.custom("ZenKakuGothicNew-Medium", size: 12, relativeTo: .caption))
        #expect(Font.uiText(size: 16, weight: .regular) == Font.custom("ZenKakuGothicNew-Medium", size: 16, relativeTo: .body))
        #expect(Font.uiText(size: 16, weight: .medium) == Font.custom("ZenKakuGothicNew-Bold", size: 16, relativeTo: .body))
        #expect(UIFont.nichijiTypedBody.fontName == "ZenKakuGothicNew-Medium")
    }

    @Test("Typed search text draws in Medium when Bold Text is on")
    func typedBodyWithBoldText() {
        #expect(UIFont.nichijiTypedBody(boldText: false).fontName == "ZenKakuGothicNew-Regular")
        #expect(UIFont.nichijiTypedBody(boldText: true).fontName == "ZenKakuGothicNew-Medium")
    }

    @Test("Reading an interface token in a view body is tracked, so turning Bold Text on re-renders it")
    func interfaceTokensAreObservable() {
        let store = BoldTextStore.shared
        let original = store.isEnabled
        defer { store.update(isEnabled: original) }
        store.update(isEnabled: false)

        let flag = ChangeFlag()
        withObservationTracking {
            _ = Font.nichijiBody
        } onChange: {
            flag.set()
        }
        store.update(isEnabled: true)
        #expect(flag.isSet)
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

/// The `onChange` closure of `withObservationTracking` is `@Sendable`, so it cannot mutate a captured local.
private final class ChangeFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var isSet: Bool { lock.withLock { value } }

    func set() { lock.withLock { value = true } }
}

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

        let flag = ChangeFlag()
        withObservationTracking {
            _ = Font.kanjiHero
        } onChange: {
            flag.set()
        }
        store.select(.gothic)
        #expect(flag.isSet)
    }
}

/*-------------------------------bold-text-store------------------------------*/

@Suite("Bold text store Tests", .serialized)
struct BoldTextStoreTests {
    // Tests that touch `BoldTextStore.shared` live in `BundledFontsTests`, so one serialized suite owns the shared store.
    @Test("Bold Text starts off and follows updates")
    func updates() {
        let store = BoldTextStore()
        #expect(!store.isEnabled)
        store.update(isEnabled: true)
        #expect(store.isEnabled)
        store.update(isEnabled: false)
        #expect(!store.isEnabled)
    }
}
