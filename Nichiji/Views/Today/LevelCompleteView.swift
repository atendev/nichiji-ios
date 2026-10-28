import SwiftUI

/*-----------------------------level-complete-----------------------------*/

public struct LevelCompleteView: View {
    public let onOpenSettings: () -> Void

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: LayoutTokens.space16) {
            Spacer()

            SealStamp(text: "Level complete")

            Text("You've learned all kanji in this level.")
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)

            Text("Choose another level or customize your study pool in Settings.")
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutTokens.space32)

            PrimaryButton(title: "Open Settings", action: onOpenSettings)
                .padding(.horizontal, LayoutTokens.space32)
                .padding(.top, LayoutTokens.space16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nichijiSurface.ignoresSafeArea())
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Display dynamic level summary metrics and direct level switcher shortcut in Slice 7.
