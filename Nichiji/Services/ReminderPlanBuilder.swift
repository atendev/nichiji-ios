import Foundation

/*--------------------------------enums---------------------------------------*/

/// What the learner's assignment looks like today, as far as reminder copy is concerned.
enum ReminderTodayState: Equatable, Sendable {
    case assigned(kanji: String)
    case learned
}

/// Notification body variants for the rolling reminder window.
enum ReminderCopy: Equatable, Sendable {
    case kanjiLed(String)
    case missedDay
    case generic

    var body: String {
        switch self {
        case .kanjiLed(let kanji): "\(kanji) · Today's kanji is ready"
        case .missedDay: "You missed yesterday's kanji. That's okay, check it now."
        case .generic: "Today's kanji is ready"
        }
    }
}

/*--------------------------------structs-------------------------------------*/

/// One planned local notification: a stable identifier, a fire time and its copy.
struct ReminderPlan: Equatable, Sendable {
    let identifier: String
    let fireComponents: DateComponents
    let copy: ReminderCopy
}

/*--------------------------------builder-------------------------------------*/

/// Pure planner for the rolling 7-day reminder window. No notification center involved.
enum ReminderPlanBuilder {
    static let windowSize = 7
    static let identifierPrefix = "nichiji.reminder."

    /// Plans up to 7 daily reminders. Today is skipped once learned or once its time has passed.
    static func plans(
        now: Date,
        calendar: Calendar,
        hour: Int,
        minute: Int,
        today: ReminderTodayState
    ) -> [ReminderPlan] {
        let hour = min(max(hour, 0), 23)
        let minute = min(max(minute, 0), 59)
        let startOfToday = calendar.startOfDay(for: now)

        var firstOffset = 1
        var firstCopy: ReminderCopy = .generic
        switch today {
        case .assigned(let kanji):
            if let todayFire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now),
               todayFire > now {
                firstOffset = 0
                firstCopy = .kanjiLed(kanji)
            } else {
                firstCopy = .missedDay
            }
        case .learned:
            break
        }

        return (0..<windowSize).compactMap { index in
            let offset = firstOffset + index
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { return nil }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute
            return ReminderPlan(
                identifier: identifier(for: components),
                fireComponents: components,
                copy: index == 0 ? firstCopy : .generic
            )
        }
    }

    private static func identifier(for components: DateComponents) -> String {
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return identifierPrefix + String(format: "%04d-%02d-%02d", year, month, day)
    }
}
