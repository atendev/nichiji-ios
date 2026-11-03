import Foundation
import Testing
@testable import Nichiji

/*-----------------------------progress-tests-----------------------------*/

@Suite("Stats Progress Tests")
struct StatsProgressTests {
    private let clock = StatsClock()

    private let index = [
        StatsFixtures.entry("日", jlpt: .n5, joyo: .grade1, listIndex: 0),
        StatsFixtures.entry("一", jlpt: .n5, joyo: .grade1, listIndex: 1),
        StatsFixtures.entry("会", jlpt: .n4, joyo: .grade2, listIndex: 2),
        StatsFixtures.entry("憂", jlpt: .n1, joyo: .secondary, listIndex: 3),
        StatsFixtures.entry("凜", jlpt: .n1, joyo: nil, listIndex: 4)
    ]

    /*------------------------------by-level--------------------------------*/

    @Test("JLPT bars show learned out of each level's total")
    func jlptBars() {
        let progress = [StatsFixtures.progress("日", .learning), StatsFixtures.progress("一", .new), StatsFixtures.progress("凜", .known)]
        let bars = StatsCalculator.levelBars(progress: progress, index: index, system: .jlpt)
        #expect(bars.map(\.id) == ["n5", "n4", "n1"])
        #expect(bars.map(\.learned) == [1, 0, 1])
        #expect(bars.map(\.total) == [2, 1, 2])
    }

    @Test("Jōyō bars follow the browse groups, Name kanji last, even with a custom pool")
    func joyoBars() {
        let progress = [StatsFixtures.progress("凜", .familiar)]
        let preferences = LearnerPreferencesSnapshot(levelSystem: .joyo, isCustomPoolActive: true)
        let bars = StatsCalculator.stats(log: [], progress: progress, index: index, preferences: preferences, dayProvider: clock.provider).levelBars
        #expect(bars.map(\.title) == ["1st grade", "2nd grade", "Secondary school", "Name kanji"])
        #expect(bars.map(\.learned) == [0, 0, 0, 1])
        #expect(bars.map(\.total) == [2, 1, 1, 1])
    }

    /*-----------------------------milestones-------------------------------*/

    @Test("Every milestone stays earned after Forget it and a broken streak")
    func milestonesAreSticky() {
        let kanji = (0..<25).map { "k\($0)" }
        let learnDays = (1...30).map { String(format: "2026-09-%02d", $0) }
        var log = kanji.enumerated().map { clock.record($0.element, .learnedDaily, learnDays[$0.offset]) }
        log += learnDays.map { clock.record("k0", .gotItReview, $0) }
        log += (0..<70).map { _ in clock.record("k1", .forgotItReview, "2026-09-30") }
        let levelIndex = kanji.prefix(2).map { StatsFixtures.entry($0, jlpt: .n5, joyo: .grade1) }
        let reset = kanji.map { StatsFixtures.progress($0, .new) }

        let stats = StatsCalculator.stats(log: log, progress: reset, index: levelIndex, preferences: .standard, dayProvider: clock.provider)
        #expect(stats.streak.current == 0)
        #expect(stats.kanjiLearned == 0)
        #expect(stats.milestones.map(\.kind) == [
            .firstKanji, .tenKanji, .twentyFiveKanji, .hundredReviews, .sevenDayStreak, .thirtyDayStreak, .finishLevel(.jlpt(.n5))
        ])
        #expect(stats.milestones.allSatisfy { $0.isEarned })
    }

    @Test("Locked milestones report progress toward their target")
    func milestoneProgress() {
        let log = [clock.record("日", .learnedDaily, "2026-11-03"), clock.record("日", .gotItReview, "2026-11-04")]
        let stats = StatsCalculator.stats(log: log, progress: [], index: index, preferences: .standard, dayProvider: clock.provider)
        #expect(stats.milestones.map(\.current) == [1, 1, 1, 1, 2, 2, 1])
        #expect(stats.milestones.map(\.target) == [1, 10, 25, 100, 7, 30, 2])
        #expect(stats.milestones.map(\.isEarned) == [true, false, false, false, false, false, false])
        #expect(stats.milestones[6].progress == 0.5)
    }

    @Test("The level milestone follows the level system, custom pool or not")
    func levelMilestoneLabel() {
        let joyo = LearnerPreferencesSnapshot(levelSystem: .joyo, isCustomPoolActive: true)
        let stats = StatsCalculator.stats(log: [], progress: [], index: index, preferences: joyo, dayProvider: clock.provider)
        #expect(stats.milestones[6].kind == .finishLevel(.joyo(.grade1)))
        #expect(stats.milestones[6].target == 2)
        #expect(StudyLevel.joyo(.grade1).finishLabel == "Finish Grade 1")
        #expect(StudyLevel.jlpt(.n5).finishLabel == "Finish N5")
    }

    /*---------------------------needs-attention----------------------------*/

    private func attention(_ progress: [KanjiProgressSnapshot], _ log: [StudyLogRecord] = []) -> [String] {
        StatsCalculator.needsAttention(progress: progress, log: log).map(\.kanjiID)
    }

    @Test("Needs attention ranks by forgets, caps at three and skips new or never forgotten kanji")
    func needsAttentionRanking() {
        let progress = [
            StatsFixtures.progress("a", .learning, forgotItCount: 3),
            StatsFixtures.progress("b", .learning, forgotItCount: 1),
            StatsFixtures.progress("c", .familiar, forgotItCount: 2),
            StatsFixtures.progress("d", .learning, forgotItCount: 1),
            StatsFixtures.progress("e", .new, forgotItCount: 9),
            StatsFixtures.progress("f", .known, forgotItCount: 0)
        ]
        #expect(attention(progress) == ["a", "c", "b"])
        #expect(StatsCalculator.needsAttention(progress: progress, log: []).first?.forgotCount == 3)
        #expect(attention([]).isEmpty)
    }

    @Test("Ties go to the lower got-it ratio from the log, not the progress count")
    func needsAttentionRatio() {
        let progress = [
            StatsFixtures.progress("x", .learning, gotItCount: 1, forgotItCount: 2),
            StatsFixtures.progress("y", .learning, gotItCount: 9, forgotItCount: 2)
        ]
        let log = Array(repeating: clock.record("x", .gotItReview, "2026-11-01"), count: 3)
            + Array(repeating: clock.record("x", .forgotItReview, "2026-11-01"), count: 2)
            + [clock.record("y", .gotItReview, "2026-11-01")]
            + Array(repeating: clock.record("y", .forgotItReview, "2026-11-01"), count: 2)
        #expect(attention(progress, log) == ["y", "x"])

        let unreviewed = [StatsFixtures.progress("w", .learning, forgotItCount: 1), StatsFixtures.progress("z", .learning, forgotItCount: 1)]
        let wLog = [clock.record("w", .gotItReview, "2026-11-01"), clock.record("w", .forgotItReview, "2026-11-01")]
        #expect(attention(unreviewed, wLog) == ["z", "w"])
    }

    @Test("Then the most recent Forgot it, with no Forgot it row sorting last")
    func needsAttentionRecency() {
        let progress = ["p", "q", "r", "s"].map { StatsFixtures.progress($0, .learning, forgotItCount: 1) }
        let log = [
            clock.record("p", .forgotItReview, "2026-11-01"),
            clock.record("q", .forgotItReview, "2026-11-03"),
            clock.record("r", .forgotItReview, "2026-10-01")
        ]
        #expect(attention(progress, log) == ["q", "p", "r"])
        #expect(attention([progress[3], progress[2]], log) == ["r", "s"])
    }

    @Test("The learned list is newest first and skips new kanji")
    func learnedList() {
        let progress = [
            StatsFixtures.progress("a", .learning, learnedAt: clock.at("2026-11-01")),
            StatsFixtures.progress("b", .known, learnedAt: clock.at("2026-11-03")),
            StatsFixtures.progress("c", .new, learnedAt: clock.at("2026-11-04"))
        ]
        #expect(StatsCalculator.learnedKanjiIDs(progress: progress) == ["b", "a"])
    }

    /*----------------------------level-complete----------------------------*/

    @Test("Level-complete figures cover only the level's kanji")
    func levelComplete() {
        let log = [
            clock.record("日", .learnedDaily, "2026-10-30"),
            clock.record("一", .learnedDaily, "2026-11-02"),
            clock.record("日", .gotItReview, "2026-11-03"),
            clock.record("一", .forgotItReview, "2026-11-03"),
            clock.record("会", .gotItReview, "2026-11-03"),
            clock.record("会", .gotItReview, "2026-11-03")
        ]
        let progress = [StatsFixtures.progress("日", .learning), StatsFixtures.progress("一", .learning), StatsFixtures.progress("会", .known)]
        let figures = StatsCalculator.levelComplete(level: .jlpt(.n5), log: log, progress: progress, index: index, dayProvider: clock.provider)
        #expect(figures == LevelCompleteFigures(kanjiLearned: 2, daysTaken: 4, gotItRate: 50))
    }

    @Test("Days taken is 1 for a one-day level and nil with nothing learned")
    func levelCompleteEdges() {
        let sameDay = [clock.record("日", .learnedDaily, "2026-11-02"), clock.record("一", .learnedDaily, "2026-11-02")]
        let oneDay = StatsCalculator.levelComplete(level: .jlpt(.n5), log: sameDay, progress: [], index: index, dayProvider: clock.provider)
        #expect(oneDay.daysTaken == 1)
        #expect(oneDay.gotItRate == nil)
        let none = StatsCalculator.levelComplete(level: .jlpt(.n4), log: sameDay, progress: [], index: index, dayProvider: clock.provider)
        #expect(none == LevelCompleteFigures(kanjiLearned: 0, daysTaken: nil, gotItRate: nil))
    }

    /*----------------------------level-sequence----------------------------*/

    @Test("The next level stops after N1 and Secondary, and a custom pool has none")
    func levelSequence() {
        #expect(LevelSequence.next(after: .jlpt(.n5)) == .jlpt(.n4))
        #expect(LevelSequence.next(after: .jlpt(.n1)) == nil)
        #expect(LevelSequence.next(after: .joyo(.grade6)) == .joyo(.secondary))
        #expect(LevelSequence.next(after: .joyo(.secondary)) == nil)
        #expect(LevelSequence.next(after: nil) == nil)
        #expect(LevelSequence.current(preferences: .standard) == .jlpt(.n5))
        #expect(LevelSequence.current(preferences: LearnerPreferencesSnapshot(levelSystem: .joyo)) == .joyo(.grade1))
        #expect(LevelSequence.current(preferences: LearnerPreferencesSnapshot(isCustomPoolActive: true)) == nil)
    }
}
