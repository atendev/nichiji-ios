import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/*---------------------------------colors---------------------------------*/

public extension Color {
    // Semantic surfaces adapting to Washi light and Sumi dark themes.
    static let nichijiSurface = dynamicColor(lightHex: "#f4eee2", darkHex: "#15130f")
    static let nichijiSurfaceRaised = dynamicColor(lightHex: "#fbf7ee", darkHex: "#1f1c16")
    static let nichijiSurfaceSunken = dynamicColor(lightHex: "#eae2d1", darkHex: "#0f0d0a")

    // Ink text and line hierarchies.
    static let nichijiInk = dynamicColor(lightHex: "#1f1b16", darkHex: "#efe8d8")
    static let nichijiInkMuted = dynamicColor(lightHex: "#5e5548", darkHex: "#a89f8e")
    static let nichijiInkSubtle = dynamicColor(lightHex: "#74695a", darkHex: "#928a7a")
    static let nichijiHairline = dynamicColor(lightHex: "#d9cfbc", darkHex: "#35302a")
    static let nichijiBorderControl = dynamicColor(lightHex: "#8c8068", darkHex: "#7d7566")

    // Hanko vermilion accent colors.
    static let nichijiVermilion = dynamicColor(lightHex: "#b8321d", darkHex: "#e8603f")
    static let nichijiVermilionHover = dynamicColor(lightHex: "#9c2915", darkHex: "#f07a5c")
    static let nichijiOnVermilion = dynamicColor(lightHex: "#ffffff", darkHex: "#15130f")
    static let nichijiVermilionWash = dynamicColor(lightHex: "#f7e6de", darkHex: "#321913")

    // Status badges and review indicators.
    static let nichijiMatcha = dynamicColor(lightHex: "#3f6b3a", darkHex: "#8db483")
    static let nichijiMatchaWash = dynamicColor(lightHex: "#dce5d0", darkHex: "#202b1d")
    static let nichijiMustard = dynamicColor(lightHex: "#a67300", darkHex: "#e0b04a")
    static let nichijiMustardText = dynamicColor(lightHex: "#7d5600", darkHex: "#e0b04a")
    static let nichijiMustardWash = dynamicColor(lightHex: "#f6e8bd", darkHex: "#2e2410")

    // Information and focus ring colors.
    static let nichijiIndigo = dynamicColor(lightHex: "#2f4a6b", darkHex: "#8faad0")
    static let nichijiIndigoWash = dynamicColor(lightHex: "#d8dfe8", darkHex: "#1d2633")
    static let nichijiFocusRing = dynamicColor(lightHex: "#2f4a6b", darkHex: "#8faad0")

    private static func dynamicColor(lightHex: String, darkHex: String) -> Color {
        #if canImport(UIKit)
        let uiColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(hex: darkHex)
            } else {
                return UIColor(hex: lightHex)
            }
        }
        return Color(uiColor: uiColor)
        #else
        return Color(hex: lightHex)
        #endif
    }
}

/*---------------------------------helpers--------------------------------*/

#if canImport(UIKit)
public extension UIColor {
    convenience init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
#endif
