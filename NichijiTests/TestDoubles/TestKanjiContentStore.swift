import Foundation
@testable import Nichiji

/*----------------------------test-content--------------------------------*/

final class TestKanjiContentStore: KanjiContentStore, @unchecked Sendable {
    var entries: [String: KanjiEntry] = [:]
    var strokeSVGs: [String: String] = [:]

    init(entries: [KanjiEntry] = []) {
        for entry in entries {
            self.entries[entry.id] = entry
        }
    }

    func loadIndex() async throws -> [KanjiIndexEntry] {
        entries.values.map { entry in
            KanjiIndexEntry(
                id: entry.id,
                primaryMeaning: entry.meanings.first ?? "",
                primaryReading: entry.onyomi.first?.kana ?? entry.kunyomi.first?.kana ?? "",
                strokeCount: entry.strokeCount,
                jlptLevel: entry.jlptLevel,
                joyoGrade: entry.joyoGrade,
                canonicalIndex: entry.canonicalIndex
            )
        }
    }

    func loadEntry(id: String) async throws -> KanjiEntry {
        guard let entry = entries[id] else {
            throw NichijiError.contentMissing(kanjiID: id)
        }
        return entry
    }

    func strokeSVG(id: String) async throws -> String {
        guard let svg = strokeSVGs[id] else {
            throw NichijiError.contentMissing(kanjiID: id)
        }
        return svg
    }
}
