import Foundation

/*-------------------------------protocols------------------------------------*/

/// Injected clock and calendar boundary for deterministic day rollover and midnight scheduling.
public protocol DayProvider: Sendable {
    /// Current instant from the system clock or test fixture.
    var now: Date { get }

    /// Active local calendar used to compute day boundaries.
    var calendar: Calendar { get }

    /// Formats a date as a local calendar day key (yyyy-MM-dd).
    func calendarDay(for date: Date) -> String

    /// Computes the start of the next local calendar day after the given instant.
    func nextMidnight(after date: Date) -> Date
}

/*--------------------------------providers-----------------------------------*/

/// System-clock provider backed by auto-updating user calendar and time zone.
public final class SystemDayProvider: DayProvider, Sendable {
    public init() {}

    public var now: Date {
        Date()
    }

    public var calendar: Calendar {
        Calendar.autoupdatingCurrent
    }

    public func calendarDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    public func nextMidnight(after date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date.addingTimeInterval(86400)
    }
}
