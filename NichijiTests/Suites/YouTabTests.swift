import Foundation
import Testing
@testable import Nichiji

/*-------------------------------you-tests--------------------------------*/

@Suite("You Tab Tests")
struct YouTabTests {
    private let clock = StatsClock()

    private func stats(
        current: Int = 4,
        longest: Int = 12,
        freeze: StreakFreezeState? = nil,
        gotItRate: Int? = 86,
        activity: [[ActivityCell]] = []
    ) -> LearnerStats {
        LearnerStats(
            streak: StreakSummary(current: current, longest: longest, freeze: freeze),
            streakFreeze: freeze,
            kanjiLearned: 16,
            reviewsDone: 312,
            gotItRate: gotItRate,
            daysStudied: 30,
            learningSince: YearMonth(year: 2026, month: 9),
            activity: activity,
            levelBars: [],
            milestones: [],
            needsAttention: [],
            learnedKanjiIDs: []
        )
    }

    /*------------------------------header--------------------------------*/

    @Test("Learning since reads the month in caps and hides with no entries")
    func learningSince() {
        #expect(YouCopy.learningSince(YearMonth(year: 2026, month: 9)) == "LEARNING SINCE SEP 2026")
        #expect(YouCopy.learningSince(YearMonth(year: 2027, month: 1)) == "LEARNING SINCE JAN 2027")
        #expect(YouCopy.learningSince(nil) == nil)
    }

    @Test("The Review subtitle shows the day streak and hides at zero")
    func streakSubtitle() {
        #expect(YouCopy.streakSubtitle(4) == "4 DAY STREAK")
        #expect(YouCopy.streakSubtitle(1) == "1 DAY STREAK")
        #expect(YouCopy.streakSubtitle(0) == nil)
    }

    /*-------------------------------tiles--------------------------------*/

    @Test("Six tiles in order, Days studied last")
    func tiles() {
        let tiles = YouCopy.tiles(stats())
        #expect(tiles.map(\.label) == ["Day streak", "Longest streak", "Kanji learned", "Reviews done", "Got it rate", "Days studied"])
        #expect(tiles.map(\.value) == ["4", "12", "16", "312", "86%", "30"])
    }

    @Test("Got it rate shows a dash before the first answer")
    func rateDash() {
        #expect(YouCopy.tiles(stats(gotItRate: nil))[4].value == "–")
        #expect(YouCopy.rate(0) == "0%")
    }

    @Test("Freeze row copy per state, and no row with the setting off")
    func freezeRow() {
        #expect(YouCopy.freezeRow(.ready)?.title == "Streak freeze ready")
        #expect(YouCopy.freezeRow(.ready)?.isReady == true)
        #expect(YouCopy.freezeRow(.usedThisWeek)?.title == "Streak freeze used this week")
        #expect(YouCopy.freezeRow(.usedThisWeek)?.isReady == false)
        #expect(YouCopy.freezeRow(nil) == nil)
    }

    /*------------------------------activity------------------------------*/

    @Test("Activity summary counts studied days over days up to today")
    func activitySummary() {
        let week = [
            ActivityCell(calendarDay: "2026-11-02", count: 3, shade: 2),
            ActivityCell(calendarDay: "2026-11-03", count: 0, shade: 0),
            ActivityCell(calendarDay: "2026-11-04", count: 1, shade: 1),
            ActivityCell(calendarDay: "2026-11-05", count: 0, shade: nil)
        ]
        #expect(YouCopy.activitySummary([week]) == "Study activity for the last 12 weeks. Studied on 2 of 3 days.")
    }

    @Test("The calculator's mid-week grid leaves future days out of the summary")
    func activitySummaryFromCalculator() {
        let log = clock.studied(["2026-11-02", "2026-11-04"])
        let grid = StatsCalculator.activityGrid(log: log, dayProvider: clock.provider)
        // Wednesday with Monday-first weeks: 11 full weeks plus Monday to Wednesday.
        #expect(YouCopy.activitySummary(grid) == "Study activity for the last 12 weeks. Studied on 2 of 80 days.")
    }

    /*------------------------------by-level------------------------------*/

    @Test("JLPT bars map to code and name")
    func jlptRows() {
        let row = YouCopy.levelRow(LevelBar(id: "n5", title: "N5", learned: 14, total: 103))
        #expect(row.code == "N5")
        #expect(row.name == "Beginner")
        #expect(row.count == "14 of 103")
    }

    @Test("Jōyō bars map to grade codes, and Name kanji has no code")
    func joyoRows() {
        let grade = YouCopy.levelRow(LevelBar(id: "grade1", title: "1st grade", learned: 0, total: 80))
        #expect(grade.code == "1")
        #expect(grade.name == "1st grade")
        let secondary = YouCopy.levelRow(LevelBar(id: JoyoGrade.secondary.rawValue, title: "Secondary school", learned: 0, total: 1))
        #expect(secondary.code == "S")
        #expect(secondary.name == "Secondary school")
        let names = YouCopy.levelRow(LevelBar(id: "name-kanji", title: "Name kanji", learned: 1, total: 247))
        #expect(names.code == nil)
        #expect(names.name == "Name kanji")
    }

    @Test("Bar fill shows a sliver for any progress and caps at full")
    func barFraction() {
        #expect(YouCopy.barFraction(learned: 0, total: 103) == 0)
        #expect(YouCopy.barFraction(learned: 1, total: 1232) == 0.02)
        #expect(YouCopy.barFraction(learned: 51, total: 102) == 0.5)
        #expect(YouCopy.barFraction(learned: 5, total: 4) == 1)
    }

    /*-----------------------------milestones-----------------------------*/

    @Test("Milestone titles for every kind and both level systems")
    func milestoneTitles() {
        let kinds: [MilestoneKind] = [.firstKanji, .tenKanji, .twentyFiveKanji, .hundredReviews, .sevenDayStreak, .thirtyDayStreak]
        #expect(kinds.map(YouCopy.milestoneTitle) == [
            "First kanji", "10 kanji learned", "25 kanji learned", "100 reviews", "7-day streak", "30-day streak"
        ])
        #expect(YouCopy.milestoneTitle(.finishLevel(.jlpt(.n5))) == "Finish N5")
        #expect(YouCopy.milestoneTitle(.finishLevel(.joyo(.grade1))) == "Finish Grade 1")
    }

    @Test("A Custom Jōyō pool's level milestone reads Finish Grade 1")
    func customJoyoMilestone() {
        let index = [StatsFixtures.entry("日", jlpt: .n5, joyo: .grade1)]
        let preferences = LearnerPreferencesSnapshot(levelSystem: .joyo, isCustomPoolActive: true)
        let result = StatsCalculator.stats(log: [], progress: [], index: index, preferences: preferences, dayProvider: clock.provider)
        #expect(result.milestones.last.map { YouCopy.milestoneTitle($0.kind) } == "Finish Grade 1")
    }

    @Test("Earned and locked milestone rows, and the earned count")
    func milestoneRows() {
        let earned = Milestone(kind: .tenKanji, current: 16, target: 10)
        let locked = Milestone(kind: .twentyFiveKanji, current: 16, target: 25)
        #expect(YouCopy.milestoneRow(earned) == MilestoneRow(title: "10 kanji learned", note: "Earned", isEarned: true, progress: 1))
        #expect(YouCopy.milestoneRow(locked) == MilestoneRow(title: "25 kanji learned", note: "16 / 25", isEarned: false, progress: 0.64))
        #expect(YouCopy.milestoneCount([earned, locked]) == "1 of 2")
    }

    /*--------------------------needs-attention---------------------------*/

    @Test("Forgot notes and the empty message")
    func needsAttention() {
        #expect(YouCopy.forgotNote(1) == "Forgot 1 time")
        #expect(YouCopy.forgotNote(3) == "Forgot 3 times")
        #expect(YouCopy.needsAttentionMessage([]) == YouCopy.needsAttentionEmpty)
        #expect(YouCopy.needsAttentionMessage([NeedsAttentionItem(kanjiID: "水", forgotCount: 3)]) == nil)
    }

    /*-----------------------------your-kanji-----------------------------*/

    @Test("Learned and History show their empty messages only when empty")
    func emptyStates() {
        #expect(YouCopy.learnedMessage([]) == YouCopy.learnedEmpty)
        #expect(YouCopy.learnedMessage(["学"]) == nil)
        #expect(YouCopy.historyMessage([]) == YouCopy.historyEmpty)
        let day = HistoryDay(calendarDay: "2026-11-04", heading: "TODAY", entries: [clock.record("学", .learnedDaily, "2026-11-04")])
        #expect(YouCopy.historyMessage([day]) == nil)
        #expect(YouCopy.learnedCount(16) == "16 learned")
    }

    @Test("History rows name every action")
    func historyActions() {
        #expect(StudyAction.allCases.map(YouCopy.historyAction) == ["Learned", "Reviewed, got it", "Reviewed, forgot", "Reset to new"])
    }

    @Test("History times read in the provider's zone with lowercase am and pm")
    func historyTimes() {
        let calendar = clock.provider.calendar
        #expect(YouCopy.historyTime(clock.at("2026-11-04", hour: 8, minute: 2), calendar: calendar) == "8:02 am")
        #expect(YouCopy.historyTime(clock.at("2026-11-04", hour: 0, minute: 5), calendar: calendar) == "12:05 am")
        #expect(YouCopy.historyTime(clock.at("2026-11-04", hour: 12, minute: 0), calendar: calendar) == "12:00 pm")
        #expect(YouCopy.historyTime(clock.at("2026-11-04", hour: 21, minute: 30), calendar: calendar) == "9:30 pm")
    }

    @Test("Locked export opens the paywall; unlocked export shares once the file is ready")
    func exportAction() {
        let url = URL(fileURLWithPath: "/tmp/nichiji-history-2026-11-04.csv")
        #expect(YouCopy.exportAction(logIsEmpty: false, fileURL: url, access: .purchased) == .share(url))
        #expect(YouCopy.exportAction(logIsEmpty: true, fileURL: url, access: .purchased) == .unavailable)
        #expect(YouCopy.exportAction(logIsEmpty: false, fileURL: nil, access: .purchased) == .unavailable)
        #expect(YouCopy.exportAction(logIsEmpty: false, fileURL: url, access: .locked) == .paywall)
        #expect(YouCopy.exportAction(logIsEmpty: true, fileURL: nil, access: .locked) == .paywall)
        #expect(YouCopy.exportAction(logIsEmpty: false, fileURL: url, access: ProAccess(isDevUnlocked: true)) == .share(url))
    }

    /*---------------------------level-complete---------------------------*/

    @Test("Study level titles, and finish labels built on them")
    func levelTitles() {
        #expect(StudyLevel.jlpt(.n5).title == "N5")
        #expect(StudyLevel.joyo(.grade1).title == "Grade 1")
        #expect(StudyLevel.joyo(.secondary).title == "Secondary")
        #expect(StudyLevel.joyo(.secondary).finishLabel == "Finish Secondary")
    }

    @Test("Level-complete title, figures and next-level button")
    func levelCompleteSummary() {
        let summary = LevelCompleteSummary(level: .jlpt(.n5), figures: LevelCompleteFigures(kanjiLearned: 103, daysTaken: 120, gotItRate: 91))
        #expect(summary.title == "N5 complete")
        #expect(summary.figures == [
            StatTile(value: "103", label: "Kanji learned"),
            StatTile(value: "120", label: "Days taken"),
            StatTile(value: "91%", label: "Got it rate")
        ])
        #expect(summary.startTitle == "Start N4")
        #expect(LevelCompleteSummary(level: .joyo(.grade6), figures: LevelCompleteFigures(kanjiLearned: 1, daysTaken: 1, gotItRate: nil)).startTitle == "Start Secondary")
    }

    @Test("Missing figures read as dashes, and the last level has no next")
    func levelCompleteLastLevel() {
        let summary = LevelCompleteSummary(level: .jlpt(.n1), figures: LevelCompleteFigures(kanjiLearned: 0, daysTaken: nil, gotItRate: nil))
        #expect(summary.figures.map(\.value) == ["0", "–", "–"])
        #expect(summary.nextLevel == nil)
        #expect(summary.startTitle == nil)
        #expect(LevelCompleteSummary(level: .joyo(.secondary), figures: LevelCompleteFigures(kanjiLearned: 0, daysTaken: nil, gotItRate: nil)).startTitle == nil)
    }

    @Test("Custom pools have no level, so no figures or switcher")
    func levelCompleteCustom() {
        #expect(LevelSequence.current(preferences: LearnerPreferencesSnapshot(isCustomPoolActive: true)) == nil)
    }

    @Test("Starting the next level sets it, turns the custom pool off and keeps the rest")
    func startNextLevel() {
        let current = LearnerPreferencesSnapshot(streakFreezeEnabled: true, levelSystem: .jlpt, selectedJLPTLevel: .n5, isCustomPoolActive: true)
        let jlpt = LevelSequence.preferences(starting: .jlpt(.n4), from: current)
        #expect(jlpt.selectedJLPTLevel == .n4)
        #expect(jlpt.levelSystem == .jlpt)
        #expect(!jlpt.isCustomPoolActive)
        #expect(jlpt.streakFreezeEnabled)

        let joyo = LevelSequence.preferences(starting: .joyo(.grade2), from: LearnerPreferencesSnapshot(levelSystem: .joyo))
        #expect(joyo.selectedJoyoGrade == .grade2)
        #expect(joyo.levelSystem == .joyo)
        #expect(joyo.selectedJLPTLevel == .n5)
    }
}
