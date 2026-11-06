import Foundation
import Testing
@testable import Nichiji

/*------------------------------auto-known--------------------------------*/

@Suite("Auto Known Levels Tests")
struct AutoKnownLevelsTests {
    private let index = [
        StatsFixtures.entry("日", jlpt: .n5, joyo: .grade1),
        StatsFixtures.entry("会", jlpt: .n4, joyo: .grade2),
        StatsFixtures.entry("新", jlpt: .n3, joyo: .grade2),
        StatsFixtures.entry("昼", jlpt: .n4, joyo: .grade2),
        StatsFixtures.entry("曜", jlpt: .n4, joyo: .grade2),
        StatsFixtures.entry("税", jlpt: .n1, joyo: .grade5),
        StatsFixtures.entry("憂", jlpt: .n1, joyo: .secondary),
        StatsFixtures.entry("凜", jlpt: nil, joyo: nil)
    ]

    private func ids(_ preferences: LearnerPreferencesSnapshot) -> Set<String>? {
        AutoKnownLevels.kanjiIDs(in: index, preferences: preferences)
    }

    @Test("JLPT marks every level easier than the learner's and nothing unleveled")
    func jlpt() {
        #expect(ids(LearnerPreferencesSnapshot(levelSystem: .jlpt, selectedJLPTLevel: .n3)) == ["日", "会", "昼", "曜"])
        #expect(ids(LearnerPreferencesSnapshot(levelSystem: .jlpt, selectedJLPTLevel: .n5)) == [])
    }

    @Test("Jōyō marks the grades below the learner's, and Secondary marks grades 1 to 6")
    func joyo() {
        #expect(ids(LearnerPreferencesSnapshot(levelSystem: .joyo, selectedJoyoGrade: .grade3)) == ["日", "会", "新", "昼", "曜"])
        #expect(ids(LearnerPreferencesSnapshot(levelSystem: .joyo, selectedJoyoGrade: .secondary)) == ["日", "会", "新", "昼", "曜", "税"])
    }

    @Test("The custom pool has no level, so it leaves the marks alone")
    func customPool() {
        let custom = LearnerPreferencesSnapshot(levelSystem: .jlpt, selectedJLPTLevel: .n1, isCustomPoolActive: true)

        #expect(ids(custom) == nil)
        #expect(!AutoKnownLevels.hasEasierLevels(custom))
    }

    @Test("Only the easiest level has nothing below it")
    func easierLevels() {
        #expect(!AutoKnownLevels.hasEasierLevels(LearnerPreferencesSnapshot(levelSystem: .jlpt, selectedJLPTLevel: .n5)))
        #expect(AutoKnownLevels.hasEasierLevels(LearnerPreferencesSnapshot(levelSystem: .jlpt, selectedJLPTLevel: .n4)))
        #expect(!AutoKnownLevels.hasEasierLevels(LearnerPreferencesSnapshot(levelSystem: .joyo, selectedJoyoGrade: .grade1)))
        #expect(AutoKnownLevels.hasEasierLevels(LearnerPreferencesSnapshot(levelSystem: .joyo, selectedJoyoGrade: .secondary)))
    }
}
