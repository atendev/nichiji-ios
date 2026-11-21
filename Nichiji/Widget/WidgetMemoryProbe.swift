import Darwin
import Foundation

/// Temporary measurement probe for ticket 088. Remove before merging to main.
enum WidgetMemoryProbe {
    private static let peakKey = "measure.widgetPeakMB"
    private static let lastKey = "measure.widgetLastMB"
    private static let runsKey = "measure.widgetRuns"

    static func residentMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(task_self_trap(), task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1_048_576 : 0
    }

    static func record() {
        guard let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) else { return }
        let mb = residentMB()
        defaults.set(max(defaults.double(forKey: peakKey), mb), forKey: peakKey)
        defaults.set(mb, forKey: lastKey)
        defaults.set(defaults.integer(forKey: runsKey) + 1, forKey: runsKey)
    }

    static func summary() -> String {
        guard let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName),
              defaults.integer(forKey: runsKey) > 0 else {
            return "No widget runs recorded yet."
        }
        return String(
            format: "Widget peak %.1f MB, last %.1f MB, runs %d",
            defaults.double(forKey: peakKey),
            defaults.double(forKey: lastKey),
            defaults.integer(forKey: runsKey)
        )
    }
}
