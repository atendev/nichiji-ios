import Foundation

/*--------------------------------constants-----------------------------------*/

/// Shared App Group container identifier used by the app and WidgetKit extension.
enum AppStorageGroup {
    static let suiteName = "group.com.aten.nichiji"
}

/*---------------------------------enums--------------------------------------*/

/// Theme selection controlling Washi light or Sumi dark tokens.
enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

/// Grouping system used for level selection and custom kanji picking.
enum LevelSystem: String, Codable, CaseIterable, Sendable {
    case jlpt
    case joyo
}

/// Ordering strategy for picking the next unlearned daily kanji.
enum DailyOrder: String, Codable, CaseIterable, Sendable {
    case mostCommon
    case listOrder
    case random
}

/// Shared UserDefaults keys for lightweight scalar learner preferences.
enum LearnerPreferenceKey: String, Sendable {
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
struct LearnerPreferencesSnapshot: Codable, Equatable, Sendable {
    var hasCompletedOnboarding: Bool
    var appearanceMode: AppearanceMode
    var showsRomaji: Bool
    var streakFreezeEnabled: Bool
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var levelSystem: LevelSystem
    var selectedJLPTLevel: JLPTLevel
    var selectedJoyoGrade: JoyoGrade
    var dailyOrder: DailyOrder
    var isCustomPoolActive: Bool
}
