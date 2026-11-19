import SwiftUI

/*-------------------------------dictionary-------------------------------*/

public struct DictionaryView: View {
    public let onOpenSettings: () -> Void

    @Environment(\.serviceContainer) private var services
    @Environment(ProAccessModel.self) private var proAccess: ProAccessModel?
    @AppStorage(
        LearnerPreferenceKey.levelSystem.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var levelSystemRaw: String = LevelSystem.jlpt.rawValue

    @AppStorage(
        LearnerPreferenceKey.showsRomaji.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var showsRomaji: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sections: [KanjiBrowseSection] = []
    @State private var collapsedSectionIDs: Set<String> = []
    @State private var tileSide: CGFloat = 0
    @State private var errorMessage: String?
    @State private var isLoaded = false
    @State private var reloadID = UUID()
    @State private var path = NavigationPath()
    @State private var query = ""
    @State private var searchIndex: DictionarySearchIndex?
    @State private var searchFailure: String?
    @State private var results: DictionarySearchResults?
    @State private var chosenWord: WordResult?
    @State private var paywallFeature: ProFeature?
    /// Kept across sheet opens, so the templates load once per run.
    @State private var handwriting: HandwritingSearchModel?
    @State private var drawSearch: DrawSearchPresentation?

    private let searchSource: any DictionarySearchSource

    /// Re-runs the search when the text changes or the index finishes building.
    private struct SearchRequest: Hashable {
        let query: String
        let isIndexReady: Bool
    }

    private var activeLevelSystem: LevelSystem {
        LevelSystem(rawValue: levelSystemRaw) ?? .jlpt
    }

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
        self.searchSource = BundledDictionarySearchSource()
    }

    private var isSearching: Bool {
        DictionaryQuery.parse(query) != nil
    }

    public var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                HeaderBar(kanjiTitle: "辞書", englishTitle: "Dictionary") {
                    Button(action: onOpenSettings) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.nichijiInk)
                            .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                    }
                    .minTouchTarget()
                    .accessibilityLabel("Open settings")
                }

                DictionarySearchBar(text: $query)
                DictionaryActionButtons(onDraw: openDrawSearch, onScan: openPhotoLookup)

                if isSearching {
                    searchContent
                } else if let errorMessage {
                    retryView(message: errorMessage)
                } else if !isLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    browseGrid
                }
            }
            .background(Color.nichijiSurface.ignoresSafeArea())
            // The pushed detail screen's back button reads this title.
            .navigationTitle("Dictionary")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: KanjiDetailRoute.self) { route in
                KanjiDetailView(kanjiID: route.kanjiID)
            }
            .navigationDestination(for: PhotoLookupPresentation.self) { presentation in
                PhotoLookupScreen(model: presentation.model) { kanjiID in
                    path.append(KanjiDetailRoute(kanjiID: kanjiID))
                }
            }
        }
        .task(id: "\(levelSystemRaw)-\(reloadID)") {
            await loadSections()
        }
        .task {
            await prepareSearchIndex()
        }
        .task(id: SearchRequest(query: query, isIndexReady: searchIndex != nil)) {
            await runSearch()
        }
        .sheet(item: $chosenWord) { result in
            WhichKanjiSheet(result: result, showsRomaji: showsRomaji) { kanjiID in
                chosenWord = nil
                path.append(KanjiDetailRoute(kanjiID: kanjiID))
            }
        }
        .sheet(item: $drawSearch, onDismiss: { handwriting?.clear() }, content: { presentation in
            DrawSearchSheet(model: presentation.model) { kanji in
                query = kanji
                drawSearch = nil
            }
        })
        .paywallSheet(feature: $paywallFeature)
    }

    @ViewBuilder private var searchContent: some View {
        if let searchFailure {
            messageView(title: "Search is unavailable", message: searchFailure)
        } else if searchIndex == nil {
            HStack(spacing: LayoutTokens.space12) {
                ProgressView()
                Text("Preparing search\u{2026}")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
        } else if let results {
            DictionarySearchResultsView(results: results, showsRomaji: showsRomaji, onSelectWord: openWord)
        } else {
            Color.clear
        }
    }

    /// One flat lazy list of fixed-height rows, so the scroll offset never has to guess at nested grid heights.
    private var browseGrid: some View {
        let rows = KanjiBrowseGrouping.rows(
            from: sections,
            collapsed: collapsedSectionIDs,
            columnCount: KanjiGridTile.columnCount
        )
        return ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: KanjiGridTile.spacing) {
                ForEach(rows) { row in
                    rowView(row)
                }
            }
            .padding(.horizontal, LayoutTokens.screenMarginCompact)
            .padding(.top, LayoutTokens.space8)
            .padding(.bottom, LayoutTokens.space32)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
            let side = Self.tileSide(forWidth: width)
            if abs(side - tileSide) > 0.5 { tileSide = side }
        }
    }

    @ViewBuilder private func rowView(_ row: KanjiBrowseRow) -> some View {
        switch row {
        case .header(let section, let isCollapsed, let isFirst):
            sectionHeader(section, isCollapsed: isCollapsed)
                .padding(.top, isFirst ? 0 : LayoutTokens.space32 - KanjiGridTile.spacing)
        case .tiles(_, let entries):
            if tileSide > 0 {
                tileRow(entries)
            }
        }
    }

    private func sectionHeader(_ section: KanjiBrowseSection, isCollapsed: Bool) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.85)) {
                if isCollapsed {
                    collapsedSectionIDs.remove(section.id)
                } else {
                    collapsedSectionIDs.insert(section.id)
                }
            }
        } label: {
            HStack(alignment: .center, spacing: LayoutTokens.space12) {
                Text(section.title)
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)

                Spacer()

                Text(section.countLabel)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.nichijiInkMuted)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .frame(minHeight: LayoutTokens.minHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(isCollapsed ? "Collapsed" : "Expanded")
        .accessibilityHint(isCollapsed ? "Shows the kanji in this level" : "Hides the kanji in this level")
    }

    private func tileRow(_ entries: [KanjiIndexEntry]) -> some View {
        HStack(spacing: KanjiGridTile.spacing) {
            ForEach(entries) { entry in
                NavigationLink(value: KanjiDetailRoute(kanjiID: entry.id)) {
                    KanjiGridTile(kanji: entry.id)
                        .frame(width: tileSide, height: tileSide)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(KanjiGridTile.accessibilityLabel(kanji: entry.id, meaning: entry.primaryMeaning))
                .accessibilityHint("Opens kanji details")
            }
        }
        .frame(height: tileSide, alignment: .leading)
    }

    /// Side of one square tile once the screen margins and column gaps are taken out.
    static func tileSide(forWidth width: CGFloat) -> CGFloat {
        let columns = CGFloat(KanjiGridTile.columnCount)
        let usable = width - 2 * LayoutTokens.screenMarginCompact - (columns - 1) * KanjiGridTile.spacing
        return max(KanjiGridTile.minimumSide, (usable / columns).rounded(.down))
    }

    private func loadSections() async {
        let contentStore = services?.contentStore ?? BundledKanjiContentStore()
        let system = activeLevelSystem
        let result = await Task.detached {
            Result { try KanjiBrowseGrouping.load(system: system, contentStore: contentStore) }
        }.value
        guard !Task.isCancelled else { return }

        switch result {
        case .success(let loaded):
            sections = loaded
            errorMessage = nil
            isLoaded = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /*-------------------------------search-------------------------------*/

    private func openWord(_ result: WordResult) {
        switch result.tapAction {
        case .unavailable:
            break
        case .openKanji(let kanjiID):
            path.append(KanjiDetailRoute(kanjiID: kanjiID))
        case .chooseKanji:
            chosenWord = result
        }
    }

    /// Builds the folded index once, in the background, the first time Dictionary appears.
    private func prepareSearchIndex() async {
        guard searchIndex == nil else { return }
        let contentStore = services?.contentStore ?? BundledKanjiContentStore()
        let source = searchSource
        let result = await Task.detached(priority: .userInitiated) {
            Result { try DictionarySearchIndex.load(contentStore: contentStore, source: source) }
        }.value

        switch result {
        case .success(let index):
            searchIndex = index
            searchFailure = nil
        case .failure(let error):
            searchFailure = error.localizedDescription
        }
    }

    /// Waits about 150 ms after the last keystroke, then scans off the main actor.
    private func runSearch() async {
        guard isSearching else {
            results = nil
            return
        }
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled, let index = searchIndex else { return }
        let text = query
        let found = await Task.detached(priority: .userInitiated) { index.search(text) }.value
        guard !Task.isCancelled else { return }
        results = found
    }
}

/*-----------------------------dictionary-parts-----------------------------*/

private extension DictionaryView {
    func openDrawSearch() {
        let entry = HandwritingSearchEntry.open(access: proAccess?.access ?? .locked, existing: handwriting) {
            HandwritingSearchModel.live(contentStore: services?.contentStore ?? BundledKanjiContentStore())
        }
        switch entry {
        case .paywall(let feature):
            paywallFeature = feature
        case .pad(let model):
            handwriting = model
            drawSearch = DrawSearchPresentation(model: model)
        }
    }

    func openPhotoLookup() {
        switch PhotoLookupEntry.open(access: proAccess?.access ?? .locked) {
        case .paywall(let feature):
            paywallFeature = feature
        case .sheet:
            path.append(PhotoLookupPresentation(model: PhotoLookupModel(
                reader: SystemPhotoTextReader(),
                contentStore: services?.contentStore ?? BundledKanjiContentStore(),
                learnerStore: services?.learnerStore
            )))
        }
    }

    func messageView(title: String, message: String) -> some View {
        VStack(spacing: LayoutTokens.space16) {
            Spacer()
            Text(title)
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutTokens.space32)
            Spacer()
        }
    }

    func retryView(message: String) -> some View {
        VStack(spacing: LayoutTokens.space16) {
            Spacer()
            Text("Could not load the dictionary")
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutTokens.space32)
            PrimaryButton(title: "Retry") {
                errorMessage = nil
                reloadID = UUID()
            }
            .padding(.horizontal, LayoutTokens.space32)
            Spacer()
        }
    }
}
