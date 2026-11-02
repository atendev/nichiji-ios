import Foundation
@testable import Nichiji

/*----------------------------test-content--------------------------------*/

final class TestKanjiContentStore: KanjiContentStore, @unchecked Sendable {
    var entriesDict: [String: KanjiEntry] = [:]
    var strokePathDict: [String: [String]] = [:]

    init(entries: [KanjiEntry] = [], strokePaths: [String: [String]] = [:]) {
        for entry in entries {
            self.entriesDict[entry.id] = entry
        }
        self.strokePathDict = strokePaths
    }

    func entry(for kanjiID: String) throws -> KanjiEntry {
        guard let entry = entriesDict[kanjiID] else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        return entry
    }

    func entries(for jlptLevel: JLPTLevel) throws -> [KanjiEntry] {
        entriesDict.values
            .filter { $0.jlptLevel == jlptLevel }
            .sorted(by: { $0.listIndex < $1.listIndex })
    }

    func entries(for joyoGrade: JoyoGrade) throws -> [KanjiEntry] {
        entriesDict.values
            .filter { $0.joyoGrade == joyoGrade }
            .sorted(by: { $0.listIndex < $1.listIndex })
    }

    func count(for jlptLevel: JLPTLevel) throws -> Int {
        try entries(for: jlptLevel).count
    }

    func count(for joyoGrade: JoyoGrade) throws -> Int {
        try entries(for: joyoGrade).count
    }

    func strokePaths(for kanjiID: String) throws -> [String] {
        guard let paths = strokePathDict[kanjiID] else {
            throw NichijiError.contentMissing(kanjiID: kanjiID)
        }
        return paths
    }
}
