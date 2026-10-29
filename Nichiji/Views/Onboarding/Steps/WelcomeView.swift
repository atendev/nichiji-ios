import SwiftUI

/*---------------------------------welcome--------------------------------*/

public struct WelcomeView: View {
    public let onNext: () -> Void

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    public var body: some View {
        OnboardingStepScaffold(
            buttonTitle: "Get started",
            footnote: "No account needed. Nichiji does not collect any data.",
            action: onNext
        ) {
            VStack(spacing: LayoutTokens.space24) {
                OnboardingLogo()

                VStack(spacing: LayoutTokens.space8) {
                    Text("Nichiji")
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)
                        .accessibilityAddTraits(.isHeader)

                    Text("One Kanji. One Day. Every Day.")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

/*----------------------------------logo----------------------------------*/

/// Seal and 日字 shown on the first and last steps.
struct OnboardingLogo: View {
    var body: some View {
        VStack(spacing: LayoutTokens.space24) {
            OnboardingSeal()

            Text("日字")
                .font(.kanjiDisplay(size: 80))
                .foregroundColor(.nichijiInk)
                .accessibilityLabel("Nichiji")
        }
    }
}

/// Vermilion hanko-style mark drawn from shapes, so no image asset is needed.
private struct OnboardingSeal: View {
    var body: some View {
        Text("日")
            .font(.kanjiDisplay(size: 34))
            .foregroundColor(.nichijiOnVermilion)
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .fill(Color.nichijiVermilion)
            )
            .rotationEffect(.degrees(-4))
            .accessibilityHidden(true)
    }
}
