import SwiftUI

/*---------------------------------welcome--------------------------------*/

public struct WelcomeView: View {
    public let onNext: () -> Void

    public init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    public var body: some View {
        VStack(spacing: LayoutTokens.space24) {
            Spacer()

            Text("日字")
                .font(.kanjiDisplay(size: 80))
                .foregroundColor(.nichijiVermilion)

            VStack(spacing: LayoutTokens.space8) {
                Text("Nichiji")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("One Kanji. One Day. Every Day.")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInkMuted)
            }

            Spacer()

            VStack(spacing: LayoutTokens.space12) {
                PrimaryButton(title: "Get started", action: onNext)

                Text("No account needed. Nichiji does not collect any data.")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkSubtle)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LayoutTokens.space24)
            .padding(.bottom, LayoutTokens.space32)
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Display the custom seal mark asset alongside the Japanese title in Slice 9.
