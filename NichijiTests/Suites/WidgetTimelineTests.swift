import Testing
import Foundation
@testable import Nichiji

/*------------------------------widget-tests------------------------------*/

@Suite("WidgetTimeline Tests")
struct WidgetTimelineTests {
    @Test("Widget snapshot creates cleanly with default values")
    func snapshotInitialization() {
        let snapshot = DailyKanjiWidgetSnapshot(
            kanjiID: "学",
            primaryMeaning: "study, learning",
            primaryReading: "ガク",
            featuredWord: "学校 (がっこう)",
            isLearned: false,
            dayString: "2026-10-28",
            calendarDay: "2026-10-28"
        )
        #expect(snapshot.kanjiID == "学")
        #expect(!snapshot.isLearned)
    }

    // TODO: Verify widget timeline provider queries DailyKanjiService for midnight rollover in Slice 11.
    // TODO: Verify interactive Got it AppIntent updates store and reloads widget timelines in Slice 11.
}
