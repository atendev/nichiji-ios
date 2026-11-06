import Foundation
import Testing
@testable import Nichiji

/*------------------------------known-controls----------------------------*/

@Suite("Known Kanji Control Tests")
struct KnownKanjiControlTests {
    @Test("I know this shows for new kanji only, and Not known after all for marked ones")
    func choiceByStage() {
        #expect(KnownKanjiControl.choice(stage: nil, isDeclared: false) == .declare)
        #expect(KnownKanjiControl.choice(stage: .new, isDeclared: false) == .declare)
        #expect(KnownKanjiControl.choice(stage: .learning, isDeclared: false) == nil)
        #expect(KnownKanjiControl.choice(stage: .familiar, isDeclared: false) == nil)
        #expect(KnownKanjiControl.choice(stage: .known, isDeclared: false) == nil)
        #expect(KnownKanjiControl.choice(stage: .known, isDeclared: true) == .undeclare)
    }

    @Test("The onboarding step offers the picker only when the services are there")
    func chooseButton() {
        #expect(KnownKanjiStepView.showsChooseButton(hasServices: true))
        #expect(!KnownKanjiStepView.showsChooseButton(hasServices: false))
    }

    @Test("The You caption counts known kanji apart once there are any")
    func youCaption() {
        #expect(YouCopy.learnedCaption(learned: 16, known: 0) == "16 learned")
        #expect(YouCopy.learnedCaption(learned: 16, known: 40) == "16 learned · 40 known")
    }
}
