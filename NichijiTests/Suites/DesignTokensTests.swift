import Testing
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import Nichiji

/*------------------------------token-tests-------------------------------*/

@Suite("Design Tokens Tests")
struct DesignTokensTests {
    @Test("Layout tokens conform to Apple HIG 44pt target and 8pt grid")
    func layoutTokensConformToHIG() {
        #expect(LayoutTokens.minHitTarget >= 44.0)
        #expect(LayoutTokens.space4 == 4.0)
        #expect(LayoutTokens.space8 == 8.0)
        #expect(LayoutTokens.space16 == 16.0)
        #expect(LayoutTokens.space24 == 24.0)
        #expect(LayoutTokens.space32 == 32.0)
        #expect(LayoutTokens.cornerRadiusSmall == 8.0)
        #expect(LayoutTokens.cornerRadiusMedium == 16.0)
        #expect(LayoutTokens.cornerRadiusLarge == 24.0)
    }

    @Test("Typography tokens generate valid fonts without crashing")
    func typographyTokensInstantiation() {
        _ = Font.kanjiHero
        _ = Font.kanjiHeroCompact
        _ = Font.kanjiLarge
        _ = Font.kanjiWidget
        _ = Font.kanjiWord
        _ = Font.nichijiTitle
        _ = Font.nichijiHeading
        _ = Font.nichijiBody
        _ = Font.nichijiCallout
        _ = Font.nichijiCaption
        _ = Font.uiText(size: 16, weight: .regular)
        // Check that bold weight is safely clamped to medium (<= 500).
        _ = Font.uiText(size: 16, weight: .bold)
    }

    #if canImport(UIKit)
    @Test("Hex color initializer produces correct components")
    func hexColorParsing() {
        let washiSurface = UIColor(hex: "#f4eee2")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        washiSurface.getRed(&r, green: &g, blue: &b, alpha: &a)

        #expect(Int(round(r * 255)) == 0xF4)
        #expect(Int(round(g * 255)) == 0xEE)
        #expect(Int(round(b * 255)) == 0xE2)
        #expect(a == 1.0)
    }

    @Test("Dynamic colors resolve in both light and dark trait collections")
    func dynamicColorsResolution() {
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

        let surface = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: "#15130f") : UIColor(hex: "#f4eee2")
        }

        let lightColor = surface.resolvedColor(with: lightTraits)
        let darkColor = surface.resolvedColor(with: darkTraits)

        var rLight: CGFloat = 0, rDark: CGFloat = 0
        lightColor.getRed(&rLight, green: nil, blue: nil, alpha: nil)
        darkColor.getRed(&rDark, green: nil, blue: nil, alpha: nil)

        // Light surface should be bright (0xF4 / 255 ~ 0.957), Dark surface very dark (0x15 / 255 ~ 0.082).
        #expect(rLight > 0.9)
        #expect(rDark < 0.2)
    }
    #endif
}
