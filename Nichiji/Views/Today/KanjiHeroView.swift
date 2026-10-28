import SwiftUI

/*----------------------------------hero----------------------------------*/

public struct KanjiHeroView: View {
    public let kanji: String
    public let primaryMeaning: String
    public let onPlayAudio: () -> Void

    public init(kanji: String, primaryMeaning: String, onPlayAudio: @escaping () -> Void) {
        self.kanji = kanji
        self.primaryMeaning = primaryMeaning
        self.onPlayAudio = onPlayAudio
    }

    public var body: some View {
        VStack(spacing: LayoutTokens.space16) {
            Text(kanji)
                .font(.kanjiHero)
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutTokens.space24)
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Bind PronunciationService speech synthesis and audio button state in Slice 5 and Slice 7.
