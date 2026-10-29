import SwiftUI

/*--------------------------------scaffold--------------------------------*/

/// Scrollable, vertically centered step content with a pinned primary button.
struct OnboardingStepScaffold<Content: View>: View {
    let buttonTitle: String
    var isButtonEnabled: Bool = true
    var footnote: String?
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, LayoutTokens.screenMarginRegular)
                    .padding(.vertical, LayoutTokens.space16)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: LayoutTokens.space12) {
                PrimaryButton(title: buttonTitle, isEnabled: isButtonEnabled, action: action)

                if let footnote {
                    Text(footnote)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkSubtle)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.top, LayoutTokens.space8)
            .padding(.bottom, LayoutTokens.space16)
            .background(Color.nichijiSurface)
        }
    }
}

/*-------------------------------step-header------------------------------*/

/// Title and supporting line at the top of a step.
struct OnboardingStepHeader: View {
    let title: String
    let subtitle: String
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: LayoutTokens.space8) {
            Text(title)
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}
