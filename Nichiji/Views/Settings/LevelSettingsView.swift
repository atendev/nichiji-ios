import SwiftUI

/*---------------------------------levels---------------------------------*/

public struct LevelSettingsView: View {
    @Environment(\.serviceContainer) private var services

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
        LearnerPreferenceKey.dailyOrder.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var dailyOrderRaw: String = DailyOrder.mostCommon.rawValue

    @AppStorage(
        LearnerPreferenceKey.isCustomPoolActive.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var isCustomPoolActive: Bool = false

    @State private var customCount: Int = 0

    private var activeLevelSystem: LevelSystem { LevelSystem(rawValue: levelSystemRaw) ?? .jlpt }

    private var selectedJLPTLevel: JLPTLevel { JLPTLevel(rawValue: selectedJLPTLevelRaw) ?? .n5 }

    private var selectedJoyoGrade: JoyoGrade { JoyoGrade(rawValue: selectedJoyoGradeRaw) ?? .grade1 }

    private var selectedDailyOrder: DailyOrder { DailyOrder(rawValue: dailyOrderRaw) ?? .mostCommon }

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    Text("Level")
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)

                    Text("Your daily kanji match your level.")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                }
                .padding(.top, LayoutTokens.space8)

                levelSystemSection(activeLevelSystem: activeLevelSystem, switchAction: switchLevelSystem)

                levelRowsSection

                dailyOrderSection(selectedDailyOrder: selectedDailyOrder, selectAction: selectDailyOrder)

                customSection(customCount: customCount, isCustomPoolActive: isCustomPoolActive)

                Text("You can change this any time. Kanji you have learned stay learned.")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkSubtle)
                    .padding(.horizontal, LayoutTokens.space8)
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.bottom, LayoutTokens.space48)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Level")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(levelSystemRaw)-\(isCustomPoolActive)") {
            await loadCustomCount()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var levelRowsSection: some View {
        VStack(spacing: LayoutTokens.space8) {
            switch activeLevelSystem {
            case .jlpt:
                ForEach(JLPTLevel.allCases, id: \.self) { level in
                    let isSelected = !isCustomPoolActive && selectedJLPTLevel == level
                    levelRow(
                        code: level.codeLabel,
                        title: level.displayName,
                        countLabel: countLabel(for: level),
                        isSelected: isSelected
                    ) {
                        selectJLPTLevel(level)
                    }
                }
            case .joyo:
                ForEach(JoyoGrade.allCases, id: \.self) { grade in
                    let isSelected = !isCustomPoolActive && selectedJoyoGrade == grade
                    levelRow(
                        code: grade.codeLabel,
                        title: grade.displayName,
                        countLabel: countLabel(for: grade),
                        isSelected: isSelected
                    ) {
                        selectJoyoGrade(grade)
                    }
                }
            }
        }
    }

    private func levelRow(
        code: String,
        title: String,
        countLabel: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space12) {
                Text(code)
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiInk)
                    .frame(width: 36, alignment: .leading)

                Text(title)
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let countLabel, !countLabel.isEmpty {
                    Text(countLabel)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                }

                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.nichijiVermilion)
                    }
                }
                .frame(width: 20, height: 20)
            }
            .padding(.horizontal, LayoutTokens.space16)
            .frame(minHeight: 56)
            .selectableCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Actions & Helpers

    private func countLabel(for jlptLevel: JLPTLevel) -> String? {
        let store = services?.contentStore ?? BundledKanjiContentStore()
        let count = (try? store.entries(for: jlptLevel).count) ?? 0
        return count > 0 ? "\(count) kanji" : nil
    }

    private func countLabel(for joyoGrade: JoyoGrade) -> String? {
        let store = services?.contentStore ?? BundledKanjiContentStore()
        let count = (try? store.entries(for: joyoGrade).count) ?? 0
        if count > 0 {
            return "\(count) kanji"
        }
        switch joyoGrade {
        case .grade1: return "80 kanji"
        case .grade2: return "160 kanji"
        case .grade3: return "200 kanji"
        case .grade4: return "202 kanji"
        case .grade5: return "193 kanji"
        case .grade6: return "191 kanji"
        case .secondary: return "1,110 kanji"
        }
    }

    private func switchLevelSystem(to system: LevelSystem) {
        guard system != activeLevelSystem else { return }
        levelSystemRaw = system.rawValue
        isCustomPoolActive = false
        switch system {
        case .jlpt:
            selectedJLPTLevelRaw = JLPTLevel.n5.rawValue
        case .joyo:
            selectedJoyoGradeRaw = JoyoGrade.grade1.rawValue
        }
        triggerPoolReassignment()
    }

    private func selectJLPTLevel(_ level: JLPTLevel) {
        selectedJLPTLevelRaw = level.rawValue
        isCustomPoolActive = false
        triggerPoolReassignment()
    }

    private func selectJoyoGrade(_ grade: JoyoGrade) {
        selectedJoyoGradeRaw = grade.rawValue
        isCustomPoolActive = false
        triggerPoolReassignment()
    }

    private func selectDailyOrder(_ order: DailyOrder) {
        dailyOrderRaw = order.rawValue
        triggerPoolReassignment()
    }

    private func triggerPoolReassignment() {
        guard let services else { return }
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        let preferences = LearnerPreferencesSnapshot.load(from: defaults)
        Task {
            let day = services.dayProvider.calendarDay(for: services.dayProvider.now)
            _ = try? await services.dailyKanjiService.refreshAssignmentAfterPreferenceChange(
                for: day,
                preferences: preferences
            )
            // TODO: Rebuild reminder notification schedule and reload WidgetKit timelines after level or order changes in Slices 10 and 11.
        }
    }

    private func loadCustomCount() async {
        guard let learnerStore = services?.learnerStore else { return }
        if let ids = try? await learnerStore.customSelectionIDs(for: activeLevelSystem) {
            customCount = ids.count
        }
    }
}

// MARK: - Sections

private func levelSystemSection(
    activeLevelSystem: LevelSystem,
    switchAction: @escaping (LevelSystem) -> Void
) -> some View {
    VStack(alignment: .leading, spacing: LayoutTokens.space8) {
        Text("LEVELS BASED ON")
            .font(.nichijiCaption)
            .foregroundColor(.nichijiInkSubtle)
            .kerning(0.6)
            .padding(.horizontal, LayoutTokens.space8)

        HStack(spacing: LayoutTokens.space4) {
            ForEach(LevelSystem.allCases, id: \.self) { system in
                let isSelected = activeLevelSystem == system
                Button {
                    switchAction(system)
                } label: {
                    Text(system.displayName)
                        .font(.uiText(size: 14, weight: isSelected ? .medium : .regular))
                        .foregroundColor(isSelected ? .nichijiInk : .nichijiInkMuted)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .selectableCard(isSelected: isSelected)
                }
                .buttonStyle(.plain)
                .minTouchTarget()
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(LayoutTokens.space4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.nichijiSurfaceSunken)
        )

        Text(activeLevelSystem.schemeNote)
            .font(.nichijiCaption)
            .foregroundColor(.nichijiInkSubtle)
            .padding(.horizontal, LayoutTokens.space8)
    }
}

private func dailyOrderSection(
    selectedDailyOrder: DailyOrder,
    selectAction: @escaping (DailyOrder) -> Void
) -> some View {
    VStack(alignment: .leading, spacing: LayoutTokens.space8) {
        Text("DAILY ORDER")
            .font(.nichijiCaption)
            .foregroundColor(.nichijiInkSubtle)
            .kerning(0.6)
            .padding(.horizontal, LayoutTokens.space8)

        VStack(spacing: LayoutTokens.space8) {
            ForEach(DailyOrder.allCases, id: \.self) { order in
                let isSelected = selectedDailyOrder == order
                Button {
                    selectAction(order)
                } label: {
                    HStack(spacing: LayoutTokens.space12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.displayName)
                                .font(.nichijiBody)
                                .foregroundColor(.nichijiInk)

                            Text(order.subtitleNote)
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
    }
}

private func customSection(
    customCount: Int,
    isCustomPoolActive: Bool
) -> some View {
    VStack(alignment: .leading, spacing: LayoutTokens.space8) {
        Text("CUSTOM")
            .font(.nichijiCaption)
            .foregroundColor(.nichijiInkSubtle)
            .kerning(0.6)
            .padding(.horizontal, LayoutTokens.space8)

        NavigationLink {
            CustomKanjiPickerView()
        } label: {
            HStack(spacing: LayoutTokens.space12) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.nichijiInk)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Customize your kanji")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)

                    Text(
                        customCount > 0
                            ? "\(customCount) kanji on. Choose exactly which to study."
                            : "Choose exactly which kanji to study."
                    )
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isCustomPoolActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nichijiVermilion)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nichijiInkSubtle)
                }
            }
            .padding(.horizontal, LayoutTokens.space16)
            .frame(minHeight: 64)
            .selectableCard(isSelected: isCustomPoolActive)
        }
        .buttonStyle(.plain)
        .minTouchTarget()
    }
}
