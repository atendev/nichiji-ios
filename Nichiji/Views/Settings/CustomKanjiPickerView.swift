import SwiftUI

private struct SelectionCellBackground: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .fill(isSelected ? Color.nichijiVermilionWash : Color.nichijiSurfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(isSelected ? Color.nichijiVermilion : Color.nichijiBorderControl, lineWidth: 1)
            )
    }
}

extension View {
    func selectionCellBackground(isSelected: Bool) -> some View {
        modifier(SelectionCellBackground(isSelected: isSelected))
    }
}

/*------------------------------custom-kanji------------------------------*/

public struct CustomKanjiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.serviceContainer) private var services

    @AppStorage(
        LearnerPreferenceKey.levelSystem.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var levelSystemRaw: String = LevelSystem.jlpt.rawValue

    @AppStorage(
        LearnerPreferenceKey.isCustomPoolActive.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var isCustomPoolActive: Bool = false

    @State private var sections: [KanjiGroupSection] = []
    @State private var selectedIDs: Set<String> = []
    @State private var isLoaded: Bool = false

    private var activeLevelSystem: LevelSystem {
        LevelSystem(rawValue: levelSystemRaw) ?? .jlpt
    }

    private var allDisplayedCount: Int {
        sections.reduce(0) { $0 + $1.entries.count }
    }

    private var selectedDisplayedCount: Int {
        let displayedIDs = Set(sections.flatMap { $0.entries.map(\.id) })
        return selectedIDs.intersection(displayedIDs).count
    }

    /// Same gap between columns and between rows.
    private static let gridSpacing = LayoutTokens.space12

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                    VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                        Text("Customize your kanji")
                            .font(.nichijiTitle)
                            .foregroundColor(.nichijiInk)

                        Text("Turn on the kanji you want to study. Your daily kanji come from the ones that are on.")
                            .font(.nichijiBody)
                            .foregroundColor(.nichijiInkMuted)
                    }
                    .padding(.top, LayoutTokens.space8)

                    ForEach(sections) { section in
                        sectionView(for: section)
                    }
                }
                .padding(.horizontal, LayoutTokens.screenMarginCompact)
                .padding(.bottom, LayoutTokens.space32)
            }

            bottomSummaryBar
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Customize your kanji")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: levelSystemRaw) {
            await loadSectionsAndSelections()
        }
    }

    private func sectionView(for section: KanjiGroupSection) -> some View {
        let sectionIDs = Set(section.entries.map(\.id))
        let onCount = selectedIDs.intersection(sectionIDs).count
        let isAllSelected = !section.entries.isEmpty && onCount == section.entries.count
        let columns = Array(repeating: GridItem(.flexible(), spacing: Self.gridSpacing), count: 5)

        return VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            HStack(alignment: .center, spacing: LayoutTokens.space12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.nichijiHeading)
                        .foregroundColor(.nichijiInk)

                    Text("\(section.entries.count) kanji · \(onCount) on")
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                }

                Spacer()

                if !section.entries.isEmpty {
                    Button {
                        toggleAll(in: section, selectAll: !isAllSelected)
                    } label: {
                        Text(isAllSelected ? "Clear all" : "Select all")
                            .font(.uiText(size: 12, weight: .medium))
                            .foregroundColor(.nichijiInk)
                            .padding(.horizontal, LayoutTokens.space12)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                                    .stroke(Color.nichijiBorderControl, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .minTouchTarget()
                    .accessibilityLabel("\(isAllSelected ? "Clear all" : "Select all") in \(section.title)")
                }
            }

            if !section.entries.isEmpty {
                LazyVGrid(columns: columns, spacing: Self.gridSpacing) {
                    ForEach(section.entries) { entry in
                        kanjiCell(for: entry)
                    }
                }
            }
        }
    }

    private func kanjiCell(for entry: KanjiEntry) -> some View {
        let isSelected = selectedIDs.contains(entry.id)

        return Button {
            toggleKanji(entry.id)
        } label: {
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Text(entry.id)
                            .font(.kanjiDisplay(size: 30))
                            .foregroundColor(.nichijiInk)
                    }
                    .selectionCellBackground(isSelected: isSelected)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.nichijiVermilion)
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .accessibilityLabel("Kanji \(entry.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var bottomSummaryBar: some View {
        HStack(spacing: LayoutTokens.space16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedDisplayedCount) on")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)

                Text("of \(allDisplayedCount) kanji")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }

            Spacer()

            Button {
                Task {
                    await commitAndDismiss()
                }
            } label: {
                Text("Done")
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiOnVermilion)
                    .padding(.horizontal, LayoutTokens.space24)
                    .frame(minWidth: 120, minHeight: 48)
                    .background(Color.nichijiVermilion)
                    .continuousCornerRadius(LayoutTokens.cornerRadiusSmall)
            }
            .buttonStyle(.plain)
            .minTouchTarget()
            .accessibilityLabel("Done customizing kanji")
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.vertical, LayoutTokens.space12)
        .background(Color.nichijiSurfaceRaised)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.nichijiHairline)
                .frame(height: 1)
        }
    }

    // MARK: - Actions

    private func loadSectionsAndSelections() async {
        let contentStore = services?.contentStore ?? BundledKanjiContentStore()
        var loadedSections: [KanjiGroupSection] = []

        switch activeLevelSystem {
        case .jlpt:
            for level in JLPTLevel.allCases {
                let entries = (try? contentStore.entries(for: level)) ?? []
                if !entries.isEmpty || level == .n5 {
                    loadedSections.append(
                        KanjiGroupSection(
                            id: level.rawValue,
                            title: level.codeLabel,
                            entries: entries
                        )
                    )
                }
            }
        case .joyo:
            for grade in JoyoGrade.allCases {
                let entries = (try? contentStore.entries(for: grade)) ?? []
                if !entries.isEmpty || grade == .grade1 {
                    loadedSections.append(
                        KanjiGroupSection(
                            id: grade.rawValue,
                            title: grade.displayName,
                            entries: entries
                        )
                    )
                }
            }
        }

        sections = loadedSections

        if let learnerStore = services?.learnerStore,
           let storedIDs = try? await learnerStore.customSelectionIDs(for: activeLevelSystem),
           !storedIDs.isEmpty {
            selectedIDs = storedIDs
        } else if let firstSection = loadedSections.first {
            selectedIDs = Set(firstSection.entries.map(\.id))
        }
        isLoaded = true
    }

    private func toggleKanji(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
        Task {
            await persistSelection()
        }
    }

    private func toggleAll(in section: KanjiGroupSection, selectAll: Bool) {
        for entry in section.entries {
            if selectAll {
                selectedIDs.insert(entry.id)
            } else {
                selectedIDs.remove(entry.id)
            }
        }
        Task {
            await persistSelection()
        }
    }

    private func persistSelection() async {
        let displayedIDs = Set(sections.flatMap { $0.entries.map(\.id) })
        let activeIDs = selectedIDs.intersection(displayedIDs)
        isCustomPoolActive = !activeIDs.isEmpty

        guard let services else { return }
        do {
            try await services.learnerStore.setCustomSelection(activeIDs, levelSystem: activeLevelSystem)
            let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
            var preferences = LearnerPreferencesSnapshot.load(from: defaults)
            preferences.isCustomPoolActive = isCustomPoolActive
            try await LevelChangeCoordinator.applyLevelChange(
                preferences: preferences,
                dailyKanjiService: services.dailyKanjiService,
                dayProvider: services.dayProvider,
                reminderScheduler: services.reminderScheduler,
                widgetRefresher: services.widgetRefresher
            )
        } catch {
            // Keep UI responsive if background store persistence fails.
        }
    }

    private func commitAndDismiss() async {
        await persistSelection()
        dismiss()
    }
}

private struct KanjiGroupSection: Identifiable {
    let id: String
    let title: String
    let entries: [KanjiEntry]
}
