import SwiftUI

/*-------------------------------appearance-------------------------------*/

public struct AppearancePickerView: View {
    @AppStorage(LearnerPreferenceKey.appearanceMode.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            Text("Appearance")
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)

            HStack(spacing: LayoutTokens.space12) {
                appearanceOption(mode: .system, title: "System")
                appearanceOption(mode: .light, title: "Light")
                appearanceOption(mode: .dark, title: "Dark")
            }
        }
    }

    private func appearanceOption(mode: AppearanceMode, title: String) -> some View {
        Button(action: { appearanceModeRaw = mode.rawValue }) {
            VStack(spacing: LayoutTokens.space8) {
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(appearanceModeRaw == mode.rawValue ? Color.nichijiVermilion : Color.nichijiHairline, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                            .fill(Color.nichijiSurfaceSunken)
                    )
                    .frame(height: 60)

                Text(title)
                    .font(.nichijiCaption)
                    .foregroundColor(appearanceModeRaw == mode.rawValue ? .nichijiVermilion : .nichijiInk)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Draw the diagonal split preview graphic for System mode and accurate mini phone cards in Slice 8.
