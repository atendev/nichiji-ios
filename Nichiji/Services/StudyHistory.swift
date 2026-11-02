import Foundation

/*--------------------------------history-------------------------------------*/

/// The You tab's History list: every log entry, grouped by day.
enum StudyHistory {
    /// Days newest first; entries within a day in the order they happened.
    static func days(log: [StudyLogRecord], dayProvider: any DayProvider) -> [HistoryDay] {
        let grouped = Dictionary(grouping: log) { $0.day(using: dayProvider) }
        return grouped.keys.sorted(by: >).map { day in
            HistoryDay(
                calendarDay: day,
                heading: heading(for: day, dayProvider: dayProvider),
                entries: inTimeOrder(grouped[day, default: []])
            )
        }
    }

    /// "TODAY", "YESTERDAY", then "MON, OCT 26", with the year added for past years.
    static func heading(for day: String, dayProvider: any DayProvider) -> String {
        let calendar = dayProvider.calendar
        let today = calendar.startOfDay(for: dayProvider.now)
        if day == dayProvider.calendarDay(for: today) {
            return "TODAY"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), day == dayProvider.calendarDay(for: yesterday) {
            return "YESTERDAY"
        }
        guard let date = StatsCalculator.date(forDay: day, dayProvider: dayProvider) else { return day }

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let sameYear = gregorian.component(.year, from: date) == gregorian.component(.year, from: today)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = gregorian
        formatter.timeZone = gregorian.timeZone
        formatter.dateFormat = sameYear ? "EEE, MMM d" : "EEE, MMM d, yyyy"
        return formatter.string(from: date).uppercased()
    }

    /// Stable sort by timestamp, so entries logged at the same instant keep their stored order.
    static func inTimeOrder(_ log: [StudyLogRecord]) -> [StudyLogRecord] {
        log.enumerated()
            .sorted { ($0.element.timestamp, $0.offset) < ($1.element.timestamp, $1.offset) }
            .map(\.element)
    }
}

/*----------------------------------csv---------------------------------------*/

/// History export: one row per log entry, oldest first, UTF-8 with a BOM.
enum HistoryCSV {
    static let header = "date,time,kanji,meaning,action"

    static func data(log: [StudyLogRecord], meanings: [String: String], dayProvider: any DayProvider) -> Data {
        let timeFormatter = ISO8601DateFormatter()
        timeFormatter.timeZone = dayProvider.calendar.timeZone
        timeFormatter.formatOptions = [.withInternetDateTime]

        let rows = StudyHistory.inTimeOrder(log).map { record in
            [
                record.day(using: dayProvider),
                timeFormatter.string(from: record.timestamp),
                record.kanjiID,
                meanings[record.kanjiID] ?? "",
                actionName(record.action)
            ]
            .map(escape)
            .joined(separator: ",")
        }
        let text = ([header] + rows).map { $0 + "\n" }.joined()
        return Data(("\u{FEFF}" + text).utf8)
    }

    static func fileName(dayProvider: any DayProvider) -> String {
        "nichiji-history-\(dayProvider.calendarDay(for: dayProvider.now)).csv"
    }

    static func actionName(_ action: StudyAction) -> String {
        switch action {
        case .learnedDaily: "learned"
        case .gotItReview: "got_it"
        case .forgotItReview: "forgot_it"
        case .resetToNew: "forget_it"
        }
    }

    /// Quotes a field holding a comma, quote or line break, doubling any quotes.
    static func escape(_ field: String) -> String {
        let special = Set(",\"\n\r".unicodeScalars)
        guard field.unicodeScalars.contains(where: special.contains) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
