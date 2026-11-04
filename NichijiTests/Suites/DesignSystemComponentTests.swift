import SwiftUI
import Testing
@testable import Nichiji

@Suite("Design System Component Tests")
struct DesignSystemComponentTests {
    @Test("Components accept their public configuration")
    func componentsAcceptConfiguration() {
        _ = HeaderBar(kanjiTitle: "今日", englishTitle: "Today") {
            Image(systemName: "slider.horizontal.3")
        }
        _ = PrimaryButton(title: "Got it", isEnabled: false) {}
        _ = KanjiCard {
            Text("日")
        }
        _ = SealStamp(text: "Learned today")
        _ = HeaderCaption(text: "4 DAY STREAK")
    }

    @Test("Interactive components retain Apple HIG sizing constants")
    func componentsUseMinimumHitTarget() {
        #expect(LayoutTokens.minHitTarget >= 44)
        #expect(LayoutTokens.space16 >= 8)
        #expect(LayoutTokens.cornerRadiusMedium > 0)
    }

    @Test("Primary button action remains callable")
    @MainActor
    func primaryButtonAction() {
        var didRun = false
        let button = PrimaryButton(title: "Continue") {
            didRun = true
        }

        button.action()
        #expect(didRun)
    }

    @Test("Secondary button keeps its title and action")
    @MainActor
    func secondaryButtonAction() {
        var didRun = false
        let button = SecondaryButton(title: "Open Settings") {
            didRun = true
        }

        #expect(button.title == "Open Settings")
        button.action()
        #expect(didRun)
    }
}
