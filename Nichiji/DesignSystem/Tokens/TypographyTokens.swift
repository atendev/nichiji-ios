import SwiftUI

/*-------------------------------typography-------------------------------*/

public extension Font {
    // Large 260pt kanji display used on Today hero and detail views.
    static var kanjiHero: Font {
        .custom("ShipporiMincho-Regular", size: 260, relativeTo: .largeTitle)
    }

    // Secondary kanji glyph sizes for cards, lists, and grids.
    static func kanjiDisplay(size: CGFloat) -> Font {
        .custom("ShipporiMincho-Regular", size: size, relativeTo: .title)
    }

    // Primary interface font using Zen Kaku Gothic New with system fallback.
    static func uiText(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("ZenKakuGothicNew-Regular", size: size, relativeTo: .body)
            .weight(weight)
    }

    // Standardized typography scale matching Apple Dynamic Type sizes.
    static var nichijiTitle: Font {
        .custom("ZenKakuGothicNew-Medium", size: 22, relativeTo: .title2)
    }

    static var nichijiBody: Font {
        .custom("ZenKakuGothicNew-Regular", size: 16, relativeTo: .body)
    }

    static var nichijiCallout: Font {
        .custom("ZenKakuGothicNew-Regular", size: 14, relativeTo: .callout)
    }

    static var nichijiCaption: Font {
        .custom("ZenKakuGothicNew-Regular", size: 12, relativeTo: .caption)
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Register custom TTF font files into the app bundle and configure fallback to system serif and sans-serif in Slice 1.
