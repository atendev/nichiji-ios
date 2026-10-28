import SwiftUI

/*-----------------------------reminder-setup-----------------------------*/

public struct ReminderSetupView: View {
    public let onNext: () -> Void
    public let onBack: () -> Void

    @AppStorage(LearnerPreferenceKey.reminderEnabled.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var reminderEnabled: Bool = true

    @AppStorage(LearnerPreferenceKey.reminderHour.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var reminderHour: Int = 8

    @AppStorage(LearnerPreferenceKey.reminderMinute.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var reminderMinute: Int = 0

    public init(onNext: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.onNext = onNext
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: LayoutTokens.space24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.nichijiInk)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
                Spacer()
            }
            .padding(.horizontal, LayoutTokens.space16)

            VStack(spacing: LayoutTokens.space8) {
                Text("Daily reminder")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("A gentle reminder to learn today's kanji.")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInkMuted)
            }
            .padding(.horizontal, LayoutTokens.space24)

            Spacer()

            VStack(spacing: LayoutTokens.space16) {
                Toggle("Remind me each day", isOn: $reminderEnabled)
                    .font(.nichijiBody)
                    .tint(.nichijiVermilion)
                    .padding(.horizontal, LayoutTokens.space32)

                Text(String(format: "%02d:%02d", reminderHour, reminderMinute))
                    .font(.kanjiDisplay(size: 48))
                    .foregroundColor(.nichijiInk)
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onNext)
                .padding(.horizontal, LayoutTokens.space24)
                .padding(.bottom, LayoutTokens.space32)
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Request system notification authorization and schedule the initial rolling reminder window in Slice 9 and Slice 10.
