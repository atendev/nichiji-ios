import Foundation

/*---------------------------------reading----------------------------------*/

/// The text two engines read from one photo. Vision answers first; Live Text stands in when Vision finds next to nothing.
struct PhotoTextReading: Equatable, Sendable {
    /// Vision reading fewer characters than this in total counts as sparse.
    static let sparseThreshold = 4

    var visionLines: [String]
    var liveTextLines: [String]

    var visionIsSparse: Bool {
        visionLines.reduce(0) { $0 + $1.count } < Self.sparseThreshold
    }

    /// Whether Live Text is worth running, given only Vision's lines.
    static func needsLiveText(visionLines: [String]) -> Bool {
        PhotoTextReading(visionLines: visionLines, liveTextLines: []).visionIsSparse
    }

    var combinedLines: [String] {
        visionIsSparse && !liveTextLines.isEmpty ? liveTextLines : visionLines
    }
}

/*--------------------------------extractor---------------------------------*/

enum PhotoKanjiExtractor {
    /// Every distinct bundled kanji in the text, in the order it first appears.
    static func kanji(in lines: [String], bundled: Set<String>) -> [String] {
        var seen = Set<String>()
        var found: [String] = []
        for character in lines.joined() {
            let id = String(character)
            guard bundled.contains(id), seen.insert(id).inserted else { continue }
            found.append(id)
        }
        return found
    }
}
