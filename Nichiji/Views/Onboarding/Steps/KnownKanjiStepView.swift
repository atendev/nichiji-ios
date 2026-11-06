import SwiftUI

/*-----------------------------known-kanji-step---------------------------*/

/// Optional step after level selection. Easier levels are marked known when it appears; skipping keeps those marks.
struct KnownKanjiStepView: View {
    let onNext: () -> Void

    @Environment(\.serviceContainer) private var services
    @State private var isPicking = false
    /// Starts true so the buttons never show enabled before the marking begins.
    @State private var isMarking = true
    @State private var hasEasierLevels = false

    /// Marking writes through the service container, so without one only Continue shows.
    static func showsChooseButton(hasServices: Bool) -> Bool {
        hasServices
    }

    static func subtitle(hasEasierLevels: Bool) -> String {
        hasEasierLevels
            ? "Kanji from the levels below yours are already marked. Mark any others you know. Change it any time in Settings."
            : "Mark them and your daily kanji start with the ones you don't know yet. Skip this and change it any time in Settings."
    }

    var body: some View {
        OnboardingStepScaffold(buttonTitle: "Continue", isButtonEnabled: !isMarking, action: onNext) {
            VStack(spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Already know some kanji?",
                    subtitle: Self.subtitle(hasEasierLevels: hasEasierLevels)
                )

                if Self.showsChooseButton(hasServices: services != nil) {
                    SecondaryButton(title: "Choose kanji I know") {
                        isPicking = true
                    }
                    .disabled(isMarking)
                }
            }
        }
        .sheet(isPresented: $isPicking) {
            NavigationStack {
                KnownKanjiPickerView()
            }
        }
        .task {
            await markEasierLevels()
        }
    }

    /// Runs each time the step appears, so going back and picking another level re-marks. A replay also re-picks today's kanji.
    private func markEasierLevels() async {
        guard let services else {
            isMarking = false
            return
        }
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        let preferences = LearnerPreferencesSnapshot.load(from: defaults)
        hasEasierLevels = AutoKnownLevels.hasEasierLevels(preferences)
        isMarking = true
        if preferences.hasCompletedOnboarding {
            _ = try? await services.applyLevelPick(preferences: preferences)
        } else {
            try? await services.markEasierLevelsKnown(preferences: preferences)
        }
        isMarking = false
    }
}
