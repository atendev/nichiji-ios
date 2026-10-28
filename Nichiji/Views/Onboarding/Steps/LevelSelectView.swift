import SwiftUI

/*------------------------------level-select------------------------------*/

public struct LevelSelectView: View {
    public let onNext: () -> Void
    public let onBack: () -> Void

    @AppStorage(LearnerPreferenceKey.levelSystem.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var levelSystemRaw: String = LevelSystem.jlpt.rawValue

    @AppStorage(LearnerPreferenceKey.selectedJLPTLevel.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var selectedJLPTLevel: String = JLPTLevel.n5.rawValue

    public init(onNext: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.onNext = onNext
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: LayoutTokens.space16) {
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
                Text("Choose your level")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("You can change this or customize kanji later in Settings.")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LayoutTokens.space24)

            Picker("Level System", selection: $levelSystemRaw) {
                Text("JLPT").tag(LevelSystem.jlpt.rawValue)
                Text("Jōyō").tag(LevelSystem.joyo.rawValue)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, LayoutTokens.space24)

            Spacer()

            VStack(spacing: LayoutTokens.space12) {
                Text("Selected: \(selectedJLPTLevel.uppercased())")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)

                Text("Daily order can be configured in Settings.")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkSubtle)
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onNext)
                .padding(.horizontal, LayoutTokens.space24)
                .padding(.bottom, LayoutTokens.space32)
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Bind the verified kanji counts and selectable level rows for JLPT and Joyo systems in Slice 9.
