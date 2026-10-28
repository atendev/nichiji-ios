import SwiftUI

/*--------------------------------reminder--------------------------------*/

public struct ReminderSettingsView: View {
    @AppStorage(
        LearnerPreferenceKey.reminderEnabled.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var reminderEnabled: Bool = true

    @AppStorage(
        LearnerPreferenceKey.reminderHour.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var reminderHour: Int = 8

    @AppStorage(
        LearnerPreferenceKey.reminderMinute.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var reminderMinute: Int = 0

    @State private var isPermissionDenied: Bool = false

    public init() {}

    public var body: some View {
        List {
            if isPermissionDenied {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.nichijiMustard)
                        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                            Text("Notifications are off")
                                .font(.nichijiBody.bold())
                                .foregroundColor(.nichijiInk)
                            Text("Enable notifications in iOS Settings to receive daily reminders.")
                                .font(.nichijiCaption)
                                .foregroundColor(.nichijiInkMuted)
                        }
                    }
                }
            }

            Section {
                Toggle("Daily reminder", isOn: $reminderEnabled)
                    .tint(.nichijiVermilion)

                HStack {
                    Text("Time")
                        .foregroundColor(.nichijiInk)
                    Spacer()
                    Text(String(format: "%02d:%02d", reminderHour, reminderMinute))
                        .foregroundColor(.nichijiInkMuted)
                }
            }
        }
        .navigationTitle("Daily Reminder")
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Connect ReminderScheduler permission status checks and 7-day rolling window rebuilds in Slice 8 and Slice 10.
