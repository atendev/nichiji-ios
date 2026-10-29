import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private struct CardBackground: ViewModifier {
    let cornerRadius: CGFloat
    let fill: Color
    let stroke: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat, fill: Color, stroke: Color) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius, fill: fill, stroke: stroke))
    }
}

/*--------------------------------reminder--------------------------------*/

public struct ReminderSettingsView: View {
    @Environment(\.serviceContainer) private var services

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

    @State private var authorizationStatus: ReminderAuthorizationStatus = .notDetermined

    private var formattedTime: String {
        var snapshot = LearnerPreferencesSnapshot.standard
        snapshot.reminderHour = reminderHour
        snapshot.reminderMinute = reminderMinute
        return snapshot.formattedReminderTime
    }

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    Text("Daily reminder")
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)

                    Text("One reminder a day, naming the kanji. Never more than one.")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                }
                .padding(.top, LayoutTokens.space8)

                if authorizationStatus == .denied {
                    permissionDeniedBanner
                }

                reminderToggleCard

                if reminderEnabled {
                    notificationPreviewCard

                    timeSelectionSection
                } else {
                    Text("No reminder will be sent. You can still open Nichiji any time to see today's kanji.")
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                        .padding(.horizontal, LayoutTokens.space8)
                }
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.bottom, LayoutTokens.space48)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle("Daily reminder")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshAuthorizationStatus()
        }
        .onChange(of: reminderEnabled) { _, _ in
            Task {
                await syncReminderSchedule()
            }
        }
        .onChange(of: reminderHour * 60 + reminderMinute) { _, _ in
            Task {
                await syncReminderSchedule()
            }
        }
    }

    // MARK: - Subviews

    private var permissionDeniedBanner: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            HStack(alignment: .top, spacing: LayoutTokens.space12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.nichijiMustard)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                    Text("Notifications are off")
                        .font(.uiText(size: 16, weight: .medium))
                        .foregroundColor(.nichijiInk)

                    Text("Enable notifications in iOS Settings to receive daily reminders.")
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                }
            }

            Button {
                openSystemSettings()
            } label: {
                Text("Open Settings")
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiInk)
                    .padding(.horizontal, LayoutTokens.space16)
                    .frame(minHeight: LayoutTokens.minHitTarget)
                    .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiBorderControl)
            }
            .buttonStyle(.plain)
            .minTouchTarget()
            .accessibilityLabel("Open system notification settings")
        }
        .padding(LayoutTokens.space16)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiMustardWash, stroke: .nichijiMustard)
    }

    private var reminderToggleCard: some View {
        HStack(spacing: LayoutTokens.space12) {
            Toggle("Remind me daily", isOn: $reminderEnabled)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)
                .tint(.nichijiVermilion)
        }
        .padding(.horizontal, LayoutTokens.space16)
        .frame(minHeight: 64)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private var notificationPreviewCard: some View {
        HStack(spacing: LayoutTokens.space12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.nichijiVermilion)
                    .frame(width: 40, height: 40)

                Text("日")
                    .font(.kanjiDisplay(size: 20))
                    .foregroundColor(.nichijiOnVermilion)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Nichiji")
                        .font(.uiText(size: 14, weight: .medium))
                        .foregroundColor(.nichijiInk)

                    Spacer()

                    Text(formattedTime)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkSubtle)
                }

                HStack(spacing: 4) {
                    Text("学")
                        .font(.kanjiDisplay(size: 16))
                        .foregroundColor(.nichijiInk)

                    Text("· Today's kanji is ready")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)
                }
            }
        }
        .padding(LayoutTokens.space16)
        .cardBackground(cornerRadius: 20, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private var timeSelectionSection: some View {
        ReminderTimePicker(hour: $reminderHour, minute: $reminderMinute)
    }

    // MARK: - Actions

    private func refreshAuthorizationStatus() async {
        guard let scheduler = services?.reminderScheduler else { return }
        authorizationStatus = await scheduler.authorizationStatus()
    }

    private func syncReminderSchedule() async {
        guard let scheduler = services?.reminderScheduler else { return }
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        let preferences = LearnerPreferencesSnapshot.load(from: defaults)
        try? await ReminderSettingsCoordinator.applyReminderPreferences(
            preferences,
            scheduler: scheduler
        )
        authorizationStatus = await scheduler.authorizationStatus()
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}

/*------------------------------coordinator-------------------------------*/

enum ReminderSettingsCoordinator {
    /// Applies updated reminder preferences against a `ReminderScheduler` while preserving toggle state on denied permissions.
    static func applyReminderPreferences(
        _ preferences: LearnerPreferencesSnapshot,
        scheduler: any ReminderScheduler
    ) async throws {
        guard preferences.reminderEnabled else {
            await scheduler.cancelAllReminders()
            return
        }

        let status = await scheduler.authorizationStatus()
        switch status {
        case .notDetermined:
            let granted = try await scheduler.requestAuthorization()
            if granted {
                try await scheduler.rebuildSchedule(preferences: preferences)
            }
        case .authorized:
            try await scheduler.rebuildSchedule(preferences: preferences)
        case .denied:
            // Preserve the learner's toggle state without silently cancelling.
            break
        }
    }
}
