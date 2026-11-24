// MEASURE-PROBE (ticket 088, extended by ticket 095).
// Compiled only for DEBUG and Internal (TestFlight) builds; App Store Release builds exclude it.
// REMOVE: after ticket 095 closes, delete this file, Nichiji/Views/Settings/MeasureSection.swift,
// the `MeasureSection()` call in SettingsSheet.swift and every `WidgetMemoryProbe.begin/mark/record` call.
// Find every spot with: grep -rn "MEASURE-PROBE\|WidgetMemoryProbe\|MeasureSection" Nichiji NichijiWidget

#if DEBUG || DEV_UNLOCK
import Darwin
import Foundation

/// Temporary widget memory probe (tickets 088 and 095). Records the footprint after each marked stage of a timeline run and the run's true peak.
enum WidgetMemoryProbe {
    private static let residentPeakKey = "measure.widgetPeakMB"
    private static let residentLastKey = "measure.widgetLastMB"
    private static let runsKey = "measure.widgetRuns"
    private static let footprintPeakKey = "measure.footprintPeakMB"
    private static let peakTraceKey = "measure.peakTrace"
    private static let lastTraceKey = "measure.lastTrace"

    private static let run = Run()

    /// Resident size, kept so the 088 figures stay comparable.
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

    /// Physical footprint, the number the system's widget memory limit counts.
    static func footprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(task_self_trap(), task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : 0
    }

    /// Starts a run and a 2 ms sampler that tracks the run's peak footprint.
    static func begin() {
        run.begin()
    }

    /// Records the footprint after a stage. Does nothing outside a run, so the app can share the marked code.
    static func mark(_ stage: String) {
        run.mark(stage)
    }

    /// Ends the run and saves its peak and stage trace.
    static func record() {
        run.finish()
    }

    static func summary() -> String {
        guard let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName),
              defaults.integer(forKey: runsKey) > 0 else {
            return "No widget runs recorded yet."
        }
        return String(
            format: "Runs %d. Resident peak %.1f MB, last %.1f MB.\nPeak run: %@\nLast run: %@",
            defaults.integer(forKey: runsKey),
            defaults.double(forKey: residentPeakKey),
            defaults.double(forKey: residentLastKey),
            defaults.string(forKey: peakTraceKey) ?? "none",
            defaults.string(forKey: lastTraceKey) ?? "none"
        )
    }

    /*----------------------------------run-----------------------------------*/

    private final class Run: @unchecked Sendable {
        private let lock = NSLock()
        private var active = false
        private var stages: [(name: String, mb: Double)] = []
        private var peakMB = 0.0
        private var peakAfter = ""
        private var timer: DispatchSourceTimer?

        func begin() {
            lock.lock()
            timer?.cancel()
            active = true
            stages = []
            peakMB = 0
            peakAfter = "at start"
            let source = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
            source.schedule(deadline: .now(), repeating: .milliseconds(2))
            source.setEventHandler { [weak self] in self?.sample() }
            timer = source
            lock.unlock()
            source.resume()
            mark("start")
        }

        func mark(_ stage: String) {
            let mb = WidgetMemoryProbe.footprintMB()
            lock.lock()
            defer { lock.unlock() }
            guard active else { return }
            stages.append((stage, mb))
            if mb > peakMB {
                peakMB = mb
                peakAfter = "at \(stage)"
            }
        }

        private func sample() {
            let mb = WidgetMemoryProbe.footprintMB()
            lock.lock()
            defer { lock.unlock() }
            guard active, mb > peakMB else { return }
            peakMB = mb
            peakAfter = "after \(stages.last?.name ?? "start")"
        }

        func finish() {
            mark("end")
            lock.lock()
            guard active else {
                lock.unlock()
                return
            }
            active = false
            timer?.cancel()
            timer = nil
            let trace = stages.map { String(format: "%@ %.1f", $0.name, $0.mb) }.joined(separator: " > ")
            let peak = peakMB
            let line = String(format: "peak %.1f MB %@ | ", peak, peakAfter) + trace
            lock.unlock()

            guard let defaults = UserDefaults(suiteName: AppStorageGroup.suiteName) else { return }
            if peak > defaults.double(forKey: WidgetMemoryProbe.footprintPeakKey) {
                defaults.set(peak, forKey: WidgetMemoryProbe.footprintPeakKey)
                defaults.set(line, forKey: WidgetMemoryProbe.peakTraceKey)
            }
            defaults.set(line, forKey: WidgetMemoryProbe.lastTraceKey)
            let resident = WidgetMemoryProbe.residentMB()
            defaults.set(max(defaults.double(forKey: WidgetMemoryProbe.residentPeakKey), resident), forKey: WidgetMemoryProbe.residentPeakKey)
            defaults.set(resident, forKey: WidgetMemoryProbe.residentLastKey)
            defaults.set(defaults.integer(forKey: WidgetMemoryProbe.runsKey) + 1, forKey: WidgetMemoryProbe.runsKey)
        }
    }
}
#endif
