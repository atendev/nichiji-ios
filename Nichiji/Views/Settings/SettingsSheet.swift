import SwiftUI

/*--------------------------------settings--------------------------------*/

public struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(LearnerPreferenceKey.showsRomaji.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var showsRomaji: Bool = true

    @AppStorage(LearnerPreferenceKey.streakFreezeEnabled.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var streakFreezeEnabled: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    AppearancePickerView()
                        .padding(.vertical, LayoutTokens.space8)
                }

                Section("Learning") {
                    NavigationLink("Level & Order") {
                        LevelSettingsView()
                    }

                    NavigationLink("Daily Reminder") {
                        ReminderSettingsView()
                    }

                    Toggle("Show romaji", isOn: $showsRomaji)
                        .tint(.nichijiVermilion)

                    Toggle("Streak freeze", isOn: $streakFreezeEnabled)
                        .tint(.nichijiVermilion)
                }

                Section("About") {
                    HStack {
                        Text("Privacy")
                        Spacer()
                        Text("Data not collected")
                            .foregroundColor(.nichijiInkSubtle)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.0.4")
                            .foregroundColor(.nichijiInkSubtle)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.nichijiVermilion)
                }
            }
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Bind active Level and Daily Reminder label summaries in the main Settings list rows in Slice 8.
