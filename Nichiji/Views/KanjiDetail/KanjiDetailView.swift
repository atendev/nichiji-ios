import SwiftUI

/*--------------------------------content---------------------------------*/

/// Everything the detail screen shows for one kanji.
struct KanjiDetailContent: Equatable, Sendable {
    let entry: KanjiEntry
    let strokePaths: [String]
    let stage: StudyStage?

    /// A missing record throws `contentMissing`; missing strokes or progress only hide their parts.
    static func load(
        kanjiID: String,
        contentStore: any KanjiContentStore,
        learnerStore: any LearnerStore
    ) async throws -> KanjiDetailContent {
        let entry = try contentStore.entry(for: kanjiID)
        let strokePaths = (try? contentStore.strokePaths(for: kanjiID)) ?? []
        let stage = try? await learnerStore.progress(for: kanjiID)?.stage
        return KanjiDetailContent(entry: entry, strokePaths: strokePaths, stage: stage)
    }
}

/*---------------------------------detail---------------------------------*/

/// Shared kanji detail screen, pushed from Dictionary and from You.
struct KanjiDetailView: View {
    let kanjiID: String

    @Environment(\.serviceContainer) private var services
    @AppStorage(
        LearnerPreferenceKey.showsRomaji.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var showsRomaji: Bool = true

    @State private var content: KanjiDetailContent?
    @State private var stage: StudyStage?
    @State private var errorMessage: String?
    @State private var practiceTarget: PracticeTarget?

    var body: some View {
        Group {
            if let content {
                detail(content)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutTokens.space32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // The Dictionary root hides its bar; detail needs it back for the "Dictionary" back button.
        .toolbar(.visible, for: .navigationBar)
        .practiceSheet(target: $practiceTarget)
        .task(id: kanjiID) {
            await load()
        }
        // A pushed detail outlives tab switches, so Forget it on Today or a review can change the stage underneath it.
        .onAppear {
            Task { await refreshStage() }
        }
    }

    private func detail(_ content: KanjiDetailContent) -> some View {
        let kanji = content.entry
        return ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutTokens.space24) {
                KanjiHeroView(
                    kanji: kanji.id,
                    primaryMeaning: kanji.meanings.first ?? "",
                    onPlayAudio: { speak(kanji.id, reading: kanji.onyomi.first?.kana ?? kanji.kunyomi.first?.kana) }
                )

                DetailsCardView(
                    onyomi: kanji.onyomi,
                    kunyomi: kanji.kunyomi,
                    radical: kanji.radical.character,
                    strokeCount: kanji.strokeCount,
                    jlptLevel: kanji.jlptLevel.map { $0.rawValue },
                    isJLPTLevelEstimated: kanji.isJLPTLevelEstimated,
                    joyoGrade: kanji.joyoGrade?.detailsLabel,
                    showsRomaji: showsRomaji
                )

                ExampleWordsCardView(
                    words: kanji.exampleWords,
                    showsRomaji: showsRomaji,
                    onPlayAudio: { word in speak(word.word, reading: word.kana) }
                )

                StrokeOrderCardView(
                    strokeCount: kanji.strokeCount,
                    strokePaths: content.strokePaths,
                    onPractice: { practiceTarget = PracticeTarget(entry: kanji, strokePaths: content.strokePaths) }
                )

                ForgetItControl(kanjiID: kanji.id, stage: stage) {
                    stage = .new
                }
            }
            .padding(.bottom, LayoutTokens.space32)
        }
    }

    private func load() async {
        guard let services else {
            errorMessage = "This kanji is not ready yet."
            return
        }
        do {
            let loaded = try await KanjiDetailContent.load(
                kanjiID: kanjiID,
                contentStore: services.contentStore,
                learnerStore: services.learnerStore
            )
            content = loaded
            stage = loaded.stage
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshStage() async {
        guard let services else { return }
        stage = try? await services.learnerStore.progress(for: kanjiID)?.stage
    }

    private func speak(_ text: String, reading: String?) {
        guard let services else { return }
        try? services.pronunciationService.speak(text, reading: reading)
    }
}
