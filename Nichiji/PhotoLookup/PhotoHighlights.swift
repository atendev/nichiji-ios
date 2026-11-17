import CoreGraphics
import Foundation

/*--------------------------------geometry--------------------------------*/

enum PhotoFit {
    /// Where an aspect-filled photo is drawn in a view: centred, and larger than the view on one axis.
    static func filledFrame(imageSize: CGSize, in viewSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else { return .zero }
        let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: (viewSize.width - size.width) / 2, y: (viewSize.height - size.height) / 2, width: size.width, height: size.height)
    }

    /// A normalized box (top-left origin) in view coordinates, for a photo drawn aspect-fill.
    static func viewRect(forNormalized box: CGRect, imageSize: CGSize, in viewSize: CGSize) -> CGRect {
        let frame = filledFrame(imageSize: imageSize, in: viewSize)
        return CGRect(
            x: frame.minX + box.minX * frame.width,
            y: frame.minY + box.minY * frame.height,
            width: box.width * frame.width,
            height: box.height * frame.height
        )
    }
}

/*--------------------------------highlights------------------------------*/

/// One red or green box on the frozen photo.
struct HighlightBox: Identifiable, Equatable, Sendable {
    let id: Int
    let kanji: String
    /// Normalized image coordinates, origin at the top left.
    let rect: CGRect
    /// New to you (red) as against started (green).
    let isNew: Bool
}

enum PhotoHighlights {
    /// The smallest tap region a box gets, in points.
    static let minTarget: CGFloat = 44

    /// Every box of every kanji found, in the order of the results grid. Green is any stage past new.
    static func boxes(scanned: [ScannedKanji], startedIDs: Set<String>) -> [HighlightBox] {
        var boxes: [HighlightBox] = []
        for kanji in scanned {
            let isNew = !startedIDs.contains(kanji.id)
            for rect in kanji.boxes {
                boxes.append(HighlightBox(id: boxes.count, kanji: kanji.id, rect: rect, isNew: isNew))
            }
        }
        return boxes
    }

    /// A box's tap region: the box itself, grown about its centre to at least 44 x 44 pt.
    static func tapRegion(for rect: CGRect) -> CGRect {
        let width = max(rect.width, minTarget)
        let height = max(rect.height, minTarget)
        return CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
    }

    /// The box a tap lands on. Where regions overlap, the box the point is inside or nearest to wins, then the one whose centre is closest.
    static func index(at point: CGPoint, in rects: [CGRect]) -> Int? {
        var best: (index: Int, outside: CGFloat, centre: CGFloat)?
        for (index, rect) in rects.enumerated() where tapRegion(for: rect).contains(point) {
            let candidate = (index: index, outside: distance(from: point, to: rect), centre: hypot(point.x - rect.midX, point.y - rect.midY))
            if let current = best, (current.outside, current.centre) <= (candidate.outside, candidate.centre) { continue }
            best = candidate
        }
        return best?.index
    }

    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return hypot(dx, dy)
    }
}

/*----------------------------------sweep-----------------------------------*/

/// The scan line's clock. The line loops down the photo every pass while the read runs. Once results exist the pass in progress finishes the job: each box fades in as the line reaches it, and the line goes at the bottom.
struct ScanSweep: Equatable, Sendable {
    static let passDuration: TimeInterval = 1.6
    static let boxFade: TimeInterval = 0.35
    /// Under Reduce Motion the boxes crossfade together and there is no line.
    static let reducedFade: TimeInterval = 0.2

    let readStart: Date
    private(set) var resultsAt: Date?
    private var phaseAtResults: TimeInterval = 0

    init(readStart: Date) {
        self.readStart = readStart
    }

    /// Notes when the read finished, and where the line was.
    mutating func finishRead(at date: Date) {
        guard resultsAt == nil else { return }
        resultsAt = date
        phaseAtResults = Self.phase(elapsed: date.timeIntervalSince(readStart))
    }

    /// Seconds into the current pass.
    static func phase(elapsed: TimeInterval) -> TimeInterval {
        guard elapsed > 0 else { return 0 }
        return elapsed.truncatingRemainder(dividingBy: passDuration)
    }

    /// How far down the photo the line is, 0 to 1, or nil when it is not drawn.
    func linePosition(at date: Date) -> Double? {
        if let resultsAt, date >= resultsAt.addingTimeInterval(Self.passDuration - phaseAtResults) { return nil }
        return Self.phase(elapsed: date.timeIntervalSince(readStart)) / Self.passDuration
    }

    /// The line is solid, then fades over the last 8% of a pass.
    static func lineOpacity(at position: Double) -> Double {
        position > 0.92 ? max(0, (1 - position) / 0.08) : 1
    }

    /// How far a box is faded in, 0 to 1. `normalizedY` is where the box sits down the view, 0 to 1.
    func boxProgress(at date: Date, normalizedY: Double, reduceMotion: Bool) -> Double {
        guard let resultsAt else { return 0 }
        let fade = reduceMotion ? Self.reducedFade : Self.boxFade
        let wait = reduceMotion ? 0 : max(0, min(max(normalizedY, 0), 1) * Self.passDuration - phaseAtResults)
        let elapsed = date.timeIntervalSince(resultsAt) - wait
        return min(max(elapsed / fade, 0), 1)
    }

    /// Seconds after the results land until every box is in and the line is gone.
    func settleTime(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? Self.reducedFade : (Self.passDuration - phaseAtResults) + Self.boxFade
    }
}
