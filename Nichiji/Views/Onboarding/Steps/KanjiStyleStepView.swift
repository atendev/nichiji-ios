import SwiftUI

/*------------------------------kanji-style-------------------------------*/

/// Onboarding step right after Welcome: 直 in both styles with the saved one preselected, so Continue keeps the default.
public struct KanjiStyleStepView: View {
    public let onNext: () -> Void

    @Environment(\.serviceContainer) private var services

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    public var body: some View {
        OnboardingStepScaffold(buttonTitle: "Continue", action: onNext) {
            VStack(spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Pick your kanji style",
                    subtitle: "This is how the big kanji look. You can change it later in Settings."
                )

                KanjiStyleCards(selected: KanjiFontStyleStore.shared.style) { style in
                    KanjiFontStyleStore.shared.choose(style, widgetRefresher: services?.widgetRefresher)
                }
            }
        }
    }
}
