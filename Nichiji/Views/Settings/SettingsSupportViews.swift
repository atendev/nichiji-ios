import SwiftUI

/*-----------------------------widget-guide-------------------------------*/

public struct WidgetGuideSettingsView: View {
    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    Text("Widgets")
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)

                    Text("Keep today's kanji on your home screen or lock screen.")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                }
                .padding(.top, LayoutTokens.space8)

                mediumWidgetSection

                smallWidgetSection

                lockScreenSection

                Text("To add one, touch and hold your home screen, tap +, then choose Nichiji.")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                    .padding(.horizontal, LayoutTokens.space8)
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.bottom, LayoutTokens.space48)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var mediumWidgetSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                Text("Medium")
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)

                Text("Kanji, readings, meaning, an example word and Got it.")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }

            HStack(spacing: LayoutTokens.space12) {
                VStack(alignment: .leading) {
                    Text("学")
                        .font(.kanjiWidget)
                        .foregroundColor(.nichijiInk)

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ガク · まな-ぶ")
                            .font(.nichijiCaption)
                            .foregroundColor(.nichijiInkMuted)

                        Text("study, learning")
                            .font(.nichijiCallout)
                            .foregroundColor(.nichijiInk)
                    }
                }
                .frame(width: 108, alignment: .leading)

                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TODAY · N5")
                            .font(.nichijiCaption)
                            .foregroundColor(.nichijiInkSubtle)
                            .kerning(0.6)

                        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space8) {
                            Text("学校")
                                .font(.kanjiWord)
                                .foregroundColor(.nichijiInk)

                            Text("がっこう")
                                .font(.nichijiCaption)
                                .foregroundColor(.nichijiInkMuted)
                        }
                    }

                    Spacer()

                    Text("Got it")
                        .font(.uiText(size: 14, weight: .medium))
                        .foregroundColor(.nichijiInk)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                                .stroke(Color.nichijiBorderControl, lineWidth: 1)
                        )
                }
            }
            .padding(14)
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.nichijiSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.nichijiHairline, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Medium widget showing the kanji 学, its readings, its meaning and an example word")
        }
        .padding(LayoutTokens.space24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.nichijiHairline, lineWidth: 1)
        )
    }

    private var smallWidgetSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                Text("Small")
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)

                Text("The kanji and its main meaning.")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }

            VStack(alignment: .leading) {
                Text("学")
                    .font(.kanjiWidget)
                    .foregroundColor(.nichijiInk)

                Spacer()

                Text("study, learning")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }
            .padding(14)
            .frame(width: 150, height: 150, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.nichijiSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.nichijiHairline, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Small widget showing the kanji 学 and its meaning")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LayoutTokens.space24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.nichijiHairline, lineWidth: 1)
        )
    }

    private var lockScreenSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                Text("Lock screen")
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)

                Text("Drawn in a single ink so it follows your lock screen tint.")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }

            HStack(spacing: LayoutTokens.space12) {
                Text("学")
                    .font(.kanjiDisplay(size: 36))
                    .foregroundColor(.nichijiInk)

                Text("study, learning")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInk)

                Spacer()
            }
            .padding(.horizontal, LayoutTokens.space16)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.nichijiSurfaceSunken)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Lock screen widget showing the kanji 学 and its meaning")
        }
        .padding(LayoutTokens.space24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.nichijiHairline, lineWidth: 1)
        )
    }
}

/*--------------------------------privacy---------------------------------*/

public struct PrivacySettingsView: View {
    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                Text("Privacy")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)
                    .padding(.top, LayoutTokens.space8)

                VStack(alignment: .leading, spacing: LayoutTokens.space16) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.nichijiMatcha)

                        Text("Data not collected")
                            .font(.uiText(size: 12, weight: .medium))
                            .foregroundColor(.nichijiMatcha)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.nichijiMatchaWash)
                    )

                    VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                        Text("Nichiji collects nothing")
                            .font(.nichijiHeading)
                            .foregroundColor(.nichijiInk)

                        Text("The app does not collect any data about you. You do not need an account to use it.")
                            .font(.nichijiBody)
                            .foregroundColor(.nichijiInkMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LayoutTokens.space24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.nichijiSurfaceRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.nichijiHairline, lineWidth: 1)
                )
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.bottom, LayoutTokens.space48)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
