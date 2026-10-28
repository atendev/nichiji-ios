import SwiftUI

/*-------------------------------typography-------------------------------*/

public extension Font {
    // Kanji display fonts using Shippori Mincho with system serif fallback.
    static var kanjiHero: Font {
        .custom("ShipporiMincho-Regular", size: 260, relativeTo: .largeTitle)
    }

    static var kanjiHeroCompact: Font {
        .custom("ShipporiMincho-Regular", size: 120, relativeTo: .largeTitle)
    }

    static var kanjiLarge: Font {
        .custom("ShipporiMincho-Regular", size: 64, relativeTo: .title)
    }

    static var kanjiWidget: Font {
        .custom("ShipporiMincho-Regular", size: 48, relativeTo: .title2)
    }

    static var kanjiWord: Font {
        .custom("ShipporiMincho-Regular", size: 18, relativeTo: .body)
    }

    static func kanjiDisplay(size: CGFloat) -> Font {
        .custom("ShipporiMincho-Regular", size: size, relativeTo: .title)
    }

    // Interface typography using Zen Kaku Gothic New with weights strictly <= 500.
    static var nichijiTitle: Font {
        .custom("ZenKakuGothicNew-Medium", size: 28, relativeTo: .title)
            .weight(.medium)
    }

    static var nichijiHeading: Font {
        .custom("ZenKakuGothicNew-Medium", size: 20, relativeTo: .headline)
            .weight(.medium)
    }

    static var nichijiBody: Font {
        .custom("ZenKakuGothicNew-Regular", size: 16, relativeTo: .body)
            .weight(.regular)
    }

    static var nichijiCallout: Font {
        .custom("ZenKakuGothicNew-Regular", size: 14, relativeTo: .callout)
            .weight(.regular)
    }

    static var nichijiCaption: Font {
        .custom("ZenKakuGothicNew-Regular", size: 12, relativeTo: .caption)
            .weight(.regular)
    }

    static func uiText(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Enforce maximum weight of 500 (medium).
        let safeWeight: Font.Weight = (weight == .bold || weight == .heavy || weight == .black) ? .medium : weight
        return .custom("ZenKakuGothicNew-Regular", size: size, relativeTo: .body)
            .weight(safeWeight)
    }
}
