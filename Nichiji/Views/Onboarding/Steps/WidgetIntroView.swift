import SwiftUI

/*------------------------------widget-intro------------------------------*/

public struct WidgetIntroView: View {
    public let onNext: () -> Void

    private let steps = [
        "Touch and hold an empty spot on your home screen.",
        "Tap Edit, then Add Widget.",
        "Search for Nichiji and pick a size."
    ]

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    public var body: some View {
        OnboardingStepScaffold(buttonTitle: "Continue", action: onNext) {
            VStack(spacing: LayoutTokens.space32) {
                miniWidget

                OnboardingStepHeader(
                    title: "Home screen widget",
                    subtitle: "See today's kanji on your home screen and mark it learned without opening the app."
                )

                VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space12) {
                            Text("\(index + 1)")
                                .font(.uiText(size: 14, weight: .medium))
                                .foregroundColor(.nichijiVermilion)
                                .frame(width: 20, alignment: .leading)

                            Text(step)
                                .font(.nichijiBody)
                                .foregroundColor(.nichijiInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // TODO: Match this mock to the real small widget layout once Slice 11 lands.
    private var miniWidget: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text("TODAY")
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkSubtle)
                .kerning(0.6)

            Text("学")
                .font(.kanjiWidget)
                .foregroundColor(.nichijiInk)

            Text("study, learning")
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkMuted)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("Got it")
                .font(.uiText(size: 13, weight: .medium))
                .foregroundColor(.nichijiOnVermilion)
                .padding(.horizontal, LayoutTokens.space12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.nichijiVermilion))
        }
        .padding(LayoutTokens.space16)
        .frame(width: 160, height: 160, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusLarge, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusLarge, style: .continuous)
                .stroke(Color.nichijiHairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Widget preview showing today's kanji 学 with a Got it button")
    }
}
