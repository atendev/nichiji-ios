import SwiftUI

/*-------------------------------dictionary-------------------------------*/

public struct DictionaryView: View {
    public let onOpenSettings: () -> Void

    @Environment(\.serviceContainer) private var services
    @AppStorage(
        LearnerPreferenceKey.levelSystem.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var levelSystemRaw: String = LevelSystem.jlpt.rawValue

    @State private var sections: [KanjiBrowseSection] = []
    @State private var errorMessage: String?
    @State private var isLoaded = false
    @State private var reloadID = UUID()

    private var activeLevelSystem: LevelSystem {
        LevelSystem(rawValue: levelSystemRaw) ?? .jlpt
    }

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        NavigationStack {
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

                // TODO: "Build Dictionary search" adds the search bar and its results above the grid.

                if let errorMessage {
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
        }
        .task(id: "\(levelSystemRaw)-\(reloadID)") {
            await loadSections()
        }
    }

    private var browseGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: LayoutTokens.space32) {
                ForEach(sections) { section in
                    sectionView(section)
                }
            }
            .padding(.horizontal, LayoutTokens.screenMarginCompact)
            .padding(.top, LayoutTokens.space8)
            .padding(.bottom, LayoutTokens.space32)
        }
    }

    private func sectionView(_ section: KanjiBrowseSection) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            HStack(alignment: .firstTextBaseline) {
                Text(section.title)
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(section.countLabel)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }

            LazyVGrid(columns: KanjiGridTile.columns, spacing: KanjiGridTile.spacing) {
                ForEach(section.entries) { entry in
                    NavigationLink(value: KanjiDetailRoute(kanjiID: entry.id)) {
                        KanjiGridTile(kanji: entry.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(KanjiGridTile.accessibilityLabel(kanji: entry.id, meaning: entry.primaryMeaning))
                    .accessibilityHint("Opens kanji details")
                }
            }
        }
    }

    private func retryView(message: String) -> some View {
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
}
