import SwiftData
import SwiftUI

/*----------------------------------today---------------------------------*/

public struct TodayView: View {
    public let onOpenSettings: () -> Void

    @Environment(\.serviceContainer) private var services
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(
        LearnerPreferenceKey.showsRomaji.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var showsRomaji: Bool = true
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

    @Query private var learnerProgress: [KanjiProgress]
    @Query private var dailyAssignments: [DailyAssignment]
    @Query private var customSelections: [CustomKanjiSelection]

    @State private var assignment: DailyAssignmentSnapshot?
    @State private var kanji: KanjiEntry?
    @State private var strokePaths: [String] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var reloadID = UUID()
    @State private var wasBackgrounded = false

    private var poolPreferenceSignature: String {
        "\(levelSystemRaw)-\(selectedJLPTLevelRaw)-\(selectedJoyoGradeRaw)-\(dailyOrderRaw)-\(isCustomPoolActive)-\(customSelections.count)"
    }

    private var assignmentsSignature: String {
        dailyAssignments
            .map { "\($0.calendarDay):\($0.kanjiID):\($0.statusRaw)" }
            .joined(separator: "|")
    }

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            HeaderBar(kanjiTitle: "今日", englishTitle: "Today") {
                Button(action: onOpenSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.nichijiInk)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
                .minTouchTarget()
                .accessibilityLabel("Open settings")
            }

            // Keep the content mounted during a reload so its scroll position survives.
            if isLoading && kanji == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                retryView(message: errorMessage)
            } else if assignment == nil {
                LevelCompleteView(onOpenSettings: onOpenSettings)
            } else if let kanji {
                todayContent(kanji: kanji)
            }
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .task(id: reloadID) {
            await loadToday()
        }
        .onChange(of: scenePhase) { _, phase in
            // Control Center only passes through .inactive, so refresh after a real background trip.
            if phase == .background { wasBackgrounded = true }
            guard phase == .active, wasBackgrounded else { return }
            wasBackgrounded = false
            Task {
                await refreshAfterActivation()
            }
        }
        .onChange(of: learnerProgress.count) { _, _ in
            reloadID = UUID()
        }
        .onChange(of: poolPreferenceSignature) { _, _ in
            reloadID = UUID()
        }
        .onChange(of: assignmentsSignature) { _, _ in
            reloadID = UUID()
        }
    }

    @ViewBuilder
    private func todayContent(kanji: KanjiEntry) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutTokens.space24) {
                KanjiHeroView(
                    kanji: kanji.id,
                    primaryMeaning: kanji.meanings.first ?? "",
                    onPlayAudio: { speak(kanji.id, reading: kanji.onyomi.first?.kana ?? kanji.kunyomi.first?.kana) }
                )

                if assignment?.status == .learned {
                    SealStamp(text: "Learned today")
                        .padding(.bottom, LayoutTokens.space8)
                        .accessibilityLabel("Learned today")
                } else {
                    PrimaryButton(title: "Got it", action: markLearned)
                        .padding(.horizontal, LayoutTokens.space24)
                        .padding(.bottom, LayoutTokens.space8)
                }

                DetailsCardView(
                    onyomi: kanji.onyomi,
                    kunyomi: kanji.kunyomi,
                    radical: kanji.radical.character,
                    strokeCount: kanji.strokeCount,
                    jlptLevel: kanji.jlptLevel.map { $0.rawValue },
                    joyoGrade: kanji.joyoGrade.map(gradeLabel),
                    showsRomaji: showsRomaji
                )

                ExampleWordsCardView(
                    words: kanji.exampleWords,
                    showsRomaji: showsRomaji,
                    onPlayAudio: { word in
                        speak(word.word, reading: word.kana)
                    }
                )

                StrokeOrderCardView(
                    strokeCount: kanji.strokeCount,
                    strokePaths: strokePaths
                )
            }
            .padding(.bottom, LayoutTokens.space32)
        }
        .id(kanji.id)
    }

    private func retryView(message: String) -> some View {
        VStack(spacing: LayoutTokens.space16) {
            Spacer()
            Text("Could not load today's kanji")
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

    private func loadToday() async {
        guard let services else {
            errorMessage = "Today is not ready yet."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let day = services.dayProvider.calendarDay(for: services.dayProvider.now)
            let loadedAssignment = try await services.dailyKanjiService.assignment(for: day)
            assignment = loadedAssignment
            guard let loadedAssignment else {
                kanji = nil
                strokePaths = []
                return
            }

            let loadedKanji = try services.contentStore.entry(for: loadedAssignment.kanjiID)
            kanji = loadedKanji
            strokePaths = try services.contentStore.strokePaths(for: loadedKanji.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshAfterActivation() async {
        guard let services else { return }
        do {
            let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
            let preferences = LearnerPreferencesSnapshot.load(from: defaults)
            try await services.handleTimeOrZoneChange(preferences: preferences)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        reloadID = UUID()
    }

    private func markLearned() {
        guard let services, let assignment else { return }
        Task {
            do {
                self.assignment = try await services.learnerStore.markLearned(day: assignment.calendarDay)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func speak(_ text: String, reading: String?) {
        guard let services else { return }
        do {
            try services.pronunciationService.speak(text, reading: reading)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func gradeLabel(_ grade: JoyoGrade) -> String {
        switch grade {
        case .grade1: "1"
        case .grade2: "2"
        case .grade3: "3"
        case .grade4: "4"
        case .grade5: "5"
        case .grade6: "6"
        case .secondary: "Secondary"
        }
    }
}
