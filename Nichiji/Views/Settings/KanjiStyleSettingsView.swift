import SwiftUI

/*-------------------------------kanji-style-------------------------------*/

extension KanjiFontStyleStore {
    /// Saves the learner's pick, repaints every kanji display and reloads the widget timelines, which draw their kanji in the same style.
    func choose(_ style: KanjiFontStyle, widgetRefresher: (any WidgetRefresher)?) {
        guard style != self.style else { return }
        select(style)
        widgetRefresher?.reloadTimelines()
    }
}

/// Settings > Learning row showing the current style (`Kanji style · Serif`).
struct KanjiStyleSettingsRow: View {
    var body: some View {
        NavigationLink {
            KanjiStyleSettingsView()
        } label: {
            settingsNavigationRow(
                title: "Kanji style",
                subtitle: "Serif or gothic.",
                value: KanjiFontStyleStore.shared.style.displayName
            )
        }
        .buttonStyle(.plain)
    }
}

/// Sub screen with one card per style, each showing 直 in that style.
struct KanjiStyleSettingsView: View {
    @Environment(\.serviceContainer) private var services

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    Text("Kanji style")
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)

                    Text("Choose how the big kanji are drawn. Interface text stays the same.")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                }
                .padding(.top, LayoutTokens.space8)

                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    sectionHeader("STYLE")

                    KanjiStyleCards(selected: KanjiFontStyleStore.shared.style) { style in
                        KanjiFontStyleStore.shared.choose(style, widgetRefresher: services?.widgetRefresher)
                    }
                }
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.bottom, LayoutTokens.space48)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Kanji style")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/*--------------------------------cards----------------------------------*/

/// One card per style, shared by the Settings sub screen and the onboarding step.
struct KanjiStyleCards: View {
    let selected: KanjiFontStyle
    let onSelect: (KanjiFontStyle) -> Void

    var body: some View {
        VStack(spacing: LayoutTokens.space12) {
            ForEach(KanjiFontStyle.allCases, id: \.self) { style in
                KanjiStyleCard(style: style, isSelected: selected == style) {
                    onSelect(style)
                }
            }
        }
    }
}

private struct KanjiStyleCard: View {
    let style: KanjiFontStyle
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            layout {
                Text("直")
                    .font(.kanjiDisplay(size: 64, style: style))
                    .foregroundColor(.nichijiInk)
                    .frame(minWidth: 88)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.displayName)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)

                    Text(style.subtitleNote)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Always laid out so selecting a card does not narrow its text and rewrap it.
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nichijiVermilion)
                    .frame(width: 20, height: 20)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, LayoutTokens.space16)
            .padding(.vertical, LayoutTokens.space12)
            .frame(minHeight: 96)
            .selectableCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Stacks the sample over the name at accessibility text sizes so neither is squeezed.
    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: LayoutTokens.space8))
            : AnyLayout(HStackLayout(spacing: LayoutTokens.space16))
    }
}
