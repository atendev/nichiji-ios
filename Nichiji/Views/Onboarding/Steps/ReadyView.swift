import SwiftUI

/*----------------------------------ready---------------------------------*/

public struct ReadyView: View {
    public let isCompleting: Bool
    public let onComplete: () -> Void

    public init(isCompleting: Bool = false, onComplete: @escaping () -> Void) {
        self.isCompleting = isCompleting
        self.onComplete = onComplete
    }

    public var body: some View {
        OnboardingStepScaffold(
            buttonTitle: "Start learning",
            isButtonEnabled: !isCompleting,
            action: onComplete
        ) {
            VStack(spacing: LayoutTokens.space24) {
                SealStamp(text: "Ready")

                OnboardingStepHeader(
                    title: "You're all set",
                    subtitle: "Your first kanji is waiting on Today."
                )
            }
        }
    }
}
