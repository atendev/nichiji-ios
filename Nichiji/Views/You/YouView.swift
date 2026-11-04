import SwiftData
import SwiftUI

/*----------------------------------you-----------------------------------*/

/// You tab: stats, activity, level progress, milestones, Needs attention and the learner's kanji.
public struct YouView: View {
    public let onOpenSettings: () -> Void

    @Environment(\.serviceContainer) private var services
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(
        LearnerPreferenceKey.streakFreezeEnabled.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var streakFreezeEnabled: Bool = false
    @AppStorage(
        LearnerPreferenceKey.levelSystem.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var levelSystemRaw: String = LevelSystem.jlpt.rawValue

    // Every study action adds a row, so the count is the change signal.
    @Query private var studyLog: [StudyLogEntry]

    @State private var stats: LearnerStats?
    @State private var meanings: [String: String] = [:]
    @State private var errorMessage: String?
    @State private var refreshID = UUID()
    @State private var path: [KanjiDetailRoute] = []

    private struct StatsRequest: Hashable {
        let logCount: Int
        let freezeEnabled: Bool
        let levelSystem: String
        let refreshID: UUID
    }

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                HeaderBar(kanjiTitle: "私", englishTitle: "You") {
                    Button(action: onOpenSettings) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.nichijiInk)
                            .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                    }
                    .minTouchTarget()
                    .accessibilityLabel("Open settings")
                }

                if let caption = YouCopy.learningSince(stats?.learningSince) {
                    HeaderCaption(text: caption)
                }

                content
            }
            .background(Color.nichijiSurface.ignoresSafeArea())
            // The pushed detail screen's back button reads this title.
            .navigationTitle("You")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: KanjiDetailRoute.self) { route in
                KanjiDetailView(kanjiID: route.kanjiID)
            }
        }
        .task(id: StatsRequest(logCount: studyLog.count, freezeEnabled: streakFreezeEnabled, levelSystem: levelSystemRaw, refreshID: refreshID)) {
            await load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshID = UUID() }
        }
    }

    @ViewBuilder private var content: some View {
        if let stats {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: LayoutTokens.space16) {
                    VStack(spacing: LayoutTokens.space8) {
                        StatTilesGrid(tiles: YouCopy.tiles(stats))
                        if let freeze = YouCopy.freezeRow(stats.streakFreeze) {
                            FreezeRow(copy: freeze)
                        }
                    }
                    ActivityCard(weeks: stats.activity)
                    LevelBarsCard(rows: stats.levelBars.map(YouCopy.levelRow))
                    MilestonesCard(milestones: stats.milestones)
                    NeedsAttentionCard(items: stats.needsAttention, meanings: meanings)
                    YourKanjiSection(
                        learnedCount: stats.kanjiLearned,
                        learnedKanjiIDs: stats.learnedKanjiIDs,
                        meanings: meanings,
                        logCount: studyLog.count
                    )
                }
                .padding(.horizontal, LayoutTokens.screenMarginCompact)
                .padding(.top, LayoutTokens.space16)
                .padding(.bottom, LayoutTokens.space32)
            }
        } else if let errorMessage {
            retryView(message: errorMessage)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func retryView(message: String) -> some View {
        VStack(spacing: LayoutTokens.space16) {
            Spacer()
            Text("Could not load your stats")
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
                refreshID = UUID()
            }
            .padding(.horizontal, LayoutTokens.space32)
            Spacer()
        }
    }

    /// Keeps the last stats on screen while a reload runs, so the scroll position survives.
    private func load() async {
        guard let services else {
            errorMessage = "Your stats are not ready yet."
            return
        }
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        let preferences = LearnerPreferencesSnapshot.load(from: defaults)
        do {
            let loaded = try await services.statsService.stats(preferences: preferences)
            guard !Task.isCancelled else { return }
            if meanings.isEmpty, let index = try? services.contentStore.indexEntries() {
                meanings = Dictionary(index.map { ($0.id, $0.primaryMeaning) }, uniquingKeysWith: { first, _ in first })
            }
            stats = loaded
            errorMessage = nil
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
