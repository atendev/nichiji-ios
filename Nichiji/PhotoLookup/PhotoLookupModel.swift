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

/*---------------------------------model----------------------------------*/

/// One photo lookup: read the text, keep the bundled kanji, and split them into new to the learner and already started.
@MainActor
@Observable
final class PhotoLookupModel {
    private(set) var state: PhotoLookupState = .empty
    private(set) var photoData: Data?
    private(set) var kanji: [String] = []
    private(set) var startedIDs: Set<String> = []
    /// The "New to you" filter. Off by default.
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
        kanji = []
        state = .reading

        let reader = reader
        let contentStore = contentStore
        let outcome: Result<[String], Error> = await Task.detached(priority: .userInitiated) { () async -> Result<[String], Error> in
            do {
                let reading = try await reader.read(imageData: imageData)
                let bundled = Set(try contentStore.indexEntries().map(\.id))
                return .success(PhotoKanjiExtractor.kanji(in: reading.combinedLines, bundled: bundled))
            } catch {
                return .failure(error)
            }
        }.value
        guard mine == generation else { return }

        switch outcome {
        case .success(let found):
            startedIDs = (try? await learnerStore?.nonNewKanjiIDs()) ?? []
            guard mine == generation else { return }
            kanji = found
            state = found.isEmpty ? .noKanji : .found
        case .failure:
            state = .failed
        }
    }

    /// Back to the live camera. A read still running drops its result, and the "New to you" choice stays.
    func retake() {
        generation += 1
        photoData = nil
        kanji = []
        startedIDs = []
        state = .empty
    }
}

/*---------------------------------entry----------------------------------*/

/// What a tap on "Look up a photo" does.
enum PhotoLookupEntry: Equatable {
    case paywall(ProFeature)
    case sheet

    static func open(access: ProAccess) -> PhotoLookupEntry {
        access.allows(.photoLookup) ? .sheet : .paywall(.photoLookup)
    }
}

/// The open photo lookup camera. Each open gets a fresh model, so a new photo never shows the last one's grid.
struct PhotoLookupPresentation: Identifiable {
    let model: PhotoLookupModel

    var id: ObjectIdentifier { ObjectIdentifier(model) }
}
