import SwiftUI

/*------------------------------settings-row------------------------------*/

/// Known kanji row in the Settings sheet, with how many kanji the learner marked.
struct KnownKanjiSettingsRow: View {
    @Environment(\.serviceContainer) private var services
    @State private var knownCount = 0

    var body: some View {
        NavigationLink {
            KnownKanjiPickerView(scope: .allLevels)
        } label: {
            settingsNavigationRow(
                title: "Known kanji",
                subtitle: "Skip kanji you already know.",
                value: knownCount == 0 ? nil : "\(knownCount) kanji"
            )
        }
        .buttonStyle(.plain)
        .task { await refreshCount() }
    }

    private func refreshCount() async {
        guard let learnerStore = services?.learnerStore,
              let ids = try? await learnerStore.declaredKnownIDs()
        else { return }
        knownCount = ids.count
    }
}
