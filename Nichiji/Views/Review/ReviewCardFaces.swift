import SwiftUI

/*---------------------------------faces----------------------------------*/

/// Prompt and answer sides of one review card, laid out by card type.
@MainActor
struct ReviewCardFaces {
    let entry: KanjiEntry
    let type: ReviewCardType
    let showsExampleWord: Bool
    let onPlayAudio: () -> Void
    let onPractice: () -> Void
    let onFlip: () -> Void

    var meaning: String {
        entry.meanings.prefix(2).joined(separator: ", ")
    }

    var reading: String {
        [entry.onyomi.first, entry.kunyomi.first].compactMap { $0?.kana }.joined(separator: " · ")
    }

    var prompt: String {
        switch type {
        case .kanjiToMeaning: "What does it mean?"
        case .kanjiToReading: "How do you read it?"
        case .meaningToKanji: "Which kanji is it?"
        }
    }

    var front: some View {
        ReviewCardSurface(onPlayAudio: onPlayAudio) {
            VStack(spacing: LayoutTokens.space16) {
                if type == .meaningToKanji {
                    Text(meaning)
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)
                        .multilineTextAlignment(.center)
                } else {
                    Text(entry.id)
                        .font(.kanjiDisplay(size: 150))
                        .foregroundColor(.nichijiInk)
                        .minimumScaleFactor(0.5)
                }
                Text(prompt)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Double tap to flip")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onFlip() }
        }
    }

    var back: some View {
        ReviewCardSurface(onPlayAudio: onPlayAudio) {
            VStack(spacing: LayoutTokens.space16) {
                VStack(spacing: LayoutTokens.space8) {
                    Text(entry.id)
                        .font(.kanjiDisplay(size: type == .meaningToKanji ? 120 : 56))
                        .foregroundColor(.nichijiInk)
                        .minimumScaleFactor(0.5)
                    answerLines
                }
                .accessibilityElement(children: .combine)

                if showsExampleWord, let word = entry.exampleWords.first {
                    Divider().overlay(Color.nichijiHairline)
                    exampleWord(word)
                }

                ReviewPracticeButton(action: onPractice)
            }
        }
    }

    @ViewBuilder
    private var answerLines: some View {
        if type == .kanjiToReading {
            Text(meaning)
                .font(.uiText(size: 20))
                .foregroundColor(.nichijiInkMuted)
            Text(reading)
                .font(.uiText(size: 24, weight: .medium))
                .foregroundColor(.nichijiInk)
        } else {
            Text(reading)
                .font(.uiText(size: 20))
                .foregroundColor(.nichijiInkMuted)
            Text(meaning)
                .font(.uiText(size: 20, weight: .medium))
                .foregroundColor(.nichijiInk)
                .multilineTextAlignment(.center)
        }
    }

    private func exampleWord(_ word: ExampleWord) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space12) {
                exampleWordParts(word)
            }
            VStack(spacing: LayoutTokens.space4) {
                exampleWordParts(word)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func exampleWordParts(_ word: ExampleWord) -> some View {
        Text(word.word)
            .font(.kanjiWord)
            .foregroundColor(.nichijiInk)
        Text(word.kana)
            .font(.nichijiCallout)
            .foregroundColor(.nichijiInkMuted)
        Text(word.meaning)
            .font(.nichijiCallout)
            .foregroundColor(.nichijiInkMuted)
    }
}

/*--------------------------------surface---------------------------------*/

/// Full-size card with the speaker at the top right. Content scrolls when large text does not fit.
private struct ReviewCardSurface<Content: View>: View {
    let onPlayAudio: () -> Void
    let content: Content

    init(onPlayAudio: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onPlayAudio = onPlayAudio
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            centered
            ScrollView(showsIndicators: false) {
                centered
            }
        }
        .padding(.horizontal, LayoutTokens.space24)
        .padding(.vertical, LayoutTokens.space48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusLarge, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusLarge, style: .continuous)
                .stroke(Color.nichijiBorderControl, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Button(action: onPlayAudio) {
                Image(systemName: "speaker.wave.2")
                    .font(.uiText(size: 20))
                    .foregroundColor(.nichijiInk)
                    .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
            }
            .minTouchTarget()
            .padding(LayoutTokens.space8)
            .accessibilityLabel("Play reading")
        }
    }

    private var centered: some View {
        content
            .frame(maxWidth: .infinity)
    }
}

/*--------------------------------practice--------------------------------*/

/// "Practice this kanji" with a thick dashed outline and no fill.
private struct ReviewPracticeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Practice this kanji", systemImage: "pencil")
                .font(.uiText(size: 16, weight: .medium))
                .foregroundColor(.nichijiInk)
                .padding(.horizontal, LayoutTokens.space16)
                .frame(minHeight: LayoutTokens.minHitTarget)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                        .stroke(Color.nichijiBorderControl, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                )
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .padding(.top, LayoutTokens.space8)
    }
}
