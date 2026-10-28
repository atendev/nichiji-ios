import SwiftUI

/*---------------------------------levels---------------------------------*/

public struct LevelSettingsView: View {
    @AppStorage(LearnerPreferenceKey.levelSystem.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var levelSystemRaw: String = LevelSystem.jlpt.rawValue

    @AppStorage(LearnerPreferenceKey.dailyOrder.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var dailyOrderRaw: String = DailyOrder.mostCommon.rawValue

    public init() {}

    public var body: some View {
        List {
            Section("Levels based on") {
                Picker("Level System", selection: $levelSystemRaw) {
                    Text("JLPT").tag(LevelSystem.jlpt.rawValue)
                    Text("Jōyō").tag(LevelSystem.joyo.rawValue)
                }
                .pickerStyle(.segmented)
            }

            Section("Daily order") {
                orderRow(order: .mostCommon, title: "Most common")
                orderRow(order: .listOrder, title: "List order")
                orderRow(order: .random, title: "Random")
            }

            Section {
                NavigationLink("Customize your kanji") {
                    Text("Custom pool selector")
                        .font(.nichijiBody)
                }
            }
        }
        .navigationTitle("Level & Order")
    }

    private func orderRow(order: DailyOrder, title: String) -> some View {
        Button(action: { dailyOrderRaw = order.rawValue }) {
            HStack {
                Text(title)
                    .foregroundColor(.nichijiInk)
                Spacer()
                if dailyOrderRaw == order.rawValue {
                    Image(systemName: "checkmark")
                        .foregroundColor(.nichijiVermilion)
                }
            }
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Wire pool re-assignment triggers when changing level or order in Slice 4 and Slice 8.
