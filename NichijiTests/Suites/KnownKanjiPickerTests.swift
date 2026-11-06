import Foundation
import Testing
@testable import Nichiji

/*------------------------------known-picker------------------------------*/

@Suite("Known Kanji Picker Tests")
struct KnownKanjiPickerTests {
    private let n5 = KanjiBrowseSection(
        id: JLPTLevel.n5.rawValue,
        title: "N5",
        entries: [
            StatsFixtures.entry("日", jlpt: .n5, joyo: .grade1, listIndex: 0),
            StatsFixtures.entry("一", jlpt: .n5, joyo: .grade1, listIndex: 1),
            StatsFixtures.entry("二", jlpt: .n5, joyo: .grade1, listIndex: 2)
        ]
    )

    private let n4 = KanjiBrowseSection(
        id: JLPTLevel.n4.rawValue,
        title: "N4",
        entries: [StatsFixtures.entry("会", jlpt: .n4, joyo: .grade2, listIndex: 3)]
    )

    @Test("Studied kanji are disabled, and a declared kanji stays enabled")
    func disabledSet() {
        var model = KnownKanjiPickerModel(sections: [n5, n4], declared: ["会"], studied: ["日", "会"])

        #expect(!model.isEnabled("日"))
        #expect(model.isEnabled("一"))
        #expect(model.isEnabled("会"))
        model.toggle("日")
        #expect(!model.isSelected("日"))
    }

    @Test("Done never undeclares kanji outside the groups on screen")
    func outOfViewKanjiStay() {
        var model = KnownKanjiPickerModel(sections: [n5], declared: ["会"], studied: [])

        model.toggle("一")

        let changes = model.pendingChanges
        #expect(changes.declare == ["一"])
        #expect(changes.undeclare.isEmpty)
        #expect(model.selectedCount == 2)
    }

    @Test("Turning a declared kanji off undeclares it")
    func deselectUndeclares() {
        var model = KnownKanjiPickerModel(sections: [n4], declared: ["会"], studied: [])

        model.toggle("会")

        #expect(model.pendingChanges.undeclare == ["会"])
    }

    @Test("Select all acts on enabled rows only and the button reads Clear all once they are all on")
    func groupButton() {
        var model = KnownKanjiPickerModel(sections: [n5], declared: [], studied: ["日"])

        #expect(model.showsGroupButton(for: n5))
        #expect(!model.isAllSelected(in: n5))
        model.setAll(in: n5, selected: true)
        #expect(model.isAllSelected(in: n5))
        #expect(model.selectedCount(in: n5) == 2)
        #expect(!model.isSelected("日"))
        model.setAll(in: n5, selected: false)
        #expect(model.selectedCount == 0)
    }

    @Test("A group with nothing to mark hides its button")
    func emptyGroupHidesButton() {
        let learned = KanjiBrowseSection(id: "x", title: "X", entries: [StatsFixtures.entry("日", jlpt: .n5, joyo: .grade1)])
        let model = KnownKanjiPickerModel(sections: [learned], declared: [], studied: ["日"])

        #expect(!model.showsGroupButton(for: learned))
        #expect(!model.isAllSelected(in: learned))
    }

    @Test("Search picks outside the visible groups count and commit is idempotent")
    func commitIsIdempotent() {
        var model = KnownKanjiPickerModel(sections: [n5], declared: [], studied: [])

        model.toggle("本")
        #expect(model.selectedCount == 1)
        #expect(model.pendingChanges.declare == ["本"])
        model.markCommitted()
        #expect(model.pendingChanges.declare.isEmpty)
        #expect(model.pendingChanges.undeclare.isEmpty)
    }

    @Test("Typed kanji show exactly those kanji, anything else searches readings and meanings")
    func queryRouting() {
        let index = DictionarySearchIndex(
            kanjiIndex: SearchFixtures.kanjiIndex,
            records: SearchFixtures.records,
            words: SearchFixtures.words
        )

        #expect(KnownKanjiPickerModel.results(for: "日月", in: index).map(\.id) == ["日", "月"])
        #expect(KnownKanjiPickerModel.results(for: "日 test", in: index).map(\.id) == ["日"])
        #expect(KnownKanjiPickerModel.results(for: "moon", in: index).map(\.id).contains("月"))
    }

    @Test("Result labels name the level in the learner's system")
    func levelLabels() {
        let leveled = StatsFixtures.entry("日", jlpt: .n5, joyo: .grade1)
        let bare = StatsFixtures.entry("凜", jlpt: nil, joyo: nil)

        #expect(KnownKanjiPickerModel.levelLabel(for: leveled, system: .jlpt) == JLPTLevel.n5.codeLabel)
        #expect(KnownKanjiPickerModel.levelLabel(for: bare, system: .jlpt) == "No level")
        #expect(KnownKanjiPickerModel.levelLabel(for: leveled, system: .joyo) == JoyoGrade.grade1.codeLabel)
        #expect(KnownKanjiPickerModel.levelLabel(for: bare, system: .joyo) == "Name kanji")
    }

    @Test("Onboarding lists the chosen level, Settings lists every group")
    func scopes() {
        let preferences = LearnerPreferencesSnapshot(selectedJLPTLevel: .n4)

        #expect(KnownKanjiScope.activeLevel.sections(from: [n5, n4], preferences: preferences).map(\.id) == [n4.id])
        #expect(KnownKanjiScope.allLevels.sections(from: [n5, n4], preferences: preferences).map(\.id) == [n5.id, n4.id])
    }
}
