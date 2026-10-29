import SwiftUI

/*-----------------------------flashcard-demo-----------------------------*/

/// Static 山 practice card. Nothing here is written to the learner store.
public struct FlashcardDemoView: View {
    public let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var flyOffX: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var verdict: FlashcardVerdict?
    @State private var isResolving = false

    private let badgeThreshold: CGFloat = 40
    private let swipeThreshold: CGFloat = 100

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    private var canAnswer: Bool { isFlipped && !isResolving }

    private var displayedVerdict: FlashcardVerdict? {
        if let verdict { return verdict }
        if dragOffset.width > badgeThreshold { return .gotIt }
        if dragOffset.width < -badgeThreshold { return .forgotIt }
        return nil
    }

    private var horizontalOffset: CGFloat { dragOffset.width + flyOffX }

    // Swaps faces when the card is edge-on, about halfway through the flip.
    private var faceSwapAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .linear(duration: 0.01).delay(0.2)
    }

    public var body: some View {
        OnboardingStepScaffold(buttonTitle: "Continue", action: onNext) {
            VStack(spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Flashcards",
                    subtitle: isFlipped
                        ? "Swipe right for Got it, left for Forgot it."
                        : "Tap the card to flip it."
                )

                card

                answerButtons
            }
        }
    }

    // MARK: - Card

    private var card: some View {
        ZStack {
            cardFace {
                Text("山")
                    .font(.kanjiDisplay(size: 96))
                    .foregroundColor(.nichijiInk)

                Text("Tap to flip")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkSubtle)
            }
            .opacity(isFlipped ? 0 : 1)
            .animation(faceSwapAnimation, value: isFlipped)

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
            .opacity(isFlipped ? 1 : 0)
            .animation(faceSwapAnimation, value: isFlipped)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(
            .degrees(isFlipped && !reduceMotion ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .overlay(alignment: .top) {
            if let displayedVerdict {
                FlashcardVerdictBadge(verdict: displayedVerdict)
                    .padding(.top, LayoutTokens.space16)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: 280)
        .offset(x: horizontalOffset, y: dragOffset.height * 0.2)
        .rotationEffect(.degrees(reduceMotion ? 0 : Double(horizontalOffset) / 20))
        .opacity(cardOpacity)
        .onTapGesture { flip() }
        .gesture(dragGesture, including: canAnswer ? .all : .subviews)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? "山, mountain, read san or yama" : "Flashcard, 山")
        .accessibilityHint(isFlipped ? "Use Got it or Forgot it below" : "Double tap to flip")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { flip() }
    }

    private func cardFace<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        KanjiCard {
            VStack(spacing: LayoutTokens.space12) {
                content()
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    resolve(.gotIt)
                } else if value.translation.width < -swipeThreshold {
                    resolve(.forgotIt)
                } else {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.3)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - Answer buttons

    private var answerButtons: some View {
        HStack(spacing: LayoutTokens.space12) {
            answerButton(.forgotIt)
            answerButton(.gotIt)
        }
        .disabled(!canAnswer)
        .opacity(canAnswer ? 1 : 0.5)
    }

    private func answerButton(_ verdict: FlashcardVerdict) -> some View {
        Button {
            resolve(verdict)
        } label: {
            HStack(spacing: LayoutTokens.space8) {
                Image(systemName: verdict.systemImage)
                    .foregroundColor(verdict.tint)
                Text(verdict.title)
                    .font(.uiText(size: 16, weight: .medium))
                    .foregroundColor(.nichijiInk)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiBorderControl)
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .accessibilityLabel(verdict.title)
    }

    // MARK: - Actions

    private func flip() {
        guard !isResolving else { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5)) {
            isFlipped.toggle()
        }
    }

    private func resolve(_ newVerdict: FlashcardVerdict) {
        guard canAnswer else { return }
        isResolving = true
        withAnimation(.easeOut(duration: 0.15)) {
            verdict = newVerdict
        }

        Task {
            if reduceMotion {
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.easeInOut(duration: 0.2)) {
                    cardOpacity = 0
                }
                try? await Task.sleep(for: .milliseconds(200))
            } else {
                withAnimation(.easeIn(duration: 0.3)) {
                    flyOffX = newVerdict == .gotIt ? 600 : -600
                }
                try? await Task.sleep(for: .milliseconds(300))
            }

            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) {
                isFlipped = false
                dragOffset = .zero
                flyOffX = 0
                verdict = nil
                cardOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.2)) {
                cardOpacity = 1
            }
            isResolving = false
        }
    }
}

/*---------------------------------verdict--------------------------------*/

private enum FlashcardVerdict {
    case gotIt
    case forgotIt

    var title: String {
        switch self {
        case .gotIt: "Got it"
        case .forgotIt: "Forgot it"
        }
    }

    var systemImage: String {
        switch self {
        case .gotIt: "checkmark.circle.fill"
        case .forgotIt: "questionmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .gotIt: .nichijiMatcha
        case .forgotIt: .nichijiMustard
        }
    }

    var text: Color {
        switch self {
        case .gotIt: .nichijiMatcha
        case .forgotIt: .nichijiMustardText
        }
    }

    var wash: Color {
        switch self {
        case .gotIt: .nichijiMatchaWash
        case .forgotIt: .nichijiMustardWash
        }
    }
}

private struct FlashcardVerdictBadge: View {
    let verdict: FlashcardVerdict

    var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            Image(systemName: verdict.systemImage)
                .foregroundColor(verdict.tint)
            Text(verdict.title)
                .font(.nichijiCallout.weight(.semibold))
                .foregroundColor(verdict.text)
        }
        .padding(.horizontal, LayoutTokens.space12)
        .padding(.vertical, LayoutTokens.space8)
        .background(Capsule().fill(verdict.wash))
        .overlay(Capsule().stroke(verdict.tint, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
