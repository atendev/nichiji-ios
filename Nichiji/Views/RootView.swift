import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/*----------------------------------root----------------------------------*/

public struct RootView: View {
    @AppStorage(
        LearnerPreferenceKey.hasCompletedOnboarding.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var hasCompletedOnboarding: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.serviceContainer) private var services
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasBackgrounded = false

    public init() {}

    public var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingCoordinator()
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .background(Color.nichijiSurface.ignoresSafeArea())
        .task { await refreshReminders() }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            guard completed else { return }
            Task { await refreshReminders() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Control Center only passes through .inactive, so wait for a real background trip.
            if phase == .background { wasBackgrounded = true }
            guard phase == .active, wasBackgrounded else { return }
            wasBackgrounded = false
            Task { await refreshReminders() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            Task { await refreshReminders() }
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            Task { await refreshReminders() }
        }
        #endif
    }

    /// Reruns rollover and rebuilds the reminder window on launch, foreground, onboarding completion and clock or zone changes. Waits for onboarding so a first run writes nothing early.
    private func refreshReminders() async {
        guard hasCompletedOnboarding, let services else { return }
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        try? await services.handleTimeOrZoneChange(preferences: LearnerPreferencesSnapshot.load(from: defaults))
    }
}
