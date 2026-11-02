import SwiftData
import SwiftUI

/*---------------------------------review---------------------------------*/

/// Review tab home: what is due, stage counts, what comes up next, and this week's review days.
public struct ReviewView: View {
    public let onOpenSettings: () -> Void

    @Environment(\.serviceContainer) private var services
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(
        ReviewPreferenceKey.sessionSize.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var sessionSizeRaw: String = ReviewSessionSize.ten.rawValue
    @AppStorage(
        ReviewPreferenceKey.order.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var orderRaw: String = ReviewOrder.dueFirst.rawValue

    @Query private var learnerProgress: [KanjiProgress]
    @Query private var studyLog: [StudyLogEntry]

    @State private var isSessionPresented = false
    @State private var showsSessionOptions = false
    // Bumped on return to the foreground so due counts follow the date.
    @State private var refreshID = UUID()

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }

    private var sessionSize: ReviewSessionSize {
        ReviewSessionSize(rawValue: sessionSizeRaw) ?? .ten
    }

    private var optionsSummary: String {
        ReviewPreferencesSnapshot.settingsSummary(
            sessionSize: sessionSize,
            order: ReviewOrder(rawValue: orderRaw) ?? .dueFirst
        )
    }

    private var summary: ReviewHomeSummary {
        _ = refreshID
        return ReviewHomeSummary(
            progress: learnerProgress.map(\.snapshot),
            reviewLog: studyLog.map { (action: $0.action, calendarDay: $0.calendarDay) },
            sessionSize: sessionSize,
            dayProvider: services?.dayProvider ?? SystemDayProvider()
        )
    }

    public var body: some View {
        NavigationStack {
            content(summary: summary)
                .background(Color.nichijiSurface.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showsSessionOptions) {
                    ReviewSettingsView()
                }
        }
        .fullScreenCover(isPresented: $isSessionPresented) {
            if let services {
                ReviewSessionView(services: services)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshID = UUID() }
        }
        .onChange(of: isSessionPresented) { _, presented in
            if !presented { refreshID = UUID() }
        }
    }

    private func content(summary: ReviewHomeSummary) -> some View {
        VStack(spacing: 0) {
            HeaderBar(kanjiTitle: "復習", englishTitle: "Review") {
                Button(action: onOpenSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.nichijiInk)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
                .minTouchTarget()
                .accessibilityLabel("Open settings")
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutTokens.space16) {
                    ReviewDueCard(
                        summary: summary,
                        optionsSummary: optionsSummary,
                        onStart: { isSessionPresented = true },
                        onOptions: { showsSessionOptions = true }
                    )
                    ReviewStagesCard(summary: summary)
                    ReviewComingUpCard(summary: summary)
                    ReviewWeekCard(week: summary.week)
                }
                .padding(.horizontal, LayoutTokens.screenMarginCompact)
                .padding(.top, LayoutTokens.space16)
                .padding(.bottom, LayoutTokens.space32)
            }
        }
    }
}

/*--------------------------------snapshot--------------------------------*/

extension KanjiProgress {
    var snapshot: KanjiProgressSnapshot {
        KanjiProgressSnapshot(
            kanjiID: kanjiID,
            stage: stage,
            firstLearnedAt: firstLearnedAt,
            lastReviewedAt: lastReviewedAt,
            nextReviewAt: nextReviewAt,
            gotItCount: gotItCount,
            forgotItCount: forgotItCount
        )
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Show the "N DAY STREAK" subtitle under the header in "Build the You tab", from the stats service.
