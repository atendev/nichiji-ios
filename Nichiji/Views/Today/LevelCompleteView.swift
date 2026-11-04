import SwiftUI

/*--------------------------------summary---------------------------------*/

/// What the level-complete screen shows for a finished level.
struct LevelCompleteSummary: Equatable, Sendable {
    let title: String
    let figures: [StatTile]
    /// Nil after N1 and Secondary, which have no next level.
    let nextLevel: StudyLevel?

    init(level: StudyLevel, figures: LevelCompleteFigures) {
        title = "\(level.title) complete"
        self.figures = [
            StatTile(value: "\(figures.kanjiLearned)", label: "Kanji learned"),
            StatTile(value: figures.daysTaken.map(String.init) ?? "–", label: "Days taken"),
            StatTile(value: YouCopy.rate(figures.gotItRate), label: "Got it rate")
        ]
        nextLevel = LevelSequence.next(after: level)
    }

    var startTitle: String? {
        nextLevel.map { "Start \($0.title)" }
    }

    var message: String {
        nextLevel == nil
            ? "Keep reviewing to hold on to them, or pick a new study pool in Settings."
            : "Keep reviewing to hold on to them, or start the next level."
    }
}

/*-----------------------------level-complete-----------------------------*/

public struct LevelCompleteView: View {
    public let onOpenSettings: () -> Void

    @Environment(\.serviceContainer) private var services

    @State private var summary: LevelCompleteSummary?
    @State private var isLoaded = false
    @State private var isSwitching = false

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, LayoutTokens.space32)
                    .padding(.vertical, LayoutTokens.space24)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .task {
            await load()
        }
    }

    @ViewBuilder private var content: some View {
        if !isLoaded {
            ProgressView()
        } else if let summary {
            levelContent(summary)
        } else {
            customPoolContent
        }
    }

    private func levelContent(_ summary: LevelCompleteSummary) -> some View {
        VStack(spacing: LayoutTokens.space16) {
            SealStamp(text: "All learned")

            Text(summary.title)
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(summary.message)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)

            HStack(spacing: LayoutTokens.space8) {
                ForEach(summary.figures, id: \.label) { figure in
                    figureTile(figure)
                }
            }
            .padding(.vertical, LayoutTokens.space8)

            if let startTitle = summary.startTitle, let next = summary.nextLevel {
                PrimaryButton(title: startTitle, isEnabled: !isSwitching) { start(next) }
                SecondaryButton(title: "Open Settings", action: onOpenSettings)
            } else {
                PrimaryButton(title: "Open Settings", action: onOpenSettings)
            }
        }
    }

    /// Custom pools have no level, so they keep the plain message and the Settings button.
    private var customPoolContent: some View {
        VStack(spacing: LayoutTokens.space16) {
            SealStamp(text: "Level complete")

            Text("You've learned all kanji in this level.")
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)
                .multilineTextAlignment(.center)

            Text("Choose another level or customize your study pool in Settings.")
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Open Settings", action: onOpenSettings)
                .padding(.top, LayoutTokens.space16)
        }
    }

    private func figureTile(_ figure: StatTile) -> some View {
        VStack(spacing: LayoutTokens.space4) {
            Text(figure.value)
                .font(.uiText(size: 28, weight: .medium))
                .monospacedDigit()
                .foregroundColor(.nichijiInk)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(figure.label)
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(LayoutTokens.space12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(figure.label), \(figure.value == "–" ? "none yet" : figure.value)")
    }

    /// A failed figures load falls back to the custom-pool copy rather than an error.
    private func load() async {
        defer { isLoaded = true }
        guard let services else { return }
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        guard let level = LevelSequence.current(preferences: LearnerPreferencesSnapshot.load(from: defaults)),
              let figures = try? await services.statsService.levelComplete(level: level)
        else { return }
        summary = LevelCompleteSummary(level: level, figures: figures)
    }

    /// Today follows the saved level through its preference and assignment observers.
    private func start(_ level: StudyLevel) {
        guard let services, !isSwitching else { return }
        isSwitching = true
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        let updated = LevelSequence.preferences(starting: level, from: LearnerPreferencesSnapshot.load(from: defaults))
        updated.save(to: defaults)
        Task {
            _ = try? await services.applyLevelChange(preferences: updated)
            isSwitching = false
        }
    }
}
