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
}
