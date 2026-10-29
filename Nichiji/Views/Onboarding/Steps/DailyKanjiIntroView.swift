import SwiftUI

/*-------------------------------daily-intro------------------------------*/

public struct DailyKanjiIntroView: View {
    public let onNext: () -> Void

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    public var body: some View {
        OnboardingStepScaffold(buttonTitle: "Continue", action: onNext) {
            VStack(spacing: LayoutTokens.space32) {
                KanjiCard {
                    VStack(spacing: LayoutTokens.space8) {
                        Text("木")
                            .font(.kanjiDisplay(size: 96))
                            .foregroundColor(.nichijiInk)

                        Text("tree, wood")
                            .font(.nichijiCallout)
                            .foregroundColor(.nichijiInkMuted)

                        Text("モク · き")
                            .font(.nichijiCaption)
                            .foregroundColor(.nichijiInkSubtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutTokens.space8)
                }
                .frame(maxWidth: 240)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Sample kanji 木, meaning tree or wood, read moku or ki")

                OnboardingStepHeader(
                    title: "One kanji a day",
                    subtitle: "Each day you get a new kanji to learn with readings and example words to help you learn."
                )
            }
        }
    }
}
