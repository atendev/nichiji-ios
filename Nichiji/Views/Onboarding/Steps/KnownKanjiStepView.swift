import SwiftUI

/*-----------------------------known-kanji-step---------------------------*/

/// Optional step after level selection. Skipping it changes nothing.
struct KnownKanjiStepView: View {
    let onNext: () -> Void

    @Environment(\.serviceContainer) private var services
    @State private var isPicking = false

    /// Marking writes through the service container, so without one only Continue shows.
    static func showsChooseButton(hasServices: Bool) -> Bool {
        hasServices
    }

    var body: some View {
        OnboardingStepScaffold(buttonTitle: "Continue", action: onNext) {
            VStack(spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Already know some kanji?",
                    subtitle: "Mark them and your daily kanji start with the ones you don't know yet. Skip this and change it any time in Settings."
                )

                if Self.showsChooseButton(hasServices: services != nil) {
                    SecondaryButton(title: "Choose kanji I know") {
                        isPicking = true
                    }
                }
            }
        }
        .sheet(isPresented: $isPicking) {
            NavigationStack {
                KnownKanjiPickerView()
            }
        }
    }
}
