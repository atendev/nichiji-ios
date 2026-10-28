import Testing
import Foundation
@testable import Nichiji

/*------------------------------widget-tests------------------------------*/

@Suite("WidgetTimeline Tests")
struct WidgetTimelineTests {
    @Test("Widget snapshot creates cleanly with default values")
    func snapshotInitialization() {
        let snapshot = DailyKanjiWidgetSnapshot(
            calendarDay: "2026-10-28",
            kanjiID: "学",
            primaryMeaning: "study, learning",
            onyomiKana: ["ガク"],
            kunyomiKana: ["まな"],
            featuredWord: nil,
            isLearned: false
        )
        #expect(snapshot.kanjiID == "学")
        #expect(!snapshot.isLearned)
    }

    // TODO: Verify widget timeline provider queries DailyKanjiService for midnight rollover in Slice 11.
    // TODO: Verify interactive Got it AppIntent updates store and reloads widget timelines in Slice 11.
}
