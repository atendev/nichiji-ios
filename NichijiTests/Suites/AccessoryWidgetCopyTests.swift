import Testing
import Foundation
@testable import Nichiji

/*-----------------------------accessory-copy---------------------------*/

@Suite("AccessoryWidgetCopy Tests")
struct AccessoryWidgetCopyTests {
    @Test("Inline copy covers every state")
    func inlineCopy() {
        let learned = DailyKanjiWidgetSnapshot(
            calendarDay: "1970-01-01",
            kanjiID: "学",
            primaryMeaning: "study, learning",
            onyomiKana: [],
            kunyomiKana: [],
            featuredWord: nil,
            isLearned: true
        )

        #expect(AccessoryWidgetCopy.inline(for: .today(.sample)) == "学 study, learning")
        #expect(AccessoryWidgetCopy.inline(for: .today(learned)) == "学 learned")
        #expect(AccessoryWidgetCopy.inline(for: .levelComplete) == "Level complete")
        #expect(AccessoryWidgetCopy.inline(for: .openApp) == "Nichiji")
    }

    @Test("The featured word line joins word and kana, and is absent without an example")
    func featuredWordLine() {
        let bare = DailyKanjiWidgetSnapshot(
            calendarDay: "1970-01-01",
            kanjiID: "学",
            primaryMeaning: "study, learning",
            onyomiKana: [],
            kunyomiKana: [],
            featuredWord: nil,
            isLearned: false
        )

        #expect(AccessoryWidgetCopy.featuredWordLine(for: .sample) == "学生 がくせい")
        #expect(AccessoryWidgetCopy.featuredWordLine(for: bare) == nil)
    }

    @Test("Accessory accessibility labels name the state")
    func accessibilityLabels() {
        #expect(AccessoryWidgetCopy.accessibilityLabel(for: .today(.sample)) == "学, study, learning.")
        #expect(AccessoryWidgetCopy.accessibilityLabel(for: .levelComplete) == "Level complete. Every kanji learned.")
        #expect(AccessoryWidgetCopy.accessibilityLabel(for: .openApp) == "Open Nichiji to start learning")
        #expect(AddWidgetCopy.lockScreenSteps.count == 3)
    }
}
