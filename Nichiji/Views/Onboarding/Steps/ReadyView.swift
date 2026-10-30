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
                OnboardingLogo()

                Text("You're all set")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}
