import SwiftUI

/*-------------------------------daily-intro------------------------------*/

public struct DailyKanjiIntroView: View {
    public let onNext: () -> Void
    public let onBack: () -> Void

    public init(onNext: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.onNext = onNext
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
                Text("木")
                    .font(.kanjiDisplay(size: 100))
                    .foregroundColor(.nichijiInk)

                Text("One kanji a day")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("Each day you get a new kanji to learn with readings and example words to help you learn.")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutTokens.space24)
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onNext)
                .padding(.horizontal, LayoutTokens.space24)
                .padding(.bottom, LayoutTokens.space32)
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Add subtle card presentation styling to the daily kanji showcase preview in Slice 9.
