import Foundation
import Testing
@testable import Nichiji

/*------------------------------known-stats-------------------------------*/

@Suite("Known Kanji Stats Tests")
struct KnownKanjiStatsTests {
    private let clock = StatsClock()

    private let index = [
        StatsFixtures.entry("日", jlpt: .n5, joyo: .grade1, listIndex: 0),
        StatsFixtures.entry("一", jlpt: .n5, joyo: .grade1, listIndex: 1),
        StatsFixtures.entry("会", jlpt: .n4, joyo: .grade2, listIndex: 2),
        StatsFixtures.entry("憂", jlpt: .n1, joyo: .secondary, listIndex: 3),
        StatsFixtures.entry("凜", jlpt: .n1, joyo: nil, listIndex: 4)
    ]

    private var progress: [KanjiProgressSnapshot] {
        let marked = clock.at("2026-11-02")
        return [
            StatsFixtures.progress("日", .learning, learnedAt: clock.at("2026-11-01")),
            StatsFixtures.declared("一", at: marked),
            StatsFixtures.progress("会", .known, learnedAt: clock.at("2026-10-30")),
            StatsFixtures.progress("憂", .learning, forgotItCount: 2),
            StatsFixtures.declared("凜", at: marked, forgotItCount: 3)
        ]
    }

    @Test("Declared kanji count as known and leave every Learned figure")
    func declaredLeaveLearned() {
        let stats = StatsCalculator.stats(
            log: [],
            progress: progress,
            index: index,
            preferences: .standard,
            dayProvider: clock.provider
        )

        #expect(stats.kanjiLearned == 3)
        #expect(stats.kanjiKnown == 2)
        #expect(Set(stats.learnedKanjiIDs) == ["日", "会", "憂"])
        #expect(stats.levelBars.map(\.learned) == [1, 1, 1])
        #expect(stats.needsAttention.map(\.kanjiID) == ["憂"])
    }

    @Test("The level-complete count leaves declared kanji out")
    func levelCompleteLeavesDeclared() {
        let figures = StatsCalculator.levelComplete(
            level: .jlpt(.n5),
            log: [],
            progress: progress,
            index: index,
            dayProvider: clock.provider
        )

        #expect(figures.kanjiLearned == 1)
    }

    @Test("Known needs a declared date, and a review clears it")
    func declaredFlag() {
        #expect(StatsFixtures.declared("日", at: Date()).declaredKnown)
        #expect(!StatsFixtures.progress("日", .known).declaredKnown)
        #expect(!KanjiProgressSnapshot(kanjiID: "日", stage: .learning).declaredKnown)
        #expect(StatsFixtures.progress("日", .known).isLearned)
        #expect(!StatsFixtures.progress("日", .new).isLearned)
    }
}
