import SwiftUI

/*----------------------------------root----------------------------------*/

public struct RootView: View {
    @AppStorage(
        LearnerPreferenceKey.hasCompletedOnboarding.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var hasCompletedOnboarding: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    }
}
