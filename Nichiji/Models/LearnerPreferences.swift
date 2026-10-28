import Foundation

/*--------------------------------constants-----------------------------------*/

/// Shared App Group container identifier used by the app and WidgetKit extension.
public enum AppStorageGroup {
    public static let suiteName = "group.com.aten.nichiji"
}

/*---------------------------------enums--------------------------------------*/

/// Theme selection controlling Washi light or Sumi dark tokens.
public enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

/// Grouping system used for level selection and custom kanji picking.
public enum LevelSystem: String, Codable, CaseIterable, Sendable {
    case jlpt
    case joyo
}

/// Ordering strategy for picking the next unlearned daily kanji.
public enum DailyOrder: String, Codable, CaseIterable, Sendable {
    case mostCommon
    case listOrder
    case random
}

/// Shared UserDefaults keys for lightweight scalar learner preferences.
public enum LearnerPreferenceKey: String, Sendable {
    case hasCompletedOnboarding
    case appearanceMode
    case showsRomaji
    case streakFreezeEnabled
    case reminderEnabled
    case reminderHour
    case reminderMinute
    case levelSystem
    case selectedJLPTLevel
    case selectedJoyoGrade
    case dailyOrder
    case isCustomPoolActive
}

/*--------------------------------structs-------------------------------------*/

/// Value snapshot of all scalar learner preferences stored in UserDefaults.
public struct LearnerPreferencesSnapshot: Codable, Equatable, Sendable {
    public var hasCompletedOnboarding: Bool
    public var appearanceMode: AppearanceMode
    public var showsRomaji: Bool
    public var streakFreezeEnabled: Bool
    public var reminderEnabled: Bool
    public var reminderHour: Int
    public var reminderMinute: Int
    public var levelSystem: LevelSystem
    public var selectedJLPTLevel: JLPTLevel
    public var selectedJoyoGrade: JoyoGrade
    public var dailyOrder: DailyOrder
    public var isCustomPoolActive: Bool

    public init(
        hasCompletedOnboarding: Bool = false,
        appearanceMode: AppearanceMode = .system,
        showsRomaji: Bool = true,
        streakFreezeEnabled: Bool = false,
        reminderEnabled: Bool = true,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        levelSystem: LevelSystem = .jlpt,
        selectedJLPTLevel: JLPTLevel = .n5,
        selectedJoyoGrade: JoyoGrade = .grade1,
        dailyOrder: DailyOrder = .mostCommon,
        isCustomPoolActive: Bool = false
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.appearanceMode = appearanceMode
        self.showsRomaji = showsRomaji
        self.streakFreezeEnabled = streakFreezeEnabled
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.levelSystem = levelSystem
        self.selectedJLPTLevel = selectedJLPTLevel
        self.selectedJoyoGrade = selectedJoyoGrade
        self.dailyOrder = dailyOrder
        self.isCustomPoolActive = isCustomPoolActive
    }

    public static let standard = LearnerPreferencesSnapshot()
}
