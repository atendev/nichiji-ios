import Foundation

/*------------------------------progress--------------------------------------*/

extension StatsCalculator {
    /// Learned out of total per level group of the learner's level system, custom pool or not.
    static func levelBars(progress: [KanjiProgressSnapshot], index: [KanjiIndexEntry], system: LevelSystem) -> [LevelBar] {
        let learned = Set(progress.filter(\.isLearned).map(\.kanjiID))
        return levelGroups(index: index, system: system)
            .filter { !$0.ids.isEmpty }
            .map { group in
                LevelBar(id: group.id, title: group.title, learned: group.ids.filter(learned.contains).count, total: group.ids.count)
            }
    }

    /// Kanji milestones count kanji ever learned, so Forget it never takes one back.
    static func milestones(
        learnedEver: Set<String>,
        reviewsDone: Int,
        longestStreak: Int,
        index: [KanjiIndexEntry],
        system: LevelSystem
    ) -> [Milestone] {
        let level = LevelSequence.first(in: system)
        let levelIDs = index.filter(level.contains).map(\.id)
        let kanji = learnedEver.count
        return [
            Milestone(kind: .firstKanji, current: kanji, target: 1),
            Milestone(kind: .tenKanji, current: kanji, target: 10),
            Milestone(kind: .twentyFiveKanji, current: kanji, target: 25),
            Milestone(kind: .hundredReviews, current: reviewsDone, target: 100),
            Milestone(kind: .sevenDayStreak, current: longestStreak, target: 7),
            Milestone(kind: .thirtyDayStreak, current: longestStreak, target: 30),
            Milestone(kind: .finishLevel(level), current: levelIDs.filter(learnedEver.contains).count, target: levelIDs.count)
        ]
    }

    /// Up to three kanji past new with a Forgot it, most forgotten first.
    static func needsAttention(progress: [KanjiProgressSnapshot], log: [StudyLogRecord]) -> [NeedsAttentionItem] {
        let tally = AnswerTally(log: log)
        return progress
            .filter { $0.isLearned && $0.forgotItCount >= 1 }
            .sorted(by: tally.ranksBefore)
            .prefix(needsAttentionLimit)
            .map { NeedsAttentionItem(kanjiID: $0.kanjiID, forgotCount: $0.forgotItCount) }
    }

    static func learnedKanjiIDs(progress: [KanjiProgressSnapshot]) -> [String] {
        progress
            .filter(\.isLearned)
            .sorted { lhs, rhs in
                let left = lhs.firstLearnedAt ?? .distantPast
                let right = rhs.firstLearnedAt ?? .distantPast
                return left != right ? left > right : lhs.kanjiID < rhs.kanjiID
            }
            .map(\.kanjiID)
    }

    /*----------------------------level-complete------------------------------*/

    static func levelComplete(
        level: StudyLevel,
        log: [StudyLogRecord],
        progress: [KanjiProgressSnapshot],
        index: [KanjiIndexEntry],
        dayProvider: any DayProvider
    ) -> LevelCompleteFigures {
        let ids = Set(index.filter(level.contains).map(\.id))
        let levelLog = log.filter { ids.contains($0.kanjiID) }
        let learnedDays = levelLog.filter { $0.action == .learnedDaily }.map { $0.day(using: dayProvider) }
        return LevelCompleteFigures(
            kanjiLearned: progress.filter { $0.isLearned && ids.contains($0.kanjiID) }.count,
            daysTaken: inclusiveDays(from: learnedDays.min(), to: learnedDays.max(), dayProvider: dayProvider),
            gotItRate: gotItRate(in: levelLog)
        )
    }

    private static func inclusiveDays(from first: String?, to last: String?, dayProvider: any DayProvider) -> Int? {
        guard let first, let last,
              let start = date(forDay: first, dayProvider: dayProvider),
              let end = date(forDay: last, dayProvider: dayProvider)
        else { return nil }
        return (dayProvider.calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    /// Same groups as the Dictionary browse: N5 to N1, or Grades 1 to 6, Secondary and Name kanji.
    private static func levelGroups(index: [KanjiIndexEntry], system: LevelSystem) -> [(id: String, title: String, ids: [String])] {
        switch system {
        case .jlpt:
            return JLPTLevel.allCases.map { level in
                (id: level.rawValue, title: level.codeLabel, ids: index.filter { $0.jlptLevel == level }.map(\.id))
            }
        case .joyo:
            let grades = JoyoGrade.allCases.map { grade in
                (id: grade.rawValue, title: grade.displayName, ids: index.filter { $0.joyoGrade == grade }.map(\.id))
            }
            return grades + [(id: "name-kanji", title: "Name kanji", ids: index.filter { $0.joyoGrade == nil }.map(\.id))]
        }
    }
}

/*--------------------------------tally---------------------------------------*/

/// Per-kanji review answers from the log, for the Needs attention tie-breaks.
private struct AnswerTally {
    private var got: [String: Int] = [:]
    private var forgot: [String: Int] = [:]
    private var lastForgot: [String: Date] = [:]

    init(log: [StudyLogRecord]) {
        for record in log {
            switch record.action {
            case .gotItReview:
                got[record.kanjiID, default: 0] += 1
            case .forgotItReview:
                forgot[record.kanjiID, default: 0] += 1
                lastForgot[record.kanjiID] = max(lastForgot[record.kanjiID] ?? .distantPast, record.timestamp)
            case .learnedDaily, .resetToNew:
                break
            }
        }
    }

    /// Got it share from the log, or 0 when the kanji has no review answers.
    func ratio(_ kanjiID: String) -> Double {
        let gotCount = got[kanjiID] ?? 0
        let total = gotCount + (forgot[kanjiID] ?? 0)
        return total == 0 ? 0 : Double(gotCount) / Double(total)
    }

    /// More forgets, then a lower ratio, then a more recent Forgot it (none sorts last), then kanji order.
    func ranksBefore(_ lhs: KanjiProgressSnapshot, _ rhs: KanjiProgressSnapshot) -> Bool {
        if lhs.forgotItCount != rhs.forgotItCount {
            return lhs.forgotItCount > rhs.forgotItCount
        }
        let leftRatio = ratio(lhs.kanjiID)
        let rightRatio = ratio(rhs.kanjiID)
        if leftRatio != rightRatio {
            return leftRatio < rightRatio
        }
        let leftDate = lastForgot[lhs.kanjiID] ?? .distantPast
        let rightDate = lastForgot[rhs.kanjiID] ?? .distantPast
        if leftDate != rightDate {
            return leftDate > rightDate
        }
        return lhs.kanjiID < rhs.kanjiID
    }
}
