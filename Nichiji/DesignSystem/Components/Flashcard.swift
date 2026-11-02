import SwiftUI

/*------------------------------swipe-rules-------------------------------*/

/// Swipe thresholds and tilt shared by the onboarding demo card and review sessions.
enum FlashcardSwipe {
    static let badgeThreshold: CGFloat = 40
    static let answerThreshold: CGFloat = 100

    /// Answer the badge previews while dragging. Cards only lean once flipped.
    static func previewAnswer(dragWidth: CGFloat, isFlipped: Bool) -> ReviewAnswer? {
        guard isFlipped else { return nil }
        if dragWidth > badgeThreshold { return .gotIt }
        if dragWidth < -badgeThreshold { return .forgotIt }
        return nil
    }

    /// Answer a released drag commits to, or nil when the card springs back.
    static func answer(releasedAt dragWidth: CGFloat, isFlipped: Bool) -> ReviewAnswer? {
        guard isFlipped else { return nil }
        if dragWidth > answerThreshold { return .gotIt }
        if dragWidth < -answerThreshold { return .forgotIt }
        return nil
    }

    // Capped so a fly-off does not spin the card.
    static func tiltDegrees(forOffset offset: CGFloat) -> Double {
        min(max(Double(offset) / 40, -10), 10)
    }
}

/*--------------------------------flashcard-------------------------------*/

/// Tap-to-flip card that answers by swipe or by setting `pendingAnswer`, then flies off and fades the next card up.
struct SwipeFlashcard<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    @Binding var pendingAnswer: ReviewAnswer?
    /// Label for a card read as one element. Nil leaves the faces' own controls reachable.
    let accessibilityLabel: String?
    /// Records the answer. Returning false keeps the card in place.
    let onAnswer: (ReviewAnswer) async -> Bool
    /// Runs while the card is hidden, so the next card's content swaps in unseen.
    let onSettled: () -> Void
    let front: Front
    let back: Back

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flipAngle: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var flyOffX: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var riseOffset: CGFloat = 0
    @State private var committedAnswer: ReviewAnswer?
    @State private var isResolving = false

    init(
        isFlipped: Binding<Bool>,
        pendingAnswer: Binding<ReviewAnswer?>,
        accessibilityLabel: String?,
        onAnswer: @escaping (ReviewAnswer) async -> Bool,
        onSettled: @escaping () -> Void = {},
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self._pendingAnswer = pendingAnswer
        self.accessibilityLabel = accessibilityLabel
        self.onAnswer = onAnswer
        self.onSettled = onSettled
        self.front = front()
        self.back = back()
    }

    private var canAnswer: Bool { isFlipped && !isResolving }

    private var displayedAnswer: ReviewAnswer? {
        committedAnswer ?? FlashcardSwipe.previewAnswer(dragWidth: dragOffset.width, isFlipped: isFlipped)
    }

    private var horizontalOffset: CGFloat { dragOffset.width + flyOffX }

    var body: some View {
        FlipCard(angle: flipAngle, rotates: !reduceMotion) {
            front
        } back: {
            back
        }
        .overlay(alignment: .top) {
            if let displayedAnswer {
                FlashcardVerdictBadge(answer: displayedAnswer)
                    .padding(.top, LayoutTokens.space16)
                    .transition(.opacity)
            }
        }
        .offset(x: horizontalOffset, y: dragOffset.height * 0.2 + riseOffset)
        .rotationEffect(.degrees(reduceMotion ? 0 : FlashcardSwipe.tiltDegrees(forOffset: horizontalOffset)))
        .opacity(cardOpacity)
        .onTapGesture { flip() }
        .gesture(dragGesture, including: canAnswer ? .all : .subviews)
        .modifier(FlashcardAccessibility(label: accessibilityLabel, isFlipped: isFlipped, flip: flip))
        .onChange(of: pendingAnswer) { _, answer in
            guard let answer else { return }
            resolve(answer)
        }
        .onChange(of: isFlipped) { _, flipped in
            // Keeps the face in step when the parent resets the card.
            let target: Double = flipped ? 180 : 0
            guard flipAngle != target, !isResolving else { return }
            flipAngle = target
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if let answer = FlashcardSwipe.answer(releasedAt: value.translation.width, isFlipped: isFlipped) {
                    // Routed through the binding so the parent's buttons disable during the fly-off.
                    pendingAnswer = answer
                } else {
                    springBack()
                }
            }
    }

    private func flip() {
        guard !isResolving else { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5)) {
            isFlipped.toggle()
            flipAngle = isFlipped ? 180 : 0
        }
    }

    private func springBack() {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.3)) {
            dragOffset = .zero
        }
    }

    private func resolve(_ answer: ReviewAnswer) {
        guard canAnswer else {
            pendingAnswer = nil
            return
        }
        isResolving = true
        withAnimation(.easeOut(duration: 0.15)) {
            committedAnswer = answer
        }

        Task {
            guard await onAnswer(answer) else {
                withAnimation(.easeOut(duration: 0.15)) { committedAnswer = nil }
                springBack()
                pendingAnswer = nil
                isResolving = false
                return
            }
            await flyOff(answer)
            settle()
        }
    }

    private func flyOff(_ answer: ReviewAnswer) async {
        if reduceMotion {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeInOut(duration: 0.2)) { cardOpacity = 0 }
            try? await Task.sleep(for: .milliseconds(200))
        } else {
            withAnimation(.easeIn(duration: 0.3)) {
                flyOffX = answer == .gotIt ? 600 : -600
            }
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    private func settle() {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            isFlipped = false
            flipAngle = 0
            dragOffset = .zero
            flyOffX = 0
            committedAnswer = nil
            cardOpacity = 0
            riseOffset = reduceMotion ? 0 : LayoutTokens.space16
            onSettled()
        }
        withAnimation(.easeOut(duration: 0.25)) {
            cardOpacity = 1
            riseOffset = 0
        }
        pendingAnswer = nil
        isResolving = false
    }
}

/// Reads a labelled card as one flip button; an unlabelled card keeps its faces' controls.
private struct FlashcardAccessibility: ViewModifier {
    let label: String?
    let isFlipped: Bool
    let flip: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if let label {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityHint(isFlipped ? "Use Got it or Forgot it below" : "Double tap to flip")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { flip() }
        } else {
            content.accessibilityElement(children: .contain)
        }
    }
}

/*--------------------------------flip-card-------------------------------*/

/// Two-faced card whose face follows the animated angle, so the swap lands when the card is edge-on.
private struct FlipCard<Front: View, Back: View>: View, @preconcurrency Animatable {
    var angle: Double
    let rotates: Bool
    let front: Front
    let back: Back

    init(
        angle: Double,
        rotates: Bool,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.angle = angle
        self.rotates = rotates
        self.front = front()
        self.back = back()
    }

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let progress = angle / 180
        let showsBack = angle >= 90

        ZStack {
            front
                .opacity(rotates ? (showsBack ? 0 : 1) : 1 - progress)
                .accessibilityHidden(showsBack)
                .allowsHitTesting(!showsBack)

            back
                .rotation3DEffect(.degrees(rotates ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(rotates ? (showsBack ? 1 : 0) : progress)
                .accessibilityHidden(!showsBack)
                .allowsHitTesting(showsBack)
        }
        .rotation3DEffect(
            .degrees(rotates ? angle : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
    }
}

/*---------------------------------verdict--------------------------------*/

extension ReviewAnswer {
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

    var textColor: Color {
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
    let answer: ReviewAnswer

    var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            Image(systemName: answer.systemImage)
                .foregroundColor(answer.tint)
            Text(answer.title)
                .font(.nichijiCallout.weight(.semibold))
                .foregroundColor(answer.textColor)
        }
        .padding(.horizontal, LayoutTokens.space12)
        .padding(.vertical, LayoutTokens.space8)
        .background(Capsule().fill(answer.wash))
        .overlay(Capsule().stroke(answer.tint, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/*-----------------------------answer-buttons-----------------------------*/

/// Forgot it and Got it buttons under a flashcard. Disabled until the card is flipped.
struct FlashcardAnswerButtons: View {
    let isEnabled: Bool
    let onAnswer: (ReviewAnswer) -> Void

    var body: some View {
        HStack(spacing: LayoutTokens.space12) {
            button(.forgotIt)
            button(.gotIt)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }

    private func button(_ answer: ReviewAnswer) -> some View {
        Button {
            onAnswer(answer)
        } label: {
            HStack(spacing: LayoutTokens.space8) {
                Image(systemName: answer.systemImage)
                    .foregroundColor(answer.tint)
                Text(answer.title)
                    .font(.uiText(size: 16, weight: .medium))
                    .foregroundColor(.nichijiInk)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiBorderControl)
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .accessibilityLabel(answer.title)
    }
}
