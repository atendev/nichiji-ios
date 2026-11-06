import SwiftUI

/*--------------------------------known-kanji-----------------------------*/

/// Quiet control beside Forget it: mark a new kanji as already known, or take the mark back.
struct KnownKanjiControl: View {
    enum Choice: Equatable {
        case declare
        case undeclare

        var title: String {
            switch self {
            case .declare: "I know this"
            case .undeclare: "Not known after all"
            }
        }

        var hint: String {
            switch self {
            case .declare: "Marks this kanji as known, so it leaves your daily kanji and reviews"
            case .undeclare: "Returns this kanji to new"
            }
        }
    }

    let kanjiID: String
    let stage: StudyStage?
    let isDeclared: Bool
    let onChanged: () async -> Void

    @Environment(\.serviceContainer) private var services
    @State private var isWorking = false
    @State private var errorMessage: String?

    /// Only a new kanji can be marked, and only a marked one can be unmarked; kanji in study offer neither.
    static func choice(stage: StudyStage?, isDeclared: Bool) -> Choice? {
        if isDeclared { return .undeclare }
        switch stage {
        case .none, .some(.new): return .declare
        case .some(.learning), .some(.familiar), .some(.known): return nil
        }
    }

    var body: some View {
        if let choice = Self.choice(stage: stage, isDeclared: isDeclared) {
            VStack(spacing: LayoutTokens.space4) {
                Button(choice.title) {
                    apply(choice)
                }
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .padding(.horizontal, LayoutTokens.space16)
                .minTouchTarget()
                .disabled(isWorking)
                .accessibilityHint(choice.hint)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LayoutTokens.space32)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func apply(_ choice: Choice) {
        guard let services else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
                let preferences = LearnerPreferencesSnapshot.load(from: defaults)
                switch choice {
                case .declare:
                    try await services.setKnown(declare: [kanjiID], undeclare: [], preferences: preferences)
                case .undeclare:
                    try await services.setKnown(declare: [], undeclare: [kanjiID], preferences: preferences)
                }
                errorMessage = nil
                await onChanged()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
