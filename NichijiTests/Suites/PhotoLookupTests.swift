import AVFoundation
import Foundation
import Testing
@testable import Nichiji

/*--------------------------photo-lookup-tests----------------------------*/

private struct StubPhotoReader: PhotoTextReader {
    var reading: PhotoTextReading?

    func read(imageData: Data) async throws -> PhotoTextReading {
        guard let reading else { throw PhotoTextError.unreadableImage }
        return reading
    }
}

/// Holds a read until the test opens it, so a retake can land mid-read.
private actor ReadGate {
    private var waiter: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiter = $0 }
    }

    func open() {
        isOpen = true
        waiter?.resume()
        waiter = nil
    }
}

private struct GatedPhotoReader: PhotoTextReader {
    let gate: ReadGate
    let reading: PhotoTextReading

    func read(imageData: Data) async throws -> PhotoTextReading {
        await gate.wait()
        return reading
    }
}

@Suite("Photo Lookup Text Rules")
struct PhotoLookupTextTests {
    private let bundled: Set<String> = ["日", "本", "語", "学"]

    @Test("Vision text stands when it reads four characters or more")
    func visionStands() {
        let reading = PhotoTextReading(visionLines: ["日本語", "学"], liveTextLines: ["語語語語"])

        #expect(!reading.visionIsSparse)
        #expect(reading.combinedLines == ["日本語", "学"])
    }

    @Test("Live Text stands in when Vision reads under four characters")
    func liveTextStandsIn() {
        let reading = PhotoTextReading(visionLines: ["日本"], liveTextLines: ["日本語学"])

        #expect(reading.visionIsSparse)
        #expect(reading.combinedLines == ["日本語学"])
    }

    @Test("A sparse Vision read stays when Live Text found nothing")
    func sparseVisionStaysWithoutLiveText() {
        let reading = PhotoTextReading(visionLines: ["日"], liveTextLines: [])

        #expect(reading.combinedLines == ["日"])
    }

    @Test("Live Text only runs for a sparse Vision read")
    func liveTextGate() {
        #expect(PhotoTextReading.needsLiveText(visionLines: []))
        #expect(PhotoTextReading.needsLiveText(visionLines: ["abc"]))
        #expect(!PhotoTextReading.needsLiveText(visionLines: ["abcd"]))
    }

    private func scanned(_ reading: PhotoTextReading) -> [ScannedKanji] {
        PhotoKanjiExtractor.scanned(reading, bundled: bundled)
    }

    private func box(_ x: Double) -> CGRect {
        CGRect(x: x, y: 0.1, width: 0.1, height: 0.2)
    }

    @Test("Only bundled kanji are kept, once each, in order of first appearance")
    func extractsBundledKanjiOnce() {
        let found = scanned(PhotoTextReading(visionLines: ["本日は日本語", "OPEN 学 日", "ひらがな"], liveTextLines: []))

        #expect(found.map(\.id) == ["本", "日", "語", "学"])
    }

    @Test("Text with no bundled kanji finds none")
    func noKanji() {
        #expect(scanned(PhotoTextReading(visionLines: ["EXIT", "ひらがな"], liveTextLines: [])).isEmpty)
        #expect(scanned(PhotoTextReading(visionLines: [], liveTextLines: [])).isEmpty)
    }

    @Test("A kanji that appears twice carries both boxes in reading order")
    func repeatedKanjiKeepsEveryBox() {
        let reading = PhotoTextReading(
            visionLines: ["日本", "語日"],
            liveTextLines: [],
            visionBoxes: [[box(0.1), box(0.2)], [box(0.3), box(0.4)]]
        )

        let found = scanned(reading)

        #expect(found.map(\.id) == ["日", "本", "語"])
        #expect(found[0].boxes == [box(0.1), box(0.4)])
        #expect(found[1].boxes == [box(0.2)])
        #expect(found[2].boxes == [box(0.3)])
    }

    @Test("Characters that are not kept still use up their box slot")
    func skippedCharactersKeepBoxesAligned() {
        let reading = PhotoTextReading(
            visionLines: ["A日"],
            liveTextLines: [],
            visionBoxes: [[box(0.1), box(0.2)]]
        )

        #expect(scanned(reading) == [ScannedKanji(id: "日", boxes: [box(0.2)])])
    }

    @Test("A character Vision could not box keeps its kanji but adds no box")
    func missingBoxIsSkipped() {
        let reading = PhotoTextReading(
            visionLines: ["日本"],
            liveTextLines: [],
            visionBoxes: [[nil, box(0.2)]]
        )

        #expect(scanned(reading) == [
            ScannedKanji(id: "日", boxes: []),
            ScannedKanji(id: "本", boxes: [box(0.2)])
        ])
    }

    @Test("Short or missing box rows never crash and leave boxes empty")
    func shortBoxRows() {
        let reading = PhotoTextReading(visionLines: ["日本", "語"], liveTextLines: [], visionBoxes: [[box(0.1)]])

        #expect(scanned(reading) == [
            ScannedKanji(id: "日", boxes: [box(0.1)]),
            ScannedKanji(id: "本", boxes: []),
            ScannedKanji(id: "語", boxes: [])
        ])
    }

    @Test("A Live Text read finds its kanji with no boxes")
    func liveTextHasNoBoxes() {
        let reading = PhotoTextReading(
            visionLines: ["日"],
            liveTextLines: ["日本語"],
            visionBoxes: [[box(0.1)]]
        )

        #expect(reading.usesLiveText)
        #expect(scanned(reading) == [
            ScannedKanji(id: "日", boxes: []),
            ScannedKanji(id: "本", boxes: []),
            ScannedKanji(id: "語", boxes: [])
        ])
    }

    @Test("A sparse Vision read with nothing from Live Text keeps Vision's boxes")
    func sparseVisionWithoutLiveTextKeepsBoxes() {
        let reading = PhotoTextReading(visionLines: ["日"], liveTextLines: [], visionBoxes: [[box(0.1)]])

        #expect(!reading.usesLiveText)
        #expect(scanned(reading) == [ScannedKanji(id: "日", boxes: [box(0.1)])])
    }

    @Test("Vision's bottom-left box flips to a top-left origin")
    func flipsVisionBox() {
        let flipped = PhotoBox.topLeftOrigin(fromVision: CGRect(x: 0.2, y: 0.1, width: 0.3, height: 0.2))

        #expect(abs(flipped.minX - 0.2) < 1e-9)
        #expect(abs(flipped.minY - 0.7) < 1e-9)
        #expect(abs(flipped.width - 0.3) < 1e-9)
        #expect(abs(flipped.height - 0.2) < 1e-9)
    }
}

@MainActor
@Suite("Photo Lookup Model Tests")
struct PhotoLookupModelTests {
    private func makeModel(
        reading: PhotoTextReading?,
        started: [String: StudyStage] = [:]
    ) -> PhotoLookupModel {
        let learner = TestLearnerStore()
        learner.progress = started
        return PhotoLookupModel(
            reader: StubPhotoReader(reading: reading),
            contentStore: TestKanjiContentStore(entries: SeedKanjiDataset.entries),
            learnerStore: learner
        )
    }

    @Test("A photo with bundled kanji lists them")
    func listsKanji() async {
        let model = makeModel(reading: PhotoTextReading(visionLines: ["日本一", "川"], liveTextLines: []))

        await model.lookUp(imageData: Data([1]))

        #expect(model.state == .found)
        #expect(model.kanji == ["日", "一", "川"])
        #expect(model.photoData == Data([1]))
    }

    @Test("The model keeps each kanji's boxes and reports them")
    func modelKeepsBoxes() async {
        let box = CGRect(x: 0.1, y: 0.1, width: 0.1, height: 0.1)
        let model = makeModel(reading: PhotoTextReading(visionLines: ["日"], liveTextLines: [], visionBoxes: [[box]]))

        await model.lookUp(imageData: Data([1]))

        #expect(model.scanned == [ScannedKanji(id: "日", boxes: [box])])
        #expect(model.hasBoxes)
    }

    @Test("A Live Text read lists kanji but offers no boxes")
    func liveTextOffersNoBoxes() async {
        let model = makeModel(reading: PhotoTextReading(visionLines: [], liveTextLines: ["日本一"]))

        await model.lookUp(imageData: Data([1]))

        #expect(model.kanji == ["日", "一"])
        #expect(!model.hasBoxes)
    }

    @Test("A photo with no bundled kanji ends as noKanji")
    func noKanjiState() async {
        let model = makeModel(reading: PhotoTextReading(visionLines: ["EXIT"], liveTextLines: []))

        await model.lookUp(imageData: Data([1]))

        #expect(model.state == .noKanji)
        #expect(model.kanji.isEmpty)
    }

    @Test("An unreadable photo fails")
    func failedState() async {
        let model = makeModel(reading: nil)

        await model.lookUp(imageData: Data([1]))

        #expect(model.state == .failed)
    }

    @Test("New to you is off by default and hides started kanji when on")
    func newToYouFilter() async {
        let model = makeModel(
            reading: PhotoTextReading(visionLines: ["日山一"], liveTextLines: []),
            started: ["日": .learning, "山": .new]
        )
        await model.lookUp(imageData: Data([1]))

        #expect(!model.showsNewOnly)
        #expect(model.visibleKanji == ["日", "山", "一"])

        model.showsNewOnly = true
        #expect(model.visibleKanji == ["山", "一"])
        #expect(!model.filterHidesEverything)
    }

    @Test("The filter reports when every kanji found is already started")
    func filterHidesEverything() async {
        let model = makeModel(
            reading: PhotoTextReading(visionLines: ["日山"], liveTextLines: []),
            started: ["日": .known, "山": .familiar]
        )
        await model.lookUp(imageData: Data([1]))
        model.showsNewOnly = true

        #expect(model.visibleKanji.isEmpty)
        #expect(model.filterHidesEverything)
    }

    @Test("A locked tap opens the paywall and an unlocked tap opens the sheet")
    func entryGate() {
        #expect(PhotoLookupEntry.open(access: .locked) == .paywall(.photoLookup))
        #expect(PhotoLookupEntry.open(access: .purchased) == .sheet)
        #expect(PhotoLookupEntry.open(access: ProAccess(isDevUnlocked: true)) == .sheet)
    }

    @Test("Found counts read naturally")
    func foundCount() {
        #expect(PhotoLookupCopy.foundCount(1) == "1 kanji found")
        #expect(PhotoLookupCopy.foundCount(12) == "12 kanji found")
    }

    @Test("Retake returns to the camera from every result and keeps New to you", arguments: [
        PhotoTextReading(visionLines: ["日本"], liveTextLines: []),
        PhotoTextReading(visionLines: ["EXIT"], liveTextLines: []),
        nil
    ])
    func retakeClearsResult(reading: PhotoTextReading?) async {
        let model = makeModel(reading: reading)
        model.showsNewOnly = true
        await model.lookUp(imageData: Data([1]))
        #expect(model.state != .empty)

        model.retake()

        #expect(model.state == .empty)
        #expect(model.photoData == nil)
        #expect(model.kanji.isEmpty)
        #expect(model.visibleKanji.isEmpty)
        #expect(model.showsNewOnly)
    }

    @Test("A read that finishes after a retake is dropped")
    func retakeDropsInFlightRead() async {
        let gate = ReadGate()
        let model = PhotoLookupModel(
            reader: GatedPhotoReader(gate: gate, reading: PhotoTextReading(visionLines: ["日本"], liveTextLines: [])),
            contentStore: TestKanjiContentStore(entries: SeedKanjiDataset.entries),
            learnerStore: TestLearnerStore()
        )
        let read = Task { await model.lookUp(imageData: Data([1])) }
        for _ in 0..<100 where model.state != .reading {
            await Task.yield()
        }
        #expect(model.state == .reading)

        model.retake()
        await gate.open()
        await read.value

        #expect(model.state == .empty)
        #expect(model.kanji.isEmpty)
        #expect(model.photoData == nil)
    }

    @Test("Camera access maps every status, and no camera wins")
    func cameraAccess() {
        #expect(CameraAccess.from(status: .authorized, hasCamera: true) == .authorized)
        #expect(CameraAccess.from(status: .notDetermined, hasCamera: true) == .notDetermined)
        #expect(CameraAccess.from(status: .denied, hasCamera: true) == .denied)
        #expect(CameraAccess.from(status: .restricted, hasCamera: true) == .denied)
        #expect(CameraAccess.from(status: .authorized, hasCamera: false) == .unavailable)
        #expect(CameraAccess.from(status: .denied, hasCamera: false) == .unavailable)
    }
}
