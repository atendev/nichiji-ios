import Foundation
import Testing
@testable import Nichiji

/*----------------------------dictionary-tests----------------------------*/

@Suite("Dictionary Browse Tests")
struct DictionaryBrowseTests {
    private func indexEntry(
        _ id: String,
        jlpt: JLPTLevel?,
        joyo: JoyoGrade?,
        classification: KanjiClassification? = nil,
        listIndex: Int,
        meaning: String = "meaning"
    ) -> KanjiIndexEntry {
        StatsFixtures.entry(id, jlpt: jlpt, joyo: joyo, classification: classification, listIndex: listIndex, meaning: meaning)
    }

    private var mixedEntries: [KanjiIndexEntry] {
        [
            indexEntry("楽", jlpt: .n4, joyo: .grade2, listIndex: 5),
            indexEntry("日", jlpt: .n5, joyo: .grade1, listIndex: 1),
            indexEntry("彦", jlpt: .n1, joyo: nil, listIndex: 9),
            indexEntry("一", jlpt: .n5, joyo: .grade1, listIndex: 0),
            indexEntry("憂", jlpt: .n1, joyo: .secondary, listIndex: 7)
        ]
    }

    @Test("JLPT browse runs N5 to N1 with kanji in list order")
    func jlptSectionsInLevelOrder() {
        let sections = KanjiBrowseGrouping.sections(from: mixedEntries, system: .jlpt)

        #expect(sections.map(\.title) == ["N5", "N4", "N1"])
        #expect(sections[0].entries.map(\.id) == ["一", "日"])
        #expect(sections[2].entries.map(\.id) == ["憂", "彦"])
    }

    @Test("JLPT browse ends with Name kanji and Beyond the lists, holding only kanji with no N-level")
    func jlptListSteps() {
        let entries = mixedEntries + [
            indexEntry("凜", jlpt: nil, joyo: nil, classification: .jinmeiyo, listIndex: 20),
            indexEntry("丼", jlpt: nil, joyo: nil, classification: .hyogai, listIndex: 21)
        ]

        let sections = KanjiBrowseGrouping.sections(from: entries, system: .jlpt)

        #expect(sections.map(\.title) == ["N5", "N4", "N1", "Name kanji", "Beyond the lists"])
        #expect(sections[3].entries.map(\.id) == ["凜"])
        #expect(sections[4].entries.map(\.id) == ["丼"])
        #expect(sections[2].entries.map(\.id) == ["憂", "彦"])
    }

    @Test("Jōyō browse runs grade 1 to Secondary, then every name kanji, then Beyond the lists")
    func joyoSectionsEndWithListSteps() {
        let entries = mixedEntries + [indexEntry("丼", jlpt: nil, joyo: nil, classification: .hyogai, listIndex: 21)]

        let sections = KanjiBrowseGrouping.sections(from: entries, system: .joyo)

        #expect(sections.map(\.title) == ["1st grade", "2nd grade", "Secondary school", "Name kanji", "Beyond the lists"])
        #expect(sections[3].entries.map(\.id) == ["彦"])
        #expect(sections[4].entries.map(\.id) == ["丼"])
    }

    @Test("Empty list steps are dropped")
    func emptyListStepsDropped() {
        for system in LevelSystem.allCases {
            let titles = KanjiBrowseGrouping.sections(from: [mixedEntries[1]], system: system).map(\.title)
            #expect(!titles.contains("Name kanji"))
            #expect(!titles.contains("Beyond the lists"))
        }
    }

    @Test("Every kanji appears exactly once in either system")
    func everyKanjiOnce() {
        for system in LevelSystem.allCases {
            let ids = KanjiBrowseGrouping.sections(from: mixedEntries, system: system).flatMap { $0.entries.map(\.id) }
            #expect(ids.count == mixedEntries.count)
            #expect(Set(ids) == Set(mixedEntries.map(\.id)))
        }
    }

    @Test("Empty input gives no sections")
    func emptyInput() {
        #expect(KanjiBrowseGrouping.sections(from: [], system: .jlpt).isEmpty)
        #expect(KanjiBrowseGrouping.sections(from: [], system: .joyo).isEmpty)
    }

    @Test("Section count label is singular for one kanji")
    func countLabel() {
        let one = KanjiBrowseSection(id: "n4", title: "N4", entries: [indexEntry("楽", jlpt: .n4, joyo: .grade2, listIndex: 0)])
        let two = KanjiBrowseSection(id: "n5", title: "N5", entries: Array(mixedEntries.prefix(2)))

        #expect(one.countLabel == "1 kanji")
        #expect(two.countLabel == "2 kanji")
    }

    @Test("Tiles read the glyph and meaning and keep the 44 pt minimum")
    func tileAccessibilityAndSize() {
        #expect(KanjiGridTile.accessibilityLabel(kanji: "楽", meaning: "music") == "楽, music")
        #expect(KanjiGridTile.accessibilityLabel(kanji: "楽", meaning: "") == "楽")
        #expect(KanjiGridTile.minimumSide >= 44)
        #expect(KanjiGridTile.columns.count == 5)
    }

    @Test("Loading the browse grid reads the index and decodes no records")
    func loadStaysOnIndex() throws {
        let store = TestKanjiContentStore(entries: SeedKanjiDataset.entries)

        let sections = try KanjiBrowseGrouping.load(system: .jlpt, contentStore: store)

        #expect(sections.flatMap(\.entries).count == SeedKanjiDataset.entries.count)
        #expect(store.recordLoadCount == 0)
    }

    @Test("Browse rows put a header before each level and chunk its kanji into rows of the column count")
    func rowsChunkKanjiUnderHeaders() {
        let sections = KanjiBrowseGrouping.sections(from: mixedEntries, system: .jlpt)

        let rows = KanjiBrowseGrouping.rows(from: sections, collapsed: [], columnCount: 2)

        #expect(rows.map(\.id) == ["header-n5", "n5-0", "header-n4", "n4-0", "header-n1", "n1-0"])
        #expect(rows.first == .header(sections[0], isCollapsed: false, isFirst: true))
        #expect(rows[2] == .header(sections[1], isCollapsed: false, isFirst: false))
    }

    @Test("A collapsed level keeps its header and drops its tiles")
    func collapsedLevelDropsTiles() {
        let sections = KanjiBrowseGrouping.sections(from: mixedEntries, system: .jlpt)

        let rows = KanjiBrowseGrouping.rows(from: sections, collapsed: [sections[1].id], columnCount: 5)

        #expect(rows.map(\.id) == ["header-n5", "n5-0", "header-n4", "header-n1", "n1-0"])
        #expect(rows[2] == .header(sections[1], isCollapsed: true, isFirst: false))
    }

    @Test("A level with more kanji than columns ends on a short row")
    func lastRowCanBeShort() {
        let entries = (0..<7).map { indexEntry("k\($0)", jlpt: .n5, joyo: .grade1, listIndex: $0) }
        let sections = KanjiBrowseGrouping.sections(from: entries, system: .jlpt)

        let rows = KanjiBrowseGrouping.rows(from: sections, collapsed: [], columnCount: 5)

        guard case .tiles(_, let first) = rows[1], case .tiles(_, let second) = rows[2] else {
            Issue.record("expected two tile rows")
            return
        }
        #expect(first.count == 5)
        #expect(second.count == 2)
    }

    @Test("The bundled index puts all 6,407 kanji on exactly one rung of each ladder")
    func bundledIndexCoversEveryKanji() throws {
        let store = BundledKanjiContentStore()
        let entries = try store.indexEntries()

        let jlpt = KanjiBrowseGrouping.sections(from: entries, system: .jlpt)
        let joyo = KanjiBrowseGrouping.sections(from: entries, system: .joyo)

        #expect(entries.count == 6_407)
        #expect(entries.map(\.listIndex) == entries.map(\.listIndex).sorted())
        #expect(jlpt.reduce(0) { $0 + $1.entries.count } == 6_407)
        #expect(joyo.reduce(0) { $0 + $1.entries.count } == 6_407)
        #expect(jlpt.suffix(2).map(\.entries.count) == [559, 3_465])
        #expect(joyo.suffix(2).map(\.entries.count) == [806, 3_465])
        #expect(jlpt.last?.title == "Beyond the lists")
        #expect(joyo.last?.title == "Beyond the lists")
    }
}
