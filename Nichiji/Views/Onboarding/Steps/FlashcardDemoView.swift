import SwiftUI

/*-----------------------------flashcard-demo-----------------------------*/

/// Static 山 practice card. Nothing here is written to the learner store.
public struct FlashcardDemoView: View {
    public let onNext: () -> Void

    @State private var isFlipped = false
    @State private var pendingAnswer: ReviewAnswer?

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    public var body: some View {
        OnboardingStepScaffold(buttonTitle: "Continue", action: onNext) {
            VStack(spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Flashcards",
                    subtitle: isFlipped
                        ? "Swipe right for Got it, left for Forgot it."
                        : "Tap the card to flip it.",
                    reservedSubtitleLines: 2
                )

                card

                FlashcardAnswerButtons(isEnabled: isFlipped && pendingAnswer == nil) { answer in
                    pendingAnswer = answer
                }
            }
        }
    }

    private var card: some View {
        SwipeFlashcard(
            isFlipped: $isFlipped,
            pendingAnswer: $pendingAnswer,
            accessibilityLabel: isFlipped ? "山, mountain, read san or yama" : "Flashcard, 山",
            onAnswer: { _ in true },
            front: { front },
            back: { back }
        )
        .frame(maxWidth: 280)
    }

    private var front: some View {
        cardFace {
            Text("山")
                .font(.kanjiDisplay(size: 96))
                .foregroundColor(.nichijiInk)

            Text("Tap to flip")
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkSubtle)
        }
    }

    private var back: some View {
        cardFace {
            Text("山")
                .font(.kanjiDisplay(size: 56))
                .foregroundColor(.nichijiInk)

            Text("mountain")
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)

            Text("サン · やま")
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
        }
    }

    private func cardFace<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        KanjiCard {
            VStack(spacing: LayoutTokens.space12) {
                content()
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }
}
