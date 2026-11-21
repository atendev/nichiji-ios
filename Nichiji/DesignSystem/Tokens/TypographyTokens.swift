import SwiftUI

/*-------------------------------typefaces--------------------------------*/

public extension KanjiFontStyle {
    /// PostScript name of the font that draws the big kanji in this style. Serif is bundled; gothic is the system Japanese font, because a gothic file with every dataset kanji would blow the widget size budget.
    var postScriptName: String {
        switch self {
        case .serif: "ShipporiMincho-Regular"
        case .gothic: "HiraginoSans-W3"
        }
    }
}

/// The three bundled Zen Kaku Gothic New files for interface text. SwiftUI cannot change a custom font's weight, so the file is picked by weight.
public enum InterfaceFace: String, CaseIterable, Sendable {
    case regular = "ZenKakuGothicNew-Regular"
    case medium = "ZenKakuGothicNew-Medium"
    case bold = "ZenKakuGothicNew-Bold"

    /// Medium stays Medium, Semibold and heavier use Bold, anything lighter uses Regular.
    public init(weight: Font.Weight) {
        switch weight {
        case .medium: self = .medium
        case .semibold, .bold, .heavy, .black: self = .bold
        default: self = .regular
        }
    }
}

/// Size and Dynamic Type anchor of each big kanji display.
public enum KanjiFontToken: CaseIterable, Sendable {
    case hero
    case heroCompact
    case large
    case widget
    case word

    var size: CGFloat {
        switch self {
        case .hero: 260
        case .heroCompact: 120
        case .large: 64
        case .widget: 48
        case .word: 18
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .hero, .heroCompact: .largeTitle
        case .large: .title
        case .widget: .title2
        case .word: .body
        }
    }
}

/*-------------------------------typography-------------------------------*/

public extension Font {
    // Big kanji displays follow the learner's kanji style. Kanji inside interface text keep the interface font.
    static var kanjiHero: Font { kanji(.hero) }

    static var kanjiHeroCompact: Font { kanji(.heroCompact) }

    static var kanjiLarge: Font { kanji(.large) }

    static var kanjiWidget: Font { kanji(.widget) }

    static var kanjiWord: Font { kanji(.word) }

    static func kanji(_ token: KanjiFontToken, style: KanjiFontStyle = .current) -> Font {
        .custom(style.postScriptName, size: token.size, relativeTo: token.textStyle)
    }

    static func kanjiDisplay(size: CGFloat, style: KanjiFontStyle = .current) -> Font {
        .custom(style.postScriptName, size: size, relativeTo: .title)
    }

    // Fixed size so the practice guide always fits its pad, whatever the Dynamic Type setting.
    static func kanjiGuide(size: CGFloat, style: KanjiFontStyle = .current) -> Font {
        .custom(style.postScriptName, fixedSize: size)
    }

    // Interface typography using Zen Kaku Gothic New: Bold for titles and headings, Medium for body and callout, Regular for captions.
    static var nichijiTitle: Font {
        .custom(InterfaceFace.bold.rawValue, size: 28, relativeTo: .title)
    }

    static var nichijiHeading: Font {
        .custom(InterfaceFace.bold.rawValue, size: 20, relativeTo: .headline)
    }

    static var nichijiBody: Font {
        .custom(InterfaceFace.medium.rawValue, size: 16, relativeTo: .body)
    }

    static var nichijiCallout: Font {
        .custom(InterfaceFace.medium.rawValue, size: 14, relativeTo: .callout)
    }

    static var nichijiCaption: Font {
        .custom(InterfaceFace.regular.rawValue, size: 12, relativeTo: .caption)
    }

    // Typed text in a UIKit-backed field takes its kanji fallback from the device language, so the cascade names a Japanese font.
    static var nichijiTypedBody: Font {
        Font(UIFont.nichijiTypedBody as CTFont)
    }

    static func uiText(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(InterfaceFace(weight: weight).rawValue, size: size, relativeTo: .body)
    }
}
