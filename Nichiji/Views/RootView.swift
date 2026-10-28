import SwiftUI

/*----------------------------------root----------------------------------*/

public struct RootView: View {
    @AppStorage(
        LearnerPreferenceKey.hasCompletedOnboarding.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var hasCompletedOnboarding: Bool = false

    public init() {}

    public var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingCoordinator()
            }
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Handle onboarding completion transition with a smooth cross-fade animation in Slice 9.
