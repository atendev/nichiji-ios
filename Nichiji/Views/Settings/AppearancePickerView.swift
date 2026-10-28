import SwiftUI

/*-------------------------------appearance-------------------------------*/

public struct AppearancePickerView: View {
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            Text("APPEARANCE")
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkSubtle)
                .kerning(0.6)

            HStack(spacing: LayoutTokens.space8) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    appearanceOption(mode: mode)
                }
            }

            Text(selectedMode.subtitleNote)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
        }
    }

    private func appearanceOption(mode: AppearanceMode) -> some View {
        let isSelected = selectedMode == mode

        return Button {
            appearanceModeRaw = mode.rawValue
        } label: {
            VStack(spacing: LayoutTokens.space8) {
                ZStack(alignment: .topTrailing) {
                    previewCard(for: mode)
                        .frame(height: 136)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    isSelected ? Color.nichijiInk : Color.nichijiBorderControl,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.nichijiInk)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.nichijiSurfaceRaised, lineWidth: 2)
                                )
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.nichijiSurfaceRaised)
                        }
                        .padding(LayoutTokens.space8)
                    }
                }

                Text(mode.displayName)
                    .font(.uiText(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .nichijiInk : .nichijiInkMuted)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .minTouchTarget()
        .accessibilityLabel("\(mode.displayName) appearance")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func previewCard(for mode: AppearanceMode) -> some View {
        switch mode {
        case .light:
            PhonePreviewLayer(palette: .washiLight)
        case .dark:
            PhonePreviewLayer(palette: .sumiDark)
        case .system:
            ZStack {
                PhonePreviewLayer(palette: .washiLight)
                PhonePreviewLayer(palette: .sumiDark)
                    .clipShape(BottomRightDiagonalTriangle())
            }
        }
    }
}

/*------------------------------preview-card------------------------------*/

private struct PreviewPalette {
    let background: Color
    let ink: Color
    let bar: Color
    let tabBackground: Color
    let activeDot: Color
    let hairline: Color

    static let washiLight = PreviewPalette(
        background: Color(red: 244 / 255, green: 238 / 255, blue: 226 / 255),
        ink: Color(red: 31 / 255, green: 27 / 255, blue: 22 / 255),
        bar: Color(red: 205 / 255, green: 191 / 255, blue: 166 / 255),
        tabBackground: Color(red: 251 / 255, green: 247 / 255, blue: 238 / 255),
        activeDot: Color(red: 184 / 255, green: 50 / 255, blue: 29 / 255),
        hairline: Color(red: 217 / 255, green: 207 / 255, blue: 188 / 255)
    )

    static let sumiDark = PreviewPalette(
        background: Color(red: 21 / 255, green: 19 / 255, blue: 15 / 255),
        ink: Color(red: 239 / 255, green: 232 / 255, blue: 216 / 255),
        bar: Color(red: 74 / 255, green: 68 / 255, blue: 58 / 255),
        tabBackground: Color(red: 31 / 255, green: 28 / 255, blue: 22 / 255),
        activeDot: Color(red: 232 / 255, green: 96 / 255, blue: 63 / 255),
        hairline: Color(red: 53 / 255, green: 48 / 255, blue: 42 / 255)
    )
}

private struct PhonePreviewLayer: View {
    let palette: PreviewPalette

    var body: some View {
        ZStack {
            palette.background

            VStack(spacing: 0) {
                HStack {
                    Capsule()
                        .fill(palette.bar)
                        .frame(width: 32, height: 4)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.horizontal, 10)

                Spacer(minLength: 4)

                Text("学")
                    .font(.kanjiDisplay(size: 38))
                    .foregroundColor(palette.ink)

                VStack(spacing: 4) {
                    Capsule()
                        .fill(palette.bar)
                        .frame(width: 40, height: 4)
                    Capsule()
                        .fill(palette.bar)
                        .frame(width: 26, height: 4)
                }
                .padding(.top, 4)

                Spacer(minLength: 6)

                HStack {
                    Circle()
                        .fill(palette.activeDot)
                        .frame(width: 6, height: 6)
                    Spacer()
                    Circle()
                        .fill(palette.bar)
                        .frame(width: 6, height: 6)
                    Spacer()
                    Circle()
                        .fill(palette.bar)
                        .frame(width: 6, height: 6)
                    Spacer()
                    Circle()
                        .fill(palette.bar)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 12)
                .frame(height: 24)
                .background(palette.tabBackground)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(palette.hairline)
                        .frame(height: 1)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct BottomRightDiagonalTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
