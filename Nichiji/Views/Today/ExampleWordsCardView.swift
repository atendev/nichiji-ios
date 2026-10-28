import SwiftUI

/*--------------------------------examples--------------------------------*/

public struct ExampleWordsCardView: View {
    public let words: [ExampleWord]
    public let showsRomaji: Bool
    public let onPlayAudio: (ExampleWord) -> Void

    public init(
        words: [ExampleWord] = [],
        showsRomaji: Bool = true,
        onPlayAudio: @escaping (ExampleWord) -> Void = { _ in }
    ) {
        self.words = words
        self.showsRomaji = showsRomaji
        self.onPlayAudio = onPlayAudio
    }

    public var body: some View {
        KanjiCard {
            VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                Text("Example words")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                if words.isEmpty {
                    Text("No example words available.")
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkSubtle)
                } else {
                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                            HStack(alignment: .top) {
                                Text(word.word)
                                    .font(.nichijiBody.bold())
                                    .foregroundColor(.nichijiInk)

                                Text(word.kana)
                                    .font(.nichijiCallout)
                                    .foregroundColor(.nichijiInkMuted)

                                Spacer()

                                Button {
                                    onPlayAudio(word)
                                } label: {
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundColor(.nichijiInkMuted)
                                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                                }
                                .minTouchTarget()
                                .disabled(word.kana.isEmpty)
                                .accessibilityLabel("Play \(word.word)")
                                .accessibilityHint("Speaks the kana reading")
                            }

                            if showsRomaji, !word.romaji.isEmpty {
                                Text(word.romaji)
                                    .font(.nichijiCaption)
                                    .foregroundColor(.nichijiInkMuted)
                            }
                            Text(word.meaning)
                                .font(.nichijiCallout)
                                .foregroundColor(.nichijiInkSubtle)
                        }

                        // Dividers sit between rows only, never after the last row.
                        if index < words.count - 1 {
                            Divider().background(Color.nichijiHairline)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LayoutTokens.space16)
    }
}
