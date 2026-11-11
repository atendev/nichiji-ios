import SwiftUI

/*--------------------------------known-kanji-----------------------------*/

/// Top of the kanji detail: mark a new kanji as already known, or show that it is and let the mark be taken back.
struct KnownKanjiControl: View {
    enum Choice: Equatable {
        case declare
        case undeclare

        var title: String {
            switch self {
            case .declare: "I know this kanji"
            case .undeclare: "Undo"
            }
        }

        var hint: String {
            switch self {
            case .declare: "Marks this kanji as known. It skips your daily kanji and goes into your reviews"
            case .undeclare: "Returns this kanji to new and takes it out of your reviews"
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
            VStack(spacing: LayoutTokens.space8) {
                switch choice {
                case .declare:
                    Button {
                        apply(choice)
                    } label: {
                        Label(choice.title, systemImage: "checkmark.circle")
                            .padding(.vertical, LayoutTokens.space8)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isWorking)
                    .accessibilityHint(choice.hint)
                case .undeclare:
                    HStack(spacing: LayoutTokens.space8) {
                        Label("Known", systemImage: "checkmark.circle.fill")
                            .font(.nichijiCallout.weight(.medium))
                            .foregroundColor(.nichijiMatcha)

                        Spacer(minLength: LayoutTokens.space8)

                        Button(choice.title) {
                            apply(choice)
                        }
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                        .minTouchTarget()
                        .disabled(isWorking)
                        .accessibilityHint(choice.hint)
                    }
                    .padding(.horizontal, LayoutTokens.space16)
                    .frame(minHeight: LayoutTokens.minHitTarget + LayoutTokens.space8)
                    .accessibilityElement(children: .contain)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, LayoutTokens.screenMarginCompact)
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
