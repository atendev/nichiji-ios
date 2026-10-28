import Foundation
@testable import Nichiji

/*------------------------------test-day----------------------------------*/

final class TestDayProvider: DayProvider, @unchecked Sendable {
    var simulatedDate: Date
    var simulatedCalendar: Calendar

    init(
        simulatedDate: Date = Date(timeIntervalSince1970: 1_700_000_000),
        timeZone: TimeZone = TimeZone(identifier: "Asia/Tokyo")!
    ) {
        self.simulatedDate = simulatedDate
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.simulatedCalendar = calendar
    }

    var now: Date {
        simulatedDate
    }

    var calendar: Calendar {
        simulatedCalendar
    }

    func calendarDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = simulatedCalendar
        formatter.timeZone = simulatedCalendar.timeZone
        return formatter.string(from: date)
    }

    func nextMidnight(after date: Date) -> Date {
        let startOfDay = simulatedCalendar.startOfDay(for: date)
        return simulatedCalendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date.addingTimeInterval(86400)
    }

    func advance(bySeconds seconds: TimeInterval) {
        simulatedDate = simulatedDate.addingTimeInterval(seconds)
    }

    func advance(byDays days: Int) {
        let fallback = simulatedDate.addingTimeInterval(Double(days) * 86400)
        simulatedDate = simulatedCalendar.date(byAdding: .day, value: days, to: simulatedDate) ?? fallback
    }
}
