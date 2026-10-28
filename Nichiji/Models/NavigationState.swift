import Foundation

/*---------------------------------enums--------------------------------------*/

/// Top-level tab destinations in the main application shell.
enum AppTab: String, Codable, CaseIterable, Sendable {
    case today
    case dictionary
    case review
    case you
}

/// Ordered steps in the seven-screen onboarding flow.
enum OnboardingStep: Int, Codable, CaseIterable, Sendable {
    case welcome = 0
    case dailyKanji = 1
    case flashcards = 2
    case levelSelection = 3
    case reminder = 4
    case widgetIntro = 5
    case ready = 6
}

/// Push destinations inside the shared Settings bottom sheet.
enum SettingsDestination: Hashable, Sendable {
    case level
    case customizeKanji
    case dailyReminder
    case review
    case widgets
    case privacy
}

/// Notification payload variant for the daily local reminder.
enum ReminderNotificationKind: Equatable, Sendable {
    /// Specific next-day notification when today is learned: "<kanji> · Today's kanji is ready".
    case dailyReady(kanjiID: String, dueReviewCount: Int)
    /// Specific next-day notification when today is still assigned: "You missed yesterday's kanji. That's okay, check it now."
    case missedYesterday(dueReviewCount: Int)
    /// Generic fallback notification for days 2 through 7 of the rolling window: "Today's kanji is ready".
    case genericReady(dueReviewCount: Int)
}

/*--------------------------------structs-------------------------------------*/

/// Self-contained payload rendered by the small and medium home-screen widgets.
struct DailyKanjiWidgetSnapshot: Codable, Equatable, Sendable {
    let calendarDay: String
    let kanjiID: String
    let primaryMeaning: String
    let onyomiKana: [String]
    let kunyomiKana: [String]
    let featuredWord: ExampleWord?
    let isLearned: Bool
}
