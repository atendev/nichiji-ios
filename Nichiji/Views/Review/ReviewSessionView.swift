import SwiftUI

/*--------------------------------session---------------------------------*/

/// Full-screen flashcard session that ends on a summary.
struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: ReviewSessionModel
    @State private var isFlipped = false
    @State private var pendingAnswer: ReviewAnswer?
    @State private var showsSettings = false
    @State private var practiceTarget: PracticeTarget?

    init(services: ServiceContainer) {
        _model = State(initialValue: ReviewSessionModel(
            reviewService: services.reviewService,
            contentStore: services.contentStore,
            pronunciationService: services.pronunciationService,
            rebuildReminders: {
                let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
                try? await services.rebuildReminders(preferences: LearnerPreferencesSnapshot.load(from: defaults))
            }
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            phaseContent
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.bottom, LayoutTokens.space16)
        .background(Color.nichijiSurface.ignoresSafeArea())
        .sheet(
            isPresented: $showsSettings,
            onDismiss: { model.reloadPreferences() },
            content: { sessionSettings }
        )
        .practiceSheet(target: $practiceTarget)
        .task {
            await model.start()
        }
        .onChange(of: model.phase) { _, phase in
            guard phase == .finished else { return }
            Task { await model.endSession() }
        }
        .onChange(of: isFlipped) { _, flipped in
            guard flipped, let entry = model.currentEntry else { return }
            model.autoplay(for: entry)
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch model.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ReviewSessionMessage(
                title: "Could not start the review",
                message: message,
                buttonTitle: "Retry"
            ) {
                Task { await model.start() }
            }
        case .empty:
            ReviewSessionMessage(
                title: "Nothing to review",
                message: "Kanji you learn come back here when they are due.",
                buttonTitle: "Done",
                action: close
            )
        case .active:
            activeSession
        case .finished:
            ReviewSessionSummary(summary: model.deck.summary, onDone: close)
        }
    }

    private var sessionSettings: some View {
        NavigationStack {
            ReviewSettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showsSettings = false }
                    }
                }
        }
    }

    private var topBar: some View {
        HStack(spacing: LayoutTokens.space12) {
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.uiText(size: 20))
                    .foregroundColor(.nichijiInk)
                    .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
            }
            .minTouchTarget()
            .accessibilityLabel("Close review")

            if model.phase == .active {
                ProgressView(value: model.deck.progress)
                    .tint(.nichijiInk)
                    .accessibilityLabel("Review progress")
                Text(model.deck.counterLabel)
                    .font(.nichijiCallout)
                    .monospacedDigit()
                    .foregroundColor(.nichijiInkMuted)
            } else {
                Spacer()
            }

            Button {
                showsSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.nichijiInk)
                    .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
            }
            .minTouchTarget()
            .accessibilityLabel("Review settings")
        }
        .frame(minHeight: LayoutTokens.minHitTarget)
    }

    @ViewBuilder
    private var activeSession: some View {
        if let card = model.currentCard, let entry = model.currentEntry {
            let faces = ReviewCardFaces(
                entry: entry,
                type: card.type,
                showsExampleWord: model.preferences.showsExampleWord,
                onPlayAudio: { model.playReading(for: entry) },
                onPractice: { practiceTarget = model.practiceTarget(for: entry) },
                onFlip: { withAnimation(.easeInOut(duration: 0.2)) { isFlipped.toggle() } }
            )

            VStack(spacing: LayoutTokens.space16) {
                SwipeFlashcard(
                    isFlipped: $isFlipped,
                    pendingAnswer: $pendingAnswer,
                    accessibilityLabel: nil,
                    onAnswer: { await model.record($0) },
                    onSettled: { model.advance() },
                    front: { faces.front },
                    back: { faces.back }
                )
                .padding(.vertical, LayoutTokens.space24)

                VStack(spacing: LayoutTokens.space8) {
                    Text(model.notice ?? (isFlipped
                        ? "Swipe right if you got it, left if you forgot"
                        : "Flip the card, then swipe or tap a button"))
                        .font(.nichijiCallout)
                        .foregroundColor(model.notice == nil ? .nichijiInkMuted : .nichijiMustardText)
                        .multilineTextAlignment(.center)

                    FlashcardAnswerButtons(isEnabled: isFlipped && pendingAnswer == nil) { answer in
                        pendingAnswer = answer
                    }
                }
            }
        }
    }

    private func close() {
        Task { await model.endSession() }
        dismiss()
    }
}

/*--------------------------------summary---------------------------------*/

private struct ReviewSessionSummary: View {
    let summary: ReviewDeckSummary
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: LayoutTokens.space8) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.uiText(size: 32, weight: .medium))
                .foregroundColor(.nichijiMatcha)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.nichijiMatchaWash))
                .accessibilityHidden(true)
                .padding(.bottom, LayoutTokens.space16)

            Text("Review complete")
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)

            Text("\(summary.reviewed) reviewed · \(summary.gotIt) got it · \(summary.forgot) forgot")
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)

            if summary.forgot > 0 {
                Text("Kanji you forgot will come back tomorrow.")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkSubtle)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryButton(title: "Done", action: onDone)
        }
        .frame(maxWidth: .infinity)
    }
}

/*--------------------------------message---------------------------------*/

private struct ReviewSessionMessage: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: LayoutTokens.space16) {
            Spacer()
            Text(title)
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: buttonTitle, action: action)
        }
        .frame(maxWidth: .infinity)
    }
}
