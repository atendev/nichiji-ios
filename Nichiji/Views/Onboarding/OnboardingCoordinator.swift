import SwiftUI

/*-------------------------------coordinator------------------------------*/

public struct OnboardingCoordinator: View {
    @State private var currentStep: OnboardingStep = .welcome
    @AppStorage(LearnerPreferenceKey.hasCompletedOnboarding.rawValue, store: UserDefaults(suiteName: AppStorageGroup.suiteName))
    private var hasCompletedOnboarding: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            if currentStep != .welcome {
                OnboardingProgressBar(currentStep: currentStep)
                    .padding(.horizontal, LayoutTokens.space16)
                    .padding(.top, LayoutTokens.space8)
            }

            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView(onNext: { currentStep = .dailyKanji })
                case .dailyKanji:
                    DailyKanjiIntroView(onNext: { currentStep = .flashcards }, onBack: { currentStep = .welcome })
                case .flashcards:
                    FlashcardDemoView(onNext: { currentStep = .levelSelection }, onBack: { currentStep = .dailyKanji })
                case .levelSelection:
                    LevelSelectView(onNext: { currentStep = .reminder }, onBack: { currentStep = .flashcards })
                case .reminder:
                    ReminderSetupView(onNext: { currentStep = .widgetIntro }, onBack: { currentStep = .levelSelection })
                case .widgetIntro:
                    WidgetIntroView(onNext: { currentStep = .ready }, onBack: { currentStep = .reminder })
                case .ready:
                    ReadyView(onComplete: { hasCompletedOnboarding = true }, onBack: { currentStep = .widgetIntro })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
    }
}

/*------------------------------progress-bar------------------------------*/

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep

    var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            ForEach(1...6, id: \.self) { index in
                Rectangle()
                    .fill(index <= currentStep.rawValue ? Color.nichijiVermilion : Color.nichijiHairline)
                    .frame(height: 3)
                    .clipShape(Capsule())
            }
        }
        .frame(height: LayoutTokens.space8)
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Connect back-swipe gestures and step transitions with spring animations in Slice 9.
