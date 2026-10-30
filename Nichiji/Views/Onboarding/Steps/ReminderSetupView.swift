import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/*-----------------------------reminder-setup-----------------------------*/

struct ReminderSetupView: View {
    @Bindable var flow: OnboardingFlow

    /// The pager builds neighbouring steps off-screen; the prompt must wait until this one is showing.
    let isActive: Bool

    var body: some View {
        OnboardingStepScaffold(
            buttonTitle: "Continue",
            isButtonEnabled: !flow.isRequestingAuthorization,
            action: { flow.advance() },
            content: {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Daily reminder",
                    subtitle: "One gentle reminder a day to learn today's kanji.",
                    alignment: .leading
                )

                permissionButton

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
        .task(id: isActive) {
            guard isActive else { return }
            if flow.reminderEnabled {
                await flow.requestReminderAuthorizationIfNeeded()
            } else {
                await flow.refreshReminderAuthorization()
            }
        }
        .onChange(of: flow.reminderEnabled) { _, isOn in
            guard isOn, isActive else { return }
            Task { await flow.requestReminderAuthorizationIfNeeded() }
        }
    }

    private var permissionButton: some View {
        let status = flow.reminderAuthorization

        return Button {
            if status == .denied {
                openNotificationSettings()
            } else {
                Task { await flow.requestReminderAuthorizationIfNeeded() }
            }
        } label: {
            HStack(spacing: LayoutTokens.space12) {
                Image(systemName: status.symbolName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(status.tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                    Text(status.title)
                        .font(.uiText(size: 16, weight: .medium))
                        .foregroundColor(.nichijiInk)

                    if let detail = status.detail {
                        Text(detail)
                            .font(.nichijiCaption)
                            .foregroundColor(.nichijiInkMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if status != .authorized {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.nichijiInkSubtle)
                        .accessibilityHidden(true)
                }
            }
            .padding(LayoutTokens.space16)
            .frame(minHeight: 64)
            .cardBackground(
                cornerRadius: LayoutTokens.cornerRadiusSmall,
                fill: status == .denied ? .nichijiMustardWash : .nichijiSurfaceRaised,
                stroke: status == .denied ? .nichijiMustard : .nichijiHairline
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .disabled(flow.isRequestingAuthorization)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.title)
        .accessibilityHint(status.detail ?? "")
    }

    private func openNotificationSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}

/*-------------------------------status-copy------------------------------*/

private extension ReminderAuthorizationStatus {
    var title: String {
        switch self {
        case .authorized: "Notifications are on"
        case .denied: "Notifications are off"
        case .notDetermined: "Notifications not allowed yet"
        }
    }

    var detail: String? {
        switch self {
        case .authorized: nil
        case .denied: "Tap to turn them on in iOS Settings."
        case .notDetermined: "Tap to allow notifications."
        }
    }

    var symbolName: String {
        switch self {
        case .authorized: "bell.badge.fill"
        case .denied: "bell.slash"
        case .notDetermined: "bell"
        }
    }

    var tint: Color {
        switch self {
        case .authorized: .nichijiMatcha
        case .denied: .nichijiMustard
        case .notDetermined: .nichijiInkMuted
        }
    }
}
