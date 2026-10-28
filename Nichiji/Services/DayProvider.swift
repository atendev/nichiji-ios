import Foundation

/*-------------------------------protocols------------------------------------*/

/// Injected clock and calendar boundary for deterministic day rollover and midnight scheduling.
protocol DayProvider: Sendable {
    /// Current instant from the system clock or test fixture.
    // TODO: Return Date.now in the live provider and a controllable date in tests.
    var now: Date { get }

    /// Active local calendar used to compute day boundaries.
    // TODO: Return Calendar.autoupdatingCurrent in the live provider and a fixed time-zone calendar in tests.
    var calendar: Calendar { get }

    /// Formats a date as a local calendar day key (yyyy-MM-dd).
    // TODO: Format date in the provider's calendar and time zone using a zero-padded yyyy-MM-dd representation.
    func calendarDay(for date: Date) -> String

    /// Computes the start of the next local calendar day after the given instant.
    // TODO: Advance to the next local midnight in the provider's calendar for widget timeline refresh and reminder scheduling.
    func nextMidnight(after date: Date) -> Date
}
