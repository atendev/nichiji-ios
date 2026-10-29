import SwiftUI

/*-------------------------------coordinator------------------------------*/

public struct OnboardingCoordinator: View {
    @Environment(\.serviceContainer) private var services
    @State private var flow: OnboardingFlow?

    public init() {}

    public var body: some View {
        Group {
            if let flow {
                OnboardingStepHost(flow: flow)
            } else {
                Color.clear
                    .onAppear { flow = makeFlow() }
            }
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
    }

    private func makeFlow() -> OnboardingFlow {
        let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
        if let services {
            return OnboardingFlow(services: services, defaults: defaults)
        }
        return OnboardingFlow(
            defaults: defaults,
            contentStore: BundledKanjiContentStore(),
            reminderScheduler: NoopReminderScheduler(),
            dayProvider: SystemDayProvider(),
            learnerStore: nil,
            dailyKanjiService: nil
        )
    }
}

/*--------------------------------step-host-------------------------------*/

private struct OnboardingStepHost: View {
    let flow: OnboardingFlow

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        switch flow.direction {
        case .forward:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .backward:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if flow.showsProgress {
                HStack(spacing: LayoutTokens.space8) {
                    Button {
                        flow.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.nichijiInk)
                    }
                    .buttonStyle(.plain)
                    .minTouchTarget()
                    .accessibilityLabel("Back")

                    OnboardingProgressBar(filledSegments: flow.progressFill)
                }
                .padding(.leading, LayoutTokens.space8)
                .padding(.trailing, LayoutTokens.screenMarginCompact)
                .padding(.top, LayoutTokens.space8)
                .transition(.opacity)
            }

            ZStack {
                stepView
                    .id(flow.step)
                    .transition(stepTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .animation(
            reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.35),
            value: flow.step
        )
    }

    @ViewBuilder
    private var stepView: some View {
        switch flow.step {
        case .welcome:
            WelcomeView(onNext: { flow.advance() })
        case .dailyKanji:
            DailyKanjiIntroView(onNext: { flow.advance() })
        case .flashcards:
            FlashcardDemoView(onNext: { flow.advance() })
        case .levelSelection:
            LevelSelectView(flow: flow)
        case .reminder:
            ReminderSetupView(flow: flow)
        case .widgetIntro:
            WidgetIntroView(onNext: { flow.advance() })
        case .ready:
            ReadyView(
                isCompleting: flow.isCompleting,
                onComplete: { Task { await flow.complete() } }
            )
        }
    }
}

/*------------------------------progress-bar------------------------------*/

struct OnboardingProgressBar: View {
    let filledSegments: Int

    var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            ForEach(1...OnboardingFlow.progressSegmentCount, id: \.self) { index in
                Capsule()
                    .fill(index <= filledSegments ? Color.nichijiVermilion : Color.nichijiHairline)
                    .frame(height: 3)
            }
        }
        .frame(height: LayoutTokens.minHitTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(filledSegments) of \(OnboardingFlow.progressSegmentCount)")
    }
}
