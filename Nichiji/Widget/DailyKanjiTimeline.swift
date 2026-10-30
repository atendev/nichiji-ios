import Foundation
import WidgetKit

/*--------------------------------entry---------------------------------------*/

/// One widget entry. Content is resolved once and refreshed at the next local midnight.
struct DailyKanjiWidgetEntry: TimelineEntry, Equatable, Sendable {
    enum Content: Equatable, Sendable {
        /// Today's kanji, assigned or already learned.
        case today(DailyKanjiWidgetSnapshot)
        /// Every kanji in the level is learned, so there is nothing to show.
        case levelComplete
        /// Onboarding is unfinished or the shared store could not be read.
        case openApp
    }

    let date: Date
    let content: Content
}

extension DailyKanjiWidgetEntry {
    /// Static 学 sample used by widget placeholders and the onboarding preview.
    static let sample = DailyKanjiWidgetEntry(date: Date(timeIntervalSince1970: 0), content: .today(.sample))
}

extension DailyKanjiWidgetSnapshot {
    static let sample = DailyKanjiWidgetSnapshot(
        calendarDay: "1970-01-01",
        kanjiID: "学",
        primaryMeaning: "study, learning",
        onyomiKana: ["ガク"],
        kunyomiKana: ["まな.ぶ"],
        featuredWord: ExampleWord(id: "学生", word: "学生", kana: "がくせい", romaji: "gakusei", meaning: "student"),
        isLearned: false
    )
}

/*-------------------------------builder--------------------------------------*/

/// A single entry plus when WidgetKit should ask for the next one.
struct DailyKanjiTimelinePlan: Sendable {
    let entry: DailyKanjiWidgetEntry
    let reloadDate: Date

    func timeline() -> Timeline<DailyKanjiWidgetEntry> {
        Timeline(entries: [entry], policy: .after(reloadDate))
    }
}

/// Resolves today's widget content from `DailyKanjiService` and picks the next reload time.
struct DailyKanjiTimelineBuilder: Sendable {
    /// Retry delay after a read failure; shorter than a day so the widget heals on its own.
    static let retryInterval: TimeInterval = 15 * 60

    let dailyKanjiService: any DailyKanjiService
    let dayProvider: any DayProvider
    let preferencesProvider: @Sendable () -> LearnerPreferencesSnapshot

    func build() async -> DailyKanjiTimelinePlan {
        let now = dayProvider.now
        let midnight = dayProvider.nextMidnight(after: now)

        // Reading the snapshot would create today's assignment with default preferences, so wait for onboarding.
        guard preferencesProvider().hasCompletedOnboarding else {
            return DailyKanjiTimelinePlan(entry: DailyKanjiWidgetEntry(date: now, content: .openApp), reloadDate: midnight)
        }

        do {
            let day = dayProvider.calendarDay(for: now)
            let content: DailyKanjiWidgetEntry.Content
            if let snapshot = try await dailyKanjiService.widgetSnapshot(for: day) {
                content = .today(snapshot)
            } else {
                content = .levelComplete
            }
            return DailyKanjiTimelinePlan(entry: DailyKanjiWidgetEntry(date: now, content: content), reloadDate: midnight)
        } catch {
            let retry = min(now.addingTimeInterval(Self.retryInterval), midnight)
            return DailyKanjiTimelinePlan(entry: DailyKanjiWidgetEntry(date: now, content: .openApp), reloadDate: retry)
        }
    }
}
