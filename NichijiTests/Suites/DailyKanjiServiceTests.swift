import Testing
import Foundation
@testable import Nichiji

/*-----------------------------rollover-tests-----------------------------*/

@Suite("DailyKanjiService Tests")
struct DailyKanjiServiceTests {
    @Test("DayProvider formats calendar days deterministically")
    func calendarDayFormatting() {
        let provider = TestDayProvider()
        let dayString = provider.calendarDay(for: provider.now)
        #expect(dayString.count == 10)
    }

    // TODO: Verify rollover marks past assigned rows as missed while keeping KanjiProgress stage at .new in Slice 4.
    // TODO: Verify daily assignment selection is idempotent when called repeatedly on the same day in Slice 4.
    // TODO: Verify exhausted unlearned pool returns nil to trigger the quiet level-complete state in Slice 4.
}
