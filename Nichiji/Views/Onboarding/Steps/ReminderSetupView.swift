import SwiftUI

/*-----------------------------reminder-setup-----------------------------*/

struct ReminderSetupView: View {
    @Bindable var flow: OnboardingFlow

    var body: some View {
        OnboardingStepScaffold(
            buttonTitle: "Continue",
            isButtonEnabled: !flow.isRequestingAuthorization,
            action: { Task { await flow.continueFromReminder() } },
            content: {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Daily reminder",
                    subtitle: "One gentle reminder a day to learn today's kanji.",
                    alignment: .leading
                )

                if flow.reminderAuthorization == .denied {
                    deniedRow
                }

                Toggle("Remind me daily", isOn: $flow.reminderEnabled)
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                    .tint(.nichijiVermilion)
                    .padding(.horizontal, LayoutTokens.space16)
                    .frame(minHeight: 64)
                    .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)

                if flow.reminderEnabled {
                    ReminderTimePicker(hour: $flow.reminderHour, minute: $flow.reminderMinute)
                } else {
                    Text("No reminder will be sent. You can turn it on later in Settings.")
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                        .padding(.horizontal, LayoutTokens.space8)
                }
            }
        })
        .task {
            await flow.refreshReminderAuthorization()
        }
    }

    private var deniedRow: some View {
        HStack(alignment: .top, spacing: LayoutTokens.space12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.nichijiMustard)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                Text("Notifications are off")
                    .font(.uiText(size: 16, weight: .medium))
                    .foregroundColor(.nichijiInk)

                Text("You can turn them on later in iOS Settings.")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LayoutTokens.space16)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiMustardWash, stroke: .nichijiMustard)
        .accessibilityElement(children: .combine)
    }
}
