import SwiftUI

private struct SettingsGroupBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .fill(Color.nichijiSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(Color.nichijiHairline, lineWidth: 1)
            )
    }
}

extension View {
    func settingsGroupBackground() -> some View {
        modifier(SettingsGroupBackground())
    }
}

/*--------------------------------settings--------------------------------*/

public struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.serviceContainer) private var services

    @AppStorage(
        LearnerPreferenceKey.hasCompletedOnboarding.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var hasCompletedOnboarding: Bool = false

    @AppStorage(
        LearnerPreferenceKey.showsRomaji.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var showsRomaji: Bool = true

    @AppStorage(
        LearnerPreferenceKey.streakFreezeEnabled.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var streakFreezeEnabled: Bool = false

    @AppStorage(
        LearnerPreferenceKey.reminderEnabled.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var reminderEnabled: Bool = true

    @AppStorage(
        LearnerPreferenceKey.reminderHour.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var reminderHour: Int = 8

    @AppStorage(
        LearnerPreferenceKey.reminderMinute.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var reminderMinute: Int = 0

    @AppStorage(
        LearnerPreferenceKey.levelSystem.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var levelSystemRaw: String = LevelSystem.jlpt.rawValue

    @AppStorage(
        LearnerPreferenceKey.selectedJLPTLevel.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var selectedJLPTLevelRaw: String = JLPTLevel.n5.rawValue

    @AppStorage(
        LearnerPreferenceKey.selectedJoyoGrade.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var selectedJoyoGradeRaw: String = JoyoGrade.grade1.rawValue

    @AppStorage(
        LearnerPreferenceKey.isCustomPoolActive.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var isCustomPoolActive: Bool = false

    @State private var customCount: Int = 0

    private var preferencesSnapshot: LearnerPreferencesSnapshot {
        LearnerPreferencesSnapshot(
            hasCompletedOnboarding: hasCompletedOnboarding,
            showsRomaji: showsRomaji,
            streakFreezeEnabled: streakFreezeEnabled,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            levelSystem: LevelSystem(rawValue: levelSystemRaw) ?? .jlpt,
            selectedJLPTLevel: JLPTLevel(rawValue: selectedJLPTLevelRaw) ?? .n5,
            selectedJoyoGrade: JoyoGrade(rawValue: selectedJoyoGradeRaw) ?? .grade1,
            isCustomPoolActive: isCustomPoolActive
        )
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0"
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                    AppearancePickerView()
                        .padding(.top, LayoutTokens.space8)

                    learningSection

                    helpSection

                    aboutSection
                }
                .padding(.horizontal, LayoutTokens.screenMarginCompact)
                .padding(.bottom, LayoutTokens.space48)
            }
            .background(Color.nichijiSurfaceRaised.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiInk)
                }
            }
            .task(id: "\(levelSystemRaw)-\(isCustomPoolActive)") {
                await refreshCustomCount()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var learningSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader("LEARNING")

            VStack(spacing: 0) {
                NavigationLink {
                    LevelSettingsView()
                } label: {
                    settingsNavigationRow(
                        title: "Level",
                        subtitle: "Daily kanji match this level.",
                        value: preferencesSnapshot.levelSummary(customCount: customCount)
                    )
                }
                .buttonStyle(.plain)

                dividerLine

                NavigationLink {
                    ReminderSettingsView()
                } label: {
                    settingsNavigationRow(
                        title: "Daily reminder",
                        subtitle: nil,
                        value: preferencesSnapshot.reminderSummary
                    )
                }
                .buttonStyle(.plain)

                // TODO: Add Review settings navigation row once the post-MVP Review flashcard slice is implemented.

                dividerLine

                settingsToggleRow(
                    title: "Show romaji",
                    subtitle: "Readings stay in kana unless this is on.",
                    isOn: $showsRomaji
                )

                dividerLine

                settingsToggleRow(
                    title: "Streak freeze",
                    subtitle: "Miss one day a week and keep your streak.",
                    isOn: $streakFreezeEnabled
                )
            }
            .settingsGroupBackground()
        }
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader("HELP")

            VStack(spacing: 0) {
                NavigationLink {
                    WidgetGuideSettingsView()
                } label: {
                    settingsNavigationRow(
                        title: "Add a widget",
                        subtitle: nil,
                        value: nil
                    )
                }
                .buttonStyle(.plain)

                dividerLine

                Button {
                    hasCompletedOnboarding = false
                    dismiss()
                } label: {
                    settingsNavigationRow(
                        title: "Replay introduction",
                        subtitle: nil,
                        value: nil
                    )
                }
                .buttonStyle(.plain)
            }
            .settingsGroupBackground()
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader("ABOUT")

            VStack(spacing: 0) {
                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    settingsNavigationRow(
                        title: "Privacy",
                        subtitle: nil,
                        value: "Data not collected"
                    )
                }
                .buttonStyle(.plain)

                dividerLine

                HStack(spacing: LayoutTokens.space12) {
                    Text("Version")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)

                    Spacer()

                    Text(appVersion)
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                }
                .padding(.horizontal, LayoutTokens.space16)
                .frame(minHeight: 52)
            }
            .settingsGroupBackground()
        }
    }

    private func refreshCustomCount() async {
        guard let learnerStore = services?.learnerStore else { return }
        let system = LevelSystem(rawValue: levelSystemRaw) ?? .jlpt
        if let ids = try? await learnerStore.customSelectionIDs(for: system) {
            customCount = ids.count
        }
    }
}

// MARK: - Row Builders

private func sectionHeader(_ text: String) -> some View {
    Text(text)
        .font(.nichijiCaption)
        .foregroundColor(.nichijiInkSubtle)
        .kerning(0.6)
        .padding(.horizontal, LayoutTokens.space8)
}

private var dividerLine: some View {
    Rectangle()
        .fill(Color.nichijiHairline)
        .frame(height: 1)
}

private func settingsNavigationRow(
    title: String,
    subtitle: String?,
    value: String?
) -> some View {
    HStack(spacing: LayoutTokens.space12) {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)

            if let subtitle {
                Text(subtitle)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let value {
            Text(value)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
        }

        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.nichijiInkSubtle)
    }
    .padding(.horizontal, LayoutTokens.space16)
    .frame(minHeight: 56)
    .contentShape(Rectangle())
}

private func settingsToggleRow(
    title: String,
    subtitle: String,
    isOn: Binding<Bool>
) -> some View {
    HStack(spacing: LayoutTokens.space12) {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)

            Text(subtitle)
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Toggle("", isOn: isOn)
            .labelsHidden()
            .tint(.nichijiVermilion)
    }
    .padding(.horizontal, LayoutTokens.space16)
    .frame(minHeight: 56)
}
