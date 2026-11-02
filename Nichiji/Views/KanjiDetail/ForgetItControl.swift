import SwiftUI

/*--------------------------------forget-it-------------------------------*/

/// Quiet reset at the foot of a kanji screen. It confirms first, since it drops the review schedule.
struct ForgetItControl: View {
    let kanjiID: String
    let stage: StudyStage?
    let onForgotten: () -> Void

    @Environment(\.serviceContainer) private var services
    @State private var isConfirming = false
    @State private var isWorking = false
    @State private var errorMessage: String?

    /// Only kanji past `new` have progress to reset; a new kanji would just log an empty reset.
    static func isAvailable(for stage: StudyStage?) -> Bool {
        switch stage {
        case .learning, .familiar, .known:
            true
        case .new, nil:
            false
        }
    }

    var body: some View {
        if Self.isAvailable(for: stage) {
            VStack(spacing: LayoutTokens.space4) {
                Button("Forget it") {
                    isConfirming = true
                }
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .padding(.horizontal, LayoutTokens.space16)
                .minTouchTarget()
                .disabled(isWorking)
                .accessibilityHint("Resets this kanji to new")

                if let errorMessage {
                    Text(errorMessage)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LayoutTokens.space32)
                }
            }
            .frame(maxWidth: .infinity)
            .confirmationDialog("Forget \(kanjiID)?", isPresented: $isConfirming, titleVisibility: .visible) {
                Button("Forget it", role: .destructive, action: forget)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("It goes back to new, leaves your reviews and can come up as a daily kanji again. Your history stays.")
            }
        }
    }

    private func forget() {
        guard let services else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
                try await services.forgetIt(kanjiID: kanjiID, preferences: LearnerPreferencesSnapshot.load(from: defaults))
                errorMessage = nil
                onForgotten()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
