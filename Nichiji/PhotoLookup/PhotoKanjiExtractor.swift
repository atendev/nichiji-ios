import CoreGraphics
import Foundation

/*---------------------------------reading----------------------------------*/

/// The text two engines read from one photo. Vision answers first; Live Text stands in when Vision finds next to nothing.
struct PhotoTextReading: Equatable, Sendable {
    /// Vision reading fewer characters than this in total counts as sparse.
    static let sparseThreshold = 4

    var visionLines: [String]
    var liveTextLines: [String]
    /// One box per character of each Vision line, in normalized image coordinates with the origin at the top left.
    /// Empty when no boxes were read; a character Vision could not box is nil. Live Text gives none.
    var visionBoxes: [[CGRect?]] = []

    var visionIsSparse: Bool {
        visionLines.reduce(0) { $0 + $1.count } < Self.sparseThreshold
    }

    /// Whether Live Text is worth running, given only Vision's lines.
    static func needsLiveText(visionLines: [String]) -> Bool {
        PhotoTextReading(visionLines: visionLines, liveTextLines: []).visionIsSparse
    }

    /// Whether the combined text comes from Live Text, which has no per-character boxes.
    var usesLiveText: Bool {
        visionIsSparse && !liveTextLines.isEmpty
    }

    var combinedLines: [String] {
        usesLiveText ? liveTextLines : visionLines
    }

    /// The boxes that go with `combinedLines`: none after a Live Text read.
    var combinedBoxes: [[CGRect?]] {
        usesLiveText ? [] : visionBoxes
    }
}

/*----------------------------------boxes-----------------------------------*/

enum PhotoBox {
    /// Vision's normalized box has its origin at the bottom left; the photo overlay measures from the top left.
    static func topLeftOrigin(fromVision box: CGRect) -> CGRect {
        CGRect(x: box.minX, y: 1 - box.maxY, width: box.width, height: box.height)
    }
}

/*--------------------------------extractor---------------------------------*/

/// A bundled kanji found in a photo, with every place it appears.
struct ScannedKanji: Equatable, Sendable {
    let id: String
    /// Normalized image boxes in reading order, one per appearance. Empty after a Live Text read.
    var boxes: [CGRect]
}

enum PhotoKanjiExtractor {
    /// Every distinct bundled kanji in the reading, in order of first appearance, each with the boxes of all its appearances.
    static func scanned(_ reading: PhotoTextReading, bundled: Set<String>) -> [ScannedKanji] {
        let boxes = reading.combinedBoxes
        var order: [String] = []
        var found: [String: [CGRect]] = [:]
        for (lineIndex, line) in reading.combinedLines.enumerated() {
            let lineBoxes = boxes.indices.contains(lineIndex) ? boxes[lineIndex] : []
            for (characterIndex, character) in line.enumerated() {
                let id = String(character)
                guard bundled.contains(id) else { continue }
                if found[id] == nil {
                    order.append(id)
                    found[id] = []
                }
                if lineBoxes.indices.contains(characterIndex), let box = lineBoxes[characterIndex] {
                    found[id]?.append(box)
                }
            }
        }
        return order.map { ScannedKanji(id: $0, boxes: found[$0] ?? []) }
    }
}
