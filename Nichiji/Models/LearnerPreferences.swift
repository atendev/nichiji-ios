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

    /// Display label used in the Settings appearance picker.
    public var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// Descriptive note displayed below the Settings appearance picker.
    public var subtitleNote: String {
        switch self {
        case .system: "Matches your phone. Light by day, dark at night."
        case .light: "Always light, like washi paper."
        case .dark: "Always dark, like sumi ink at night."
        }
    }
}

/// Grouping system used for level selection and custom kanji picking.
public enum LevelSystem: String, Codable, CaseIterable, Sendable {
    case jlpt
    case joyo

    /// Display title for segmented pickers and headers.
    public var displayName: String {
        switch self {
        case .jlpt: "JLPT"
        case .joyo: "Jōyō grade"
        }
    }

    /// Explanatory note displayed below the level system switch.
    public var schemeNote: String {
        switch self {
        case .jlpt: "JLPT levels follow the Japanese-Language Proficiency Test, from N5 to N1."
        case .joyo: "Jōyō grades follow the Japanese school curriculum, from 1st grade to secondary school."
        }
    }
}

/// Ordering strategy for picking the next unlearned daily kanji.
public enum DailyOrder: String, Codable, CaseIterable, Sendable {
    case mostCommon
    case listOrder
    case random

    /// Primary row title in Level & Order settings.
    public var displayName: String {
        switch self {
        case .mostCommon: "Most common"
        case .listOrder: "List order"
        case .random: "Random"
        }
    }

    /// Secondary descriptive subtitle in Level & Order settings.
    public var subtitleNote: String {
        switch self {
        case .mostCommon: "Everyday kanji come first."
        case .listOrder: "Follows the order of the level list."
        case .random: "A different kanji each day."
        }
    }
}

public extension JLPTLevel {
    /// Short badge code (`N5` through `N1`).
    var codeLabel: String {
        rawValue.uppercased()
    }

    /// Descriptive level name (`Beginner` through `Advanced`).
    var displayName: String {
        switch self {
        case .n5: "Beginner"
        case .n4: "Elementary"
        case .n3: "Intermediate"
        case .n2: "Upper intermediate"
        case .n1: "Advanced"
        }
    }

    /// Summary string displayed in the main Settings row (`N5 · Beginner`).
    var settingsSummary: String {
        "\(codeLabel) · \(displayName)"
    }
}

public extension JoyoGrade {
    /// Short badge code (`1` through `6`, or `S`).
    var codeLabel: String {
        switch self {
        case .grade1: "1"
        case .grade2: "2"
        case .grade3: "3"
        case .grade4: "4"
        case .grade5: "5"
        case .grade6: "6"
        case .secondary: "S"
        }
    }

    /// Descriptive grade name (`1st grade` through `Secondary school`).
    var displayName: String {
        switch self {
        case .grade1: "1st grade"
        case .grade2: "2nd grade"
        case .grade3: "3rd grade"
        case .grade4: "4th grade"
        case .grade5: "5th grade"
        case .grade6: "6th grade"
        case .secondary: "Secondary school"
        }
    }

    /// Summary string displayed in the main Settings row (`1st grade · Jōyō`).
    var settingsSummary: String {
        "\(displayName) · Jōyō"
    }
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
        reminderHour: Int = 8,
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

    /// Reads the current snapshot from a UserDefaults instance, applying defaults for unset keys.
    public static func load(
        from defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
    ) -> LearnerPreferencesSnapshot {
        let standard = Self.standard
        let hasCompletedOnboarding = defaults.object(forKey: LearnerPreferenceKey.hasCompletedOnboarding.rawValue) as? Bool
            ?? standard.hasCompletedOnboarding
        let appearanceMode = AppearanceMode(
            rawValue: defaults.string(forKey: LearnerPreferenceKey.appearanceMode.rawValue) ?? ""
        ) ?? standard.appearanceMode
        let showsRomaji = defaults.object(forKey: LearnerPreferenceKey.showsRomaji.rawValue) as? Bool
            ?? standard.showsRomaji
        let streakFreezeEnabled = defaults.object(forKey: LearnerPreferenceKey.streakFreezeEnabled.rawValue) as? Bool
            ?? standard.streakFreezeEnabled
        let reminderEnabled = defaults.object(forKey: LearnerPreferenceKey.reminderEnabled.rawValue) as? Bool
            ?? standard.reminderEnabled
        let reminderHour = defaults.object(forKey: LearnerPreferenceKey.reminderHour.rawValue) as? Int
            ?? standard.reminderHour
        let reminderMinute = defaults.object(forKey: LearnerPreferenceKey.reminderMinute.rawValue) as? Int
            ?? standard.reminderMinute
        let levelSystem = LevelSystem(
            rawValue: defaults.string(forKey: LearnerPreferenceKey.levelSystem.rawValue) ?? ""
        ) ?? standard.levelSystem
        let selectedJLPTLevel = JLPTLevel(
            rawValue: defaults.string(forKey: LearnerPreferenceKey.selectedJLPTLevel.rawValue) ?? ""
        ) ?? standard.selectedJLPTLevel
        let selectedJoyoGrade = JoyoGrade(
            rawValue: defaults.string(forKey: LearnerPreferenceKey.selectedJoyoGrade.rawValue) ?? ""
        ) ?? standard.selectedJoyoGrade
        let dailyOrder = DailyOrder(
            rawValue: defaults.string(forKey: LearnerPreferenceKey.dailyOrder.rawValue) ?? ""
        ) ?? standard.dailyOrder
        let isCustomPoolActive = defaults.object(forKey: LearnerPreferenceKey.isCustomPoolActive.rawValue) as? Bool
            ?? standard.isCustomPoolActive

        return LearnerPreferencesSnapshot(
            hasCompletedOnboarding: hasCompletedOnboarding,
            appearanceMode: appearanceMode,
            showsRomaji: showsRomaji,
            streakFreezeEnabled: streakFreezeEnabled,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            levelSystem: levelSystem,
            selectedJLPTLevel: selectedJLPTLevel,
            selectedJoyoGrade: selectedJoyoGrade,
            dailyOrder: dailyOrder,
            isCustomPoolActive: isCustomPoolActive
        )
    }

    /// Writes all fields of the snapshot into a UserDefaults instance.
    public func save(
        to defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
    ) {
        defaults.set(hasCompletedOnboarding, forKey: LearnerPreferenceKey.hasCompletedOnboarding.rawValue)
        defaults.set(appearanceMode.rawValue, forKey: LearnerPreferenceKey.appearanceMode.rawValue)
        defaults.set(showsRomaji, forKey: LearnerPreferenceKey.showsRomaji.rawValue)
        defaults.set(streakFreezeEnabled, forKey: LearnerPreferenceKey.streakFreezeEnabled.rawValue)
        defaults.set(reminderEnabled, forKey: LearnerPreferenceKey.reminderEnabled.rawValue)
        defaults.set(reminderHour, forKey: LearnerPreferenceKey.reminderHour.rawValue)
        defaults.set(reminderMinute, forKey: LearnerPreferenceKey.reminderMinute.rawValue)
        defaults.set(levelSystem.rawValue, forKey: LearnerPreferenceKey.levelSystem.rawValue)
        defaults.set(selectedJLPTLevel.rawValue, forKey: LearnerPreferenceKey.selectedJLPTLevel.rawValue)
        defaults.set(selectedJoyoGrade.rawValue, forKey: LearnerPreferenceKey.selectedJoyoGrade.rawValue)
        defaults.set(dailyOrder.rawValue, forKey: LearnerPreferenceKey.dailyOrder.rawValue)
        defaults.set(isCustomPoolActive, forKey: LearnerPreferenceKey.isCustomPoolActive.rawValue)
    }

    /// Human-readable summary of the active level or custom kanji pool for Settings rows.
    public func levelSummary(customCount: Int) -> String {
        if isCustomPoolActive {
            return "Custom · \(customCount) kanji"
        }
        switch levelSystem {
        case .jlpt:
            return selectedJLPTLevel.settingsSummary
        case .joyo:
            return selectedJoyoGrade.settingsSummary
        }
    }

    /// Human-readable summary of the daily reminder state and time (`On · 8:00 AM` or `Off`).
    public var reminderSummary: String {
        guard reminderEnabled else { return "Off" }
        return "On · \(formattedReminderTime)"
    }

    /// Formats `reminderHour` and `reminderMinute` into a 12-hour clock label (`8:00 am`).
    public var formattedReminderTime: String {
        let period = reminderHour >= 12 ? "pm" : "am"
        let displayHour: Int
        if reminderHour == 0 {
            displayHour = 12
        } else if reminderHour > 12 {
            displayHour = reminderHour - 12
        } else {
            displayHour = reminderHour
        }
        return String(format: "%d:%02d %@", displayHour, reminderMinute, period)
    }
}
