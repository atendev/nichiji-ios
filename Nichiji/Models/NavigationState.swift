import Foundation

/*---------------------------------enums--------------------------------------*/

/// Top-level tab destinations in the main application shell.
public enum AppTab: String, Codable, CaseIterable, Sendable {
    case today
    case dictionary
    case review
    case you
}

/// App URLs the widgets pass through `widgetURL`. The containing app receives them in
/// `onOpenURL`, so the scheme needs no `CFBundleURLTypes` registration.
public enum AppDeepLink: Equatable, Sendable {
    case today

    public static let scheme = "nichiji"

    public var url: URL {
        switch self {
        case .today:
            return URL(string: "\(Self.scheme)://today")!
        }
    }

    /// The tab the app selects when it opens this link.
    public var tab: AppTab {
        switch self {
        case .today:
            return .today
        }
    }

    public init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              url.host()?.lowercased() == "today",
              url.path().isEmpty || url.path() == "/" else {
            return nil
        }
        self = .today
    }
}

/// Ordered steps in the seven-screen onboarding flow.
public enum OnboardingStep: Int, Codable, CaseIterable, Sendable {
    case welcome = 0
    case dailyKanji = 1
    case flashcards = 2
    case levelSelection = 3
    case reminder = 4
    case widgetIntro = 5
    case ready = 6
}

/// Push destinations inside the shared Settings bottom sheet.
public enum SettingsDestination: Hashable, Sendable {
    case level
    case customizeKanji
    case dailyReminder
    case review
    case widgets
    case privacy
}

/// Notification payload variant for the daily local reminder.
public enum ReminderNotificationKind: Equatable, Sendable {
    /// Specific next-day notification when today is learned: "<kanji> · Today's kanji is ready".
    case dailyReady(kanjiID: String, dueReviewCount: Int)
    /// Specific next-day notification when today is still assigned: "You missed yesterday's kanji. That's okay, check it now."
    case missedYesterday(dueReviewCount: Int)
    /// Generic fallback notification for days 2 through 7 of the rolling window: "Today's kanji is ready".
    case genericReady(dueReviewCount: Int)
}

/*--------------------------------structs-------------------------------------*/

/// Self-contained payload rendered by the small and medium home-screen widgets.
public struct DailyKanjiWidgetSnapshot: Codable, Equatable, Sendable {
    public let calendarDay: String
    public let kanjiID: String
    public let primaryMeaning: String
    public let onyomiKana: [String]
    public let kunyomiKana: [String]
    public let featuredWord: ExampleWord?
    public let isLearned: Bool

    public init(
        calendarDay: String,
        kanjiID: String,
        primaryMeaning: String,
        onyomiKana: [String],
        kunyomiKana: [String],
        featuredWord: ExampleWord?,
        isLearned: Bool
    ) {
        self.calendarDay = calendarDay
        self.kanjiID = kanjiID
        self.primaryMeaning = primaryMeaning
        self.onyomiKana = onyomiKana
        self.kunyomiKana = kunyomiKana
        self.featuredWord = featuredWord
        self.isLearned = isLearned
    }
}
