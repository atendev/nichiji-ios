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
        listIndex: Int,
        meaning: String = "meaning"
    ) -> KanjiIndexEntry {
        KanjiIndexEntry(
            id: id,
            primaryMeaning: meaning,
            primaryReading: "",
            strokeCount: 1,
            jlptLevel: jlpt,
            joyoGrade: joyo,
            listIndex: listIndex
        )
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

    @Test("A kanji without a JLPT level lands in Other kanji, which is dropped when empty")
    func unleveledGroup() {
        let withGap = mixedEntries + [indexEntry("〆", jlpt: nil, joyo: nil, listIndex: 20)]

        let sections = KanjiBrowseGrouping.sections(from: withGap, system: .jlpt)
        let withoutGap = KanjiBrowseGrouping.sections(from: mixedEntries, system: .jlpt)

        #expect(sections.last?.title == KanjiBrowseGrouping.unleveledTitle)
        #expect(sections.last?.entries.map(\.id) == ["〆"])
        #expect(!withoutGap.contains { $0.title == KanjiBrowseGrouping.unleveledTitle })
    }

    @Test("Jōyō browse runs grade 1 to Secondary, then Name kanji for ungraded kanji")
    func joyoSectionsEndWithNameKanji() {
        let sections = KanjiBrowseGrouping.sections(from: mixedEntries, system: .joyo)

        #expect(sections.map(\.title) == ["1st grade", "2nd grade", "Secondary school", "Name kanji"])
        #expect(sections.last?.entries.map(\.id) == ["彦"])
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

    @Test("The bundled index groups all 2,383 kanji, with 247 Name kanji in Jōyō mode")
    func bundledIndexCoversEveryKanji() throws {
        let store = BundledKanjiContentStore()
        let entries = try store.indexEntries()

        let jlpt = KanjiBrowseGrouping.sections(from: entries, system: .jlpt)
        let joyo = KanjiBrowseGrouping.sections(from: entries, system: .joyo)

        #expect(entries.count == 2_383)
        #expect(entries.map(\.listIndex) == entries.map(\.listIndex).sorted())
        #expect(jlpt.reduce(0) { $0 + $1.entries.count } == 2_383)
        #expect(joyo.reduce(0) { $0 + $1.entries.count } == 2_383)
        #expect(joyo.last?.title == KanjiBrowseGrouping.nameKanjiTitle)
        #expect(joyo.last?.entries.count == 247)
    }
}
