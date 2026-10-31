import SwiftUI

/*---------------------------------review---------------------------------*/

public struct ReviewSettingsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var preferences = ReviewPreferencesSnapshot.load()

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    Text("Review")
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)

                    Text("Choose how your flashcard sessions work.")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                }
                .padding(.top, LayoutTokens.space8)

                cardTypesSection

                orderSection

                sessionSection

                audioSection
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.bottom, LayoutTokens.space48)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: preferences) { _, updated in
            updated.save()
        }
    }

    // MARK: - Sections

    private var cardTypesSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader("CARD TYPES")

            ForEach(ReviewCardType.allCases, id: \.self) { type in
                let isOn = preferences.cardTypes.contains(type)
                ReviewOptionCard(
                    title: type.displayName,
                    note: type.subtitleNote,
                    isSelected: isOn
                ) {
                    preferences.setCardType(type, enabled: !isOn)
                }
                .accessibilityHint(isOn && preferences.cardTypes.count == 1 ? "At least one card type stays on." : "")
            }

            footnote("Pick one or more. Cards rotate through the types you turn on.")
        }
    }

    private var orderSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader("ORDER")

            ForEach(ReviewOrder.allCases, id: \.self) { order in
                ReviewOptionCard(
                    title: order.displayName,
                    note: order.subtitleNote,
                    isSelected: preferences.order == order
                ) {
                    preferences.order = order
                }
            }
        }
    }

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader("SESSION")

            VStack(spacing: 0) {
                chipGroup(
                    title: "Cards per session",
                    options: ReviewSessionSize.allCases,
                    selection: $preferences.sessionSize,
                    label: \.chipLabel
                )

                dividerLine

                settingsToggleRow(
                    title: "Show example word",
                    subtitle: "Adds a word to the answer side.",
                    isOn: $preferences.showsExampleWord
                )

                dividerLine

                settingsToggleRow(
                    title: "Repeat forgotten cards",
                    subtitle: "Cards you forget return at the end.",
                    isOn: $preferences.repeatsForgotten
                )
            }
            .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
        }
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader("AUDIO")

            VStack(spacing: 0) {
                settingsToggleRow(
                    title: "Play audio automatically",
                    subtitle: "Plays when you flip a card.",
                    isOn: $preferences.autoplaysAudio
                )

                dividerLine

                chipGroup(
                    title: "Audio plays",
                    options: ReviewAudioContent.allCases,
                    selection: $preferences.audioContent,
                    label: \.displayName
                )
            }
            .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)

            footnote("The speaker button on a card always plays the reading, whatever these are set to.")
        }
    }

    // MARK: - Builders

    private func chipGroup<Option: Hashable>(
        title: String,
        options: [Option],
        selection: Binding<Option>,
        label: @escaping (Option) -> String
    ) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: LayoutTokens.space8))
            : AnyLayout(HStackLayout(spacing: LayoutTokens.space8))

        return VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            Text(title)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)

            layout {
                ForEach(options, id: \.self) { option in
                    let isSelected = selection.wrappedValue == option
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(label(option))
                            .font(.uiText(size: 14, weight: .medium))
                            .foregroundColor(.nichijiInk)
                            .padding(.horizontal, LayoutTokens.space8)
                            .frame(maxWidth: .infinity, minHeight: LayoutTokens.minHitTarget)
                            .selectableCard(isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title), \(label(option))")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .padding(LayoutTokens.space16)
    }

    private func footnote(_ text: String) -> some View {
        Text(text)
            .font(.nichijiCaption)
            .foregroundColor(.nichijiInkSubtle)
            .padding(.horizontal, LayoutTokens.space8)
    }
}

/*------------------------------settings-row------------------------------*/

/// Review row in the Settings sheet, summarizing cards per session and order.
struct ReviewSettingsRow: View {
    @AppStorage(
        ReviewPreferenceKey.order.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var orderRaw: String = ReviewPreferencesSnapshot.standard.order.rawValue

    @AppStorage(
        ReviewPreferenceKey.sessionSize.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var sessionSizeRaw: String = ReviewPreferencesSnapshot.standard.sessionSize.rawValue

    var body: some View {
        NavigationLink {
            ReviewSettingsView()
        } label: {
            settingsNavigationRow(
                title: "Review",
                subtitle: "Card types, order, audio.",
                value: ReviewPreferencesSnapshot.settingsSummary(
                    sessionSize: ReviewSessionSize(rawValue: sessionSizeRaw) ?? ReviewPreferencesSnapshot.standard.sessionSize,
                    order: ReviewOrder(rawValue: orderRaw) ?? ReviewPreferencesSnapshot.standard.order
                )
            )
        }
        .buttonStyle(.plain)
    }
}

/*------------------------------option-card-------------------------------*/

private struct ReviewOptionCard: View {
    let title: String
    let note: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)

                    Text(note)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nichijiVermilion)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, LayoutTokens.space16)
            .frame(minHeight: 64)
            .selectableCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
