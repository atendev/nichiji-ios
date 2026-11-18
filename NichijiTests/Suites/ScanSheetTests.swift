import CoreGraphics
import Foundation
import Testing
@testable import Nichiji

/*---------------------------scan-sheet-tests-----------------------------*/

private let screen: CGFloat = 844

@Suite("Scan Sheet Geometry Tests")
struct ScanSheetGeometryTests {
    @Test("Peek is 112 pt, half is 456 pt and full fills the screen")
    func restHeights() {
        #expect(ScanSheetGeometry.height(of: .peek, screenHeight: screen) == 112)
        #expect(ScanSheetGeometry.height(of: .half, screenHeight: screen) == 456)
        #expect(ScanSheetGeometry.height(of: .full, screenHeight: screen) == 844)
    }

    @Test("Half never passes a short screen")
    func halfStaysOnScreen() {
        #expect(ScanSheetGeometry.height(of: .half, screenHeight: 400) == 400)
    }

    @Test("A drag follows the finger and stays between peek and full")
    func dragHeightClamps() {
        #expect(ScanSheetGeometry.dragHeight(from: .half, translation: -100, screenHeight: screen) == 556)
        #expect(ScanSheetGeometry.dragHeight(from: .half, translation: 900, screenHeight: screen) == 112)
        #expect(ScanSheetGeometry.dragHeight(from: .half, translation: -900, screenHeight: screen) == 844)
    }

    @Test("A drag ending near a state settles there")
    func snapsToNearest() {
        #expect(ScanSheetGeometry.snap(from: .half, endHeight: 470, screenHeight: screen) == .half)
        #expect(ScanSheetGeometry.snap(from: .half, endHeight: 200, screenHeight: screen) == .peek)
        #expect(ScanSheetGeometry.snap(from: .half, endHeight: 700, screenHeight: screen) == .full)
    }

    @Test("A drag over 40 pt always moves one state")
    func dragOverFortyMoves() {
        #expect(ScanSheetGeometry.snap(from: .half, endHeight: 456 + 41, screenHeight: screen) == .full)
        #expect(ScanSheetGeometry.snap(from: .half, endHeight: 456 - 41, screenHeight: screen) == .peek)
        #expect(ScanSheetGeometry.snap(from: .peek, endHeight: 112 + 41, screenHeight: screen) == .half)
        #expect(ScanSheetGeometry.snap(from: .full, endHeight: 844 - 41, screenHeight: screen) == .half)
    }

    @Test("A drag of 40 pt or less can settle back where it began")
    func shortDragReturns() {
        #expect(ScanSheetGeometry.snap(from: .half, endHeight: 456 + 40, screenHeight: screen) == .half)
        #expect(ScanSheetGeometry.snap(from: .half, endHeight: 456 - 40, screenHeight: screen) == .half)
    }

    @Test("The photo is full size at peek and 0.8 scale, 100 pt up at half")
    func photoPose() {
        let peek = ScanSheetGeometry.photoPose(sheetHeight: 112)

        #expect(abs(peek.scale - 1) < 0.0001)
        #expect(peek.lift == 0)
        #expect(ScanSheetGeometry.photoPose(sheetHeight: 456) == ScanPhotoPose(scale: 0.8, lift: 100))
    }

    @Test("The photo follows the sheet halfway between peek and half, and holds past half")
    func photoPoseBetween() {
        let middle = ScanSheetGeometry.photoPose(sheetHeight: (112 + 456) / 2)

        #expect(abs(middle.scale - 0.9) < 0.0001)
        #expect(abs(middle.lift - 50) < 0.0001)
        #expect(ScanSheetGeometry.photoPose(sheetHeight: 700) == ScanPhotoPose(scale: 0.8, lift: 100))
    }

    @Test("The top corners are 20 pt and flatten at full")
    func cornerRadius() {
        #expect(ScanSheetGeometry.cornerRadius(forHeight: 456, screenHeight: screen) == 20)
        #expect(ScanSheetGeometry.cornerRadius(forHeight: 844, screenHeight: screen) == 0)
        #expect(ScanSheetGeometry.cornerRadius(forHeight: 824, screenHeight: screen) == 10)
    }

    @Test("The header follows the height thresholds")
    func presentation() {
        #expect(ScanSheetGeometry.presentation(forHeight: 112, screenHeight: screen) == .peek)
        #expect(ScanSheetGeometry.presentation(forHeight: 456, screenHeight: screen) == .half)
        #expect(ScanSheetGeometry.presentation(forHeight: 844, screenHeight: screen) == .full)
    }

    @Test("The sheet rises 1.9 s after the read began, and at once when that has passed")
    func riseDelay() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)

        #expect(abs(ScanSheetGeometry.riseDelay(readStart: start, now: start.addingTimeInterval(0.4)) - 1.5) < 0.0001)
        #expect(ScanSheetGeometry.riseDelay(readStart: start, now: start.addingTimeInterval(3)) == 0)
    }

    @Test("Scrolling the grid past a few points pulls the sheet up")
    func scrollPull() {
        #expect(!ScanSheetGeometry.scrollPullsToFull(offset: 0))
        #expect(ScanSheetGeometry.scrollPullsToFull(offset: 12))
    }

    @Test("The screen's height counts both safe-area insets")
    func screenMetrics() {
        let metrics = ScanScreenMetrics(size: CGSize(width: 390, height: 751), topInset: 59, bottomInset: 34)

        #expect(metrics.screenHeight == 844)
    }
}

@MainActor
@Suite("Scan Sheet Model Tests")
struct ScanSheetModelTests {
    private func makeSheet() -> ScanSheetModel {
        let sheet = ScanSheetModel()
        sheet.update(metrics: ScanScreenMetrics(size: CGSize(width: 390, height: 751), topInset: 59, bottomInset: 34))
        return sheet
    }

    @Test("The sheet has no state until it rises, then rests at half")
    func rises() {
        let sheet = makeSheet()

        #expect(!sheet.isVisible)
        #expect(sheet.height == 0)
        #expect(sheet.photoPose == ScanPhotoPose(scale: 1, lift: 0))

        sheet.rise(reduceMotion: true)

        #expect(sheet.state == .half)
        #expect(sheet.height == 456)
    }

    @Test("A second rise leaves a sheet where the reader put it")
    func riseKeepsState() {
        let sheet = makeSheet()
        sheet.rise(reduceMotion: true)
        sheet.move(to: .full, reduceMotion: true)

        sheet.rise(reduceMotion: true)

        #expect(sheet.state == .full)
        #expect(sheet.isFull)
    }

    @Test("A drag shows the finger's height and ends in a state")
    func dragAndSettle() {
        let sheet = makeSheet()
        sheet.rise(reduceMotion: true)

        sheet.drag(translation: -60)
        #expect(sheet.height == 516)

        sheet.endDrag(translation: -60, reduceMotion: true)
        #expect(sheet.state == .full)
        #expect(sheet.dragHeight == nil)
        #expect(sheet.height == 844)
    }

    @Test("Moves and steps change one state and stop at the ends")
    func stepsAndMoves() {
        let sheet = makeSheet()
        sheet.move(to: .full, reduceMotion: true)
        #expect(sheet.state == nil)

        sheet.rise(reduceMotion: true)
        sheet.step(up: false, reduceMotion: true)
        #expect(sheet.state == .peek)
        sheet.step(up: false, reduceMotion: true)
        #expect(sheet.state == .peek)
        sheet.step(up: true, reduceMotion: true)
        sheet.step(up: true, reduceMotion: true)
        sheet.step(up: true, reduceMotion: true)
        #expect(sheet.state == .full)
    }

    @Test("Scrolling pulls only the half sheet to full, and never mid-drag")
    func pullToFull() {
        let sheet = makeSheet()
        sheet.rise(reduceMotion: true)
        sheet.drag(translation: 10)
        sheet.pullToFull(reduceMotion: true)
        #expect(sheet.state == .half)

        sheet.endDrag(translation: 0, reduceMotion: true)
        sheet.pullToFull(reduceMotion: true)
        #expect(sheet.state == .full)

        sheet.move(to: .peek, reduceMotion: true)
        sheet.pullToFull(reduceMotion: true)
        #expect(sheet.state == .peek)
    }

    @Test("Reset takes the sheet away and the photo back to full size")
    func resets() {
        let sheet = makeSheet()
        sheet.rise(reduceMotion: true)
        sheet.drag(translation: 20)

        sheet.reset()

        #expect(!sheet.isVisible)
        #expect(sheet.dragHeight == nil)
        #expect(sheet.photoPose == ScanPhotoPose(scale: 1, lift: 0))
    }

    @Test("Reduced motion gives no animation")
    func reducedMotion() {
        #expect(ScanSheetModel.animation(reduceMotion: true) == nil)
        #expect(ScanSheetModel.animation(reduceMotion: false) != nil)
    }
}

/*-------------------------scan-results-tests-----------------------------*/

private struct ScanStubReader: PhotoTextReader {
    let reading: PhotoTextReading

    func read(imageData: Data) async throws -> PhotoTextReading { reading }
}

@MainActor
@Suite("Scan Results Counts Tests")
struct ScanResultsCountsTests {
    private func found(started: [String: StudyStage] = [:]) async -> PhotoLookupModel {
        let learner = TestLearnerStore()
        learner.progress = started
        let model = PhotoLookupModel(
            reader: ScanStubReader(reading: PhotoTextReading(visionLines: ["日山一"], liveTextLines: [])),
            contentStore: TestKanjiContentStore(entries: SeedKanjiDataset.entries),
            learnerStore: learner
        )
        await model.lookUp(imageData: Data([1]))
        return model
    }

    @Test("Each kanji found carries the bundled short meaning")
    func meanings() async {
        let model = await found()

        for id in model.kanji {
            let expected = SeedKanjiDataset.entries.first { $0.id == id }?.primaryMeaning
            #expect(model.meanings[id] == expected)
        }
        #expect(model.meanings.count == model.kanji.count)
    }

    @Test("New and learned counts split what was found")
    func counts() async {
        let model = await found(started: ["日": .learning, "山": .new])

        #expect(model.newCount == 2)
        #expect(model.learnedCount == 1)
    }

    @Test("A retake clears the meanings")
    func retakeClearsMeanings() async {
        let model = await found()

        model.retake()

        #expect(model.meanings.isEmpty)
    }

    @Test("The sheet's words follow the design")
    func copy() {
        #expect(PhotoLookupCopy.subtitle(new: 8, learned: 4, newOnly: false) == "8 new to you \u{00B7} 4 learned")
        #expect(PhotoLookupCopy.subtitle(new: 8, learned: 4, newOnly: true) == "Showing 8 new")
        #expect(PhotoLookupCopy.newLine(8) == "8 new to you")
        #expect(PhotoLookupCopy.backTitle == "Scan results")
    }
}
