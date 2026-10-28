import SwiftUI

/*----------------------------------ready---------------------------------*/

public struct ReadyView: View {
    public let onComplete: () -> Void
    public let onBack: () -> Void

    public init(onComplete: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: LayoutTokens.space24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.nichijiInk)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
                Spacer()
            }
            .padding(.horizontal, LayoutTokens.space16)

            Spacer()

            VStack(spacing: LayoutTokens.space16) {
                SealStamp(text: "Ready")

                Text("You're all set")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("Your daily kanji is waiting for you.")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInkMuted)
            }

            Spacer()

            PrimaryButton(title: "Start learning", action: onComplete)
                .padding(.horizontal, LayoutTokens.space24)
                .padding(.bottom, LayoutTokens.space32)
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Initialize first day assignment and mark onboarding complete in Slice 9.
