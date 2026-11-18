import Foundation
import Observation

/*---------------------------------state----------------------------------*/

public enum PhotoLookupState: Equatable, Sendable {
    /// No photo yet.
    case empty
    case reading
    case found
    /// The photo read fine but held no kanji from the dictionary.
    case noKanji
    case failed
}

/// What one photo read hands back: the kanji found and the meaning each tile shows.
struct PhotoReadOutcome: Sendable {
    let scanned: [ScannedKanji]
    let meanings: [String: String]
}

/*---------------------------------model----------------------------------*/

/// One photo lookup: read the text, keep the bundled kanji, and split them into new to the learner and already started.
@MainActor
@Observable
final class PhotoLookupModel {
    private(set) var state: PhotoLookupState = .empty
    private(set) var photoData: Data?
    /// Each kanji found with its boxes, in reading order.
    private(set) var scanned: [ScannedKanji] = []
    private(set) var startedIDs: Set<String> = []
    /// The short meaning each kanji found shows on its tile.
    private(set) var meanings: [String: String] = [:]
    /// The "New only" filter. Off by default.
    var showsNewOnly = false

    private var generation = 0
    private let reader: any PhotoTextReader
    private let contentStore: any KanjiContentStore
    private let learnerStore: (any LearnerStore)?

    init(reader: any PhotoTextReader, contentStore: any KanjiContentStore, learnerStore: (any LearnerStore)?) {
        self.reader = reader
        self.contentStore = contentStore
        self.learnerStore = learnerStore
    }

    var kanji: [String] { scanned.map(\.id) }

    /// Highlights need boxes, which only a Vision read gives.
    var hasBoxes: Bool { scanned.contains { !$0.boxes.isEmpty } }

    var newCount: Int { kanji.filter { !startedIDs.contains($0) }.count }

    var learnedCount: Int { kanji.count - newCount }

    /// What the grid shows: every kanji found, or only the unstarted ones with the filter on.
    var visibleKanji: [String] {
        showsNewOnly ? kanji.filter { !startedIDs.contains($0) } : kanji
    }

    /// The filter has nothing to offer when every kanji found is already started.
    var filterHidesEverything: Bool {
        state == .found && showsNewOnly && visibleKanji.isEmpty
    }

    /// Reads a photo. A newer photo cancels the meaning of an older read still running.
    func lookUp(imageData: Data) async {
        generation += 1
        let mine = generation
        photoData = imageData
        scanned = []
        meanings = [:]
        state = .reading

        let reader = reader
        let contentStore = contentStore
        let outcome: Result<PhotoReadOutcome, Error> = await Task.detached(priority: .userInitiated) { () async -> Result<PhotoReadOutcome, Error> in
            do {
                let reading = try await reader.read(imageData: imageData)
                let entries = try contentStore.indexEntries()
                let found = PhotoKanjiExtractor.scanned(reading, bundled: Set(entries.map(\.id)))
                let foundIDs = Set(found.map(\.id))
                let meanings = Dictionary(
                    entries.filter { foundIDs.contains($0.id) }.map { ($0.id, $0.primaryMeaning) },
                    uniquingKeysWith: { first, _ in first }
                )
                return .success(PhotoReadOutcome(scanned: found, meanings: meanings))
            } catch {
                return .failure(error)
            }
        }.value
        guard mine == generation else { return }

        switch outcome {
        case .success(let read):
            startedIDs = (try? await learnerStore?.nonNewKanjiIDs()) ?? []
            guard mine == generation else { return }
            scanned = read.scanned
            meanings = read.meanings
            state = read.scanned.isEmpty ? .noKanji : .found
        case .failure:
            state = .failed
        }
    }

    /// Crops the photo to a normalized frame and reads that part alone. The crop becomes the photo and its results replace the old ones. Returns false and changes nothing when the photo cannot be cropped.
    @discardableResult
    func crop(to region: CGRect) async -> Bool {
        guard let data = photoData else { return false }
        let mine = generation
        let cropped = await Task.detached(priority: .userInitiated) {
            PhotoCropper.crop(imageData: data, to: region)
        }.value
        guard mine == generation, let cropped else { return false }
        await lookUp(imageData: cropped)
        return true
    }

    /// Back to the live camera. A read still running drops its result, and the "New to you" choice stays.
    func retake() {
        generation += 1
        photoData = nil
        scanned = []
        meanings = [:]
        startedIDs = []
        state = .empty
    }
}

/*---------------------------------entry----------------------------------*/

/// What a tap on "Scan a kanji" does.
enum PhotoLookupEntry: Equatable {
    case paywall(ProFeature)
    case sheet

    static func open(access: ProAccess) -> PhotoLookupEntry {
        access.allows(.photoLookup) ? .sheet : .paywall(.photoLookup)
    }
}

/// One push of the scan screen onto the Dictionary stack. Each open gets a fresh model, so a new photo never shows the last one's grid.
struct PhotoLookupPresentation: Identifiable, Hashable {
    let model: PhotoLookupModel

    var id: ObjectIdentifier { ObjectIdentifier(model) }

    static func == (lhs: PhotoLookupPresentation, rhs: PhotoLookupPresentation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
