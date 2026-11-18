import Darwin
import Foundation
import Testing
@testable import Nichiji

/*----------------------dictionary-search-index-cost-tests---------------------*/

/// Builds the Dictionary search index from the real 6,407-kanji bundle and prints what it cost.
/// The ceilings are loose on purpose: the printed lines are the measurement, the ceilings only catch a blow-up.
/// 044 budgeted about 20 MB for the index.
@Suite("Dictionary search index cost Tests")
struct DictionarySearchIndexCostTests {
    private static let buildCeiling: Duration = .seconds(10)
    private static let growthCeilingMB = 150.0

    private static func residentBytes() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(task_self_trap(), task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    @Test("The real index builds quickly and its resident memory growth is printed")
    func buildTimeAndMemory() throws {
        let store = BundledKanjiContentStore()
        let source = BundledDictionarySearchSource()
        let before = Self.residentBytes()
        var built: DictionarySearchIndex?

        let elapsed = try ContinuousClock().measure {
            built = try DictionarySearchIndex.load(contentStore: store, source: source)
        }

        let growthMB = Double(Self.residentBytes() - before) / 1_048_576
        let index = try #require(built)
        let milliseconds = Double(elapsed.components.seconds) * 1_000 + Double(elapsed.components.attoseconds) / 1e15
        print("SEARCH-INDEX build: \(Int(milliseconds)) ms, resident growth: \(String(format: "%.1f", growthMB)) MB, kanji: 6407")

        #expect(index.search("山").kanji.first?.id == "山")
        #expect(elapsed < Self.buildCeiling)
        #expect(growthMB < Self.growthCeilingMB)
        withExtendedLifetime(index) {}
    }
}
