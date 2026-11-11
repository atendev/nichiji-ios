import SwiftUI

/*------------------------------known-kanji-------------------------------*/

/// Turn on the kanji the learner already knows. They leave the daily pool and join the review queue.
struct KnownKanjiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.serviceContainer) private var services

    @State private var model: KnownKanjiPickerModel?
    @State private var system: LevelSystem = .jlpt
    @State private var query = ""
    @State private var searchIndex: DictionarySearchIndex?
    @State private var results: [KanjiIndexEntry] = []
    @State private var searchFailure: String?
    @State private var errorMessage: String?

    private let searchSource = BundledDictionarySearchSource()

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            DictionarySearchBar(
                text: $query,
                placeholder: "Type kanji, a reading or a meaning",
                accessibilityName: "Search for kanji you know"
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                    Text("Turn on the kanji you already know. They skip your daily kanji and go into your reviews.")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                        .padding(.top, LayoutTokens.space8)

                    if let model {
                        content(model)
                    } else if errorMessage == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.nichijiCallout)
                            .foregroundColor(.nichijiInkMuted)
                    }
                }
                .padding(.horizontal, LayoutTokens.screenMarginCompact)
                .padding(.bottom, LayoutTokens.space32)
            }

            bottomBar
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Known kanji")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .task(id: query) { await runSearch() }
        .onDisappear { Task { _ = await commit() } }
    }

    /*-------------------------------content-------------------------------*/

    @ViewBuilder
    private func content(_ model: KnownKanjiPickerModel) -> some View {
        if isSearching {
            searchContent(model)
        } else {
            ForEach(model.sections) { section in
                sectionView(section, model: model)
            }
        }
    }

    @ViewBuilder
    private func searchContent(_ model: KnownKanjiPickerModel) -> some View {
        if let searchFailure {
            Text(searchFailure)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
        } else if searchIndex == nil {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if results.isEmpty {
            Text("No kanji found.")
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
        } else {
            LazyVGrid(columns: KanjiGridTile.columns, spacing: KanjiGridTile.spacing) {
                ForEach(results) { entry in
                    kanjiCell(
                        entry.id,
                        meaning: entry.primaryMeaning,
                        levelLabel: KnownKanjiPickerModel.levelLabel(for: entry, system: system),
                        model: model
                    )
                }
            }
        }
    }

    private func sectionView(_ section: KanjiBrowseSection, model: KnownKanjiPickerModel) -> some View {
        let isAllSelected = model.isAllSelected(in: section)

        return VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            KnownKanjiGroupHeader(
                title: section.title,
                detail: "\(section.countLabel) · \(model.selectedCount(in: section)) known",
                showsButton: model.showsGroupButton(for: section),
                isAllSelected: isAllSelected
            ) {
                self.model?.setAll(in: section, selected: !isAllSelected)
            }

            LazyVGrid(columns: KanjiGridTile.columns, spacing: KanjiGridTile.spacing) {
                ForEach(section.entries) { entry in
                    kanjiCell(entry.id, meaning: entry.primaryMeaning, levelLabel: nil, model: model)
                }
            }
        }
    }

    private func kanjiCell(
        _ kanjiID: String,
        meaning: String,
        levelLabel: String?,
        model: KnownKanjiPickerModel
    ) -> some View {
        KnownKanjiCell(
            kanjiID: kanjiID,
            meaning: meaning,
            levelLabel: levelLabel,
            isSelected: model.isSelected(kanjiID),
            isEnabled: model.isEnabled(kanjiID)
        ) {
            self.model?.toggle(kanjiID)
        }
    }

    private var bottomBar: some View {
        KnownKanjiBottomBar(count: model?.selectedCount ?? 0) {
            Task {
                if await commit() {
                    dismiss()
                }
            }
        }
    }

    /*-------------------------------actions-------------------------------*/

    private func load() async {
        guard model == nil else { return }
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        let preferences = LearnerPreferencesSnapshot.load(from: defaults)
        let loadedSystem = preferences.levelSystem
        let contentStore = services?.contentStore ?? BundledKanjiContentStore()
        let loaded = await Task.detached {
            Result { try KanjiBrowseGrouping.load(system: loadedSystem, contentStore: contentStore) }
        }.value
        guard !Task.isCancelled else { return }

        switch loaded {
        case .success(let all):
            do {
                let declared = try await services?.learnerStore.declaredKnownIDs() ?? []
                let studied = try await services?.learnerStore.nonNewKanjiIDs() ?? []
                system = loadedSystem
                model = KnownKanjiPickerModel(
                    sections: KnownKanjiScope.sections(from: all, preferences: preferences),
                    declared: declared,
                    studied: studied
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /// Builds the search index the first time the learner types, then waits about 150 ms after the last keystroke.
    private func runSearch() async {
        guard isSearching else {
            results = []
            return
        }
        await prepareSearchIndex()
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled, let index = searchIndex else { return }
        let text = query
        let found = await Task.detached(priority: .userInitiated) {
            KnownKanjiPickerModel.results(for: text, in: index)
        }.value
        guard !Task.isCancelled else { return }
        results = found
    }

    private func prepareSearchIndex() async {
        guard searchIndex == nil else { return }
        let contentStore = services?.contentStore ?? BundledKanjiContentStore()
        let source = searchSource
        let loaded = await Task.detached(priority: .userInitiated) {
            Result { try DictionarySearchIndex.load(contentStore: contentStore, source: source) }
        }.value

        switch loaded {
        case .success(let index):
            searchIndex = index
            searchFailure = nil
        case .failure(let error):
            searchFailure = error.localizedDescription
        }
    }

    /// Writes only the difference from what the store holds. The committed set moves first, so a second call finds nothing to do.
    /// Returns false when the save failed, so Done can stay open with the message.
    private func commit() async -> Bool {
        guard let current = model, let services else { return true }
        let changes = current.pendingChanges
        guard !changes.declare.isEmpty || !changes.undeclare.isEmpty else { return true }

        let previous = current.committed
        model?.markCommitted()
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        let preferences = LearnerPreferencesSnapshot.load(from: defaults)
        do {
            try await services.setKnown(declare: changes.declare, undeclare: changes.undeclare, preferences: preferences)
            errorMessage = nil
            return true
        } catch {
            model?.committed = previous
            errorMessage = "Your known kanji could not be saved. Try Done again."
            return false
        }
    }
}
