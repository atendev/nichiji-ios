import SwiftUI

/*----------------------------------hero----------------------------------*/

public struct KanjiHeroView: View {
    public let kanji: String
    public let primaryMeaning: String
    public let onPlayAudio: () -> Void
    @Environment(\.sizeCategory) private var sizeCategory

    public init(kanji: String, primaryMeaning: String, onPlayAudio: @escaping () -> Void) {
        self.kanji = kanji
        self.primaryMeaning = primaryMeaning
        self.onPlayAudio = onPlayAudio
    }

    public var body: some View {
        VStack(spacing: LayoutTokens.space16) {
            Text(kanji)
                .font(sizeCategory.isAccessibilityCategory ? .kanjiHeroCompact : .kanjiHero)
                .foregroundColor(.nichijiInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: LayoutTokens.space8) {
                Text(primaryMeaning)
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Button(action: onPlayAudio) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.nichijiInkMuted)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
                .minTouchTarget()
                .accessibilityLabel("Play pronunciation")
                .accessibilityHint("Speaks the kana reading")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutTokens.space24)
    }
}
