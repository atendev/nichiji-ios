import SwiftUI

/*-----------------------------flashcard-demo-----------------------------*/

public struct FlashcardDemoView: View {
    public let onNext: () -> Void
    public let onBack: () -> Void
    @State private var isFlipped: Bool = false
    @State private var cardOffset: CGSize = .zero

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

            VStack(spacing: LayoutTokens.space8) {
                Text("Flashcards")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("Tap to flip. Swipe right for Got it, left for Forgot it.")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInkMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LayoutTokens.space24)

            Spacer()

            KanjiCard {
                VStack(spacing: LayoutTokens.space16) {
                    Text("山")
                        .font(.kanjiDisplay(size: 80))
                        .foregroundColor(.nichijiInk)

                    if isFlipped {
                        Text("mountain · さん, やま")
                            .font(.nichijiBody)
                            .foregroundColor(.nichijiInkMuted)
                    } else {
                        Text("Tap to reveal")
                            .font(.nichijiCallout)
                            .foregroundColor(.nichijiInkSubtle)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
            .padding(.horizontal, LayoutTokens.space32)
            .offset(cardOffset)
            .onTapGesture {
                isFlipped.toggle()
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onNext)
                .padding(.horizontal, LayoutTokens.space24)
                .padding(.bottom, LayoutTokens.space32)
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Implement 3D card flip and swipe gesture physics with green matcha / yellow mustard badge overlays in Slice 9.
