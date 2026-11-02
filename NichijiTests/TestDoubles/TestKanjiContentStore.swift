import Foundation
@testable import Nichiji

/*----------------------------test-content--------------------------------*/

final class TestKanjiContentStore: KanjiContentStore, @unchecked Sendable {
    var entriesDict: [String: KanjiEntry] = [:]
    var strokePathDict: [String: [String]] = [:]
    /// Counts full-record reads, so tests can prove a path stays on the index.
    private(set) var recordLoadCount = 0

    init(entries: [KanjiEntry] = [], strokePaths: [String: [String]] = [:]) {
        for entry in entries {
            self.entriesDict[entry.id] = entry
        }
        self.strokePathDict = strokePaths
    }

    func entry(for kanjiID: String) throws -> KanjiEntry {
        recordLoadCount += 1
        guard let entry = entriesDict[kanjiID] else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        return entry
    }

    func entries(for jlptLevel: JLPTLevel) throws -> [KanjiEntry] {
        recordLoadCount += 1
        return entriesDict.values
            .filter { $0.jlptLevel == jlptLevel }
            .sorted(by: { $0.listIndex < $1.listIndex })
    }

    func entries(for joyoGrade: JoyoGrade) throws -> [KanjiEntry] {
        recordLoadCount += 1
        return entriesDict.values
            .filter { $0.joyoGrade == joyoGrade }
            .sorted(by: { $0.listIndex < $1.listIndex })
    }

    func count(for jlptLevel: JLPTLevel) throws -> Int {
        entriesDict.values.filter { $0.jlptLevel == jlptLevel }.count
    }

    func count(for joyoGrade: JoyoGrade) throws -> Int {
        entriesDict.values.filter { $0.joyoGrade == joyoGrade }.count
    }

    func indexEntries() throws -> [KanjiIndexEntry] {
        entriesDict.values
            .sorted(by: { $0.listIndex < $1.listIndex })
            .map { entry in
                KanjiIndexEntry(
                    id: entry.id,
                    primaryMeaning: entry.meanings.first ?? "",
                    primaryReading: entry.onyomi.first?.kana ?? entry.kunyomi.first?.kana ?? "",
                    strokeCount: entry.strokeCount,
                    jlptLevel: entry.jlptLevel,
                    joyoGrade: entry.joyoGrade,
                    listIndex: entry.listIndex,
                    frequencyRank: entry.frequencyRank
                )
            }
    }

    func strokePaths(for kanjiID: String) throws -> [String] {
        guard let paths = strokePathDict[kanjiID] else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        return paths
    }
}
