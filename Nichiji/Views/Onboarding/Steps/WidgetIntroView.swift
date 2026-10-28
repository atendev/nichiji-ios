import SwiftUI

/*------------------------------widget-intro------------------------------*/

public struct WidgetIntroView: View {
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
                KanjiCard {
                    VStack(spacing: LayoutTokens.space8) {
                        Text("川")
                            .font(.kanjiDisplay(size: 64))
                            .foregroundColor(.nichijiInk)

                        Text("river")
                            .font(.nichijiCallout)
                            .foregroundColor(.nichijiInkMuted)
                    }
                    .frame(width: 140, height: 140)
                }

                Text("Home screen widget")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("See today's kanji directly on your home screen and mark it learned without opening the app.")
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

// TODO: Present an accurate mini widget graphic with interactive Got it button preview in Slice 9.
