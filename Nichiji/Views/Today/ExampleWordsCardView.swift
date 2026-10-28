import SwiftUI

/*--------------------------------examples--------------------------------*/

public struct ExampleWordsCardView: View {
    public let words: [ExampleWord]

    public init(words: [ExampleWord] = []) {
        self.words = words
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
                            HStack {
                                Text(word.word)
                                    .font(.nichijiBody.bold())
                                    .foregroundColor(.nichijiInk)

                                Text(word.kana)
                                    .font(.nichijiCallout)
                                    .foregroundColor(.nichijiInkMuted)

                                Spacer()
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

/*----------------------------------TODO----------------------------------*/

// TODO: Format kana, romaji transliteration, and audio pronunciation actions for example words in Slice 7.
