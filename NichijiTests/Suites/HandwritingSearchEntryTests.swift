import Testing
@testable import Nichiji

/*---------------------handwriting-search-entry-tests----------------------*/

@MainActor
@Suite("Handwriting Search Entry Tests")
struct HandwritingSearchEntryTests {
    private func makeModel() -> HandwritingSearchModel {
        HandwritingSearchModel { HandwritingTemplateMatcher(templates: []) }
    }

    @Test("A locked tap opens the paywall and never makes a model")
    func lockedOpensPaywall() {
        var made = 0
        let entry = HandwritingSearchEntry.open(access: .locked, existing: nil) {
            made += 1
            return makeModel()
        }

        guard case .paywall(let feature) = entry else {
            Issue.record("Expected the paywall")
            return
        }
        #expect(feature == .handwritingSearch)
        #expect(made == 0)
    }

    @Test("A Pro tap, bought or dev unlocked, opens the pad")
    func unlockedOpensPad() {
        for access in [ProAccess.purchased, ProAccess(isDevUnlocked: true)] {
            let created = makeModel()
            let entry = HandwritingSearchEntry.open(access: access, existing: nil) { created }

            guard case .pad(let model) = entry else {
                Issue.record("Expected the pad")
                continue
            }
            #expect(model === created)
        }
    }

    @Test("A later Pro tap reuses the existing model")
    func reusesModel() {
        let existing = makeModel()
        let entry = HandwritingSearchEntry.open(access: .purchased, existing: existing) {
            Issue.record("A second model was made")
            return makeModel()
        }

        guard case .pad(let model) = entry else {
            Issue.record("Expected the pad")
            return
        }
        #expect(model === existing)
    }
}

/*---------------------handwriting-search-layout-tests---------------------*/

@Suite("Handwriting Search Layout Tests")
struct HandwritingSearchLayoutTests {
    @Test("Every control is at least 44 pt")
    func hitTargets() {
        let sides = [
            HandwritingSearchLayout.buttonMinHeight,
            HandwritingSearchLayout.controlMinSide,
            HandwritingSearchLayout.tileMinSide,
            HandwritingSearchLayout.padMaxSide
        ]

        #expect(sides.allSatisfy { $0 >= 44 })
        #expect(HandwritingSearchLayout.tileCount == 5)
    }

    @Test("VoiceOver labels name the match and the pad's strokes")
    func accessibilityLabels() {
        #expect(HandwritingSearchCopy.tileLabel(kanji: "学") == "Search for 学")
        #expect(HandwritingSearchCopy.padLabel(strokeCount: 1) == "Drawing pad, 1 stroke")
        #expect(HandwritingSearchCopy.padLabel(strokeCount: 3) == "Drawing pad, 3 strokes")
        #expect(HandwritingSearchCopy.buttonTitle == "Draw a kanji to search")
    }
}
