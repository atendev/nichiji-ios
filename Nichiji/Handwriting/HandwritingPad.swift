import CoreGraphics
import Foundation

/*---------------------------------point----------------------------------*/

/// One sampled touch on the draw-to-search pad: unit coordinates, and `t` in milliseconds since the drawing's first touch.
public struct HandwritingPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let t: Int

    public init(x: Double, y: Double, t: Int) {
        self.x = x
        self.y = y
        self.t = t
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

/// The finished strokes a recognizer reads.
public struct HandwritingInk: Equatable, Sendable {
    public let strokes: [[HandwritingPoint]]

    public init(strokes: [[HandwritingPoint]]) {
        self.strokes = strokes
    }
}

/*----------------------------------pad-----------------------------------*/

/// The strokes drawn on the draw-to-search pad. Each drag is one stroke; a tap with no movement also counts as one.
public struct HandwritingPad: Equatable, Sendable {
    public private(set) var strokes: [[HandwritingPoint]] = []
    public private(set) var currentStroke: [HandwritingPoint]?
    private var origin: TimeInterval?

    public init() {}

    public var strokeCount: Int { strokes.count + (currentStroke == nil ? 0 : 1) }
    public var isEmpty: Bool { strokeCount == 0 }
    public var canUndo: Bool { !strokes.isEmpty }
    public var ink: HandwritingInk { HandwritingInk(strokes: strokes) }

    public var allStrokes: [[HandwritingPoint]] {
        guard let currentStroke else { return strokes }
        return strokes + [currentStroke]
    }

    /// The note beside MATCHES.
    public var note: String {
        switch strokeCount {
        case 0: "Matches appear as you draw"
        case 1: "1 stroke drawn"
        default: "\(strokeCount) strokes drawn"
        }
    }

    /// `time` is any monotonic seconds value, such as a gesture's timestamp.
    public mutating func begin(at point: CGPoint, time: TimeInterval) {
        if origin == nil || isEmpty {
            origin = time
        }
        currentStroke = [sample(point, time: time)]
    }

    public mutating func extend(to point: CGPoint, time: TimeInterval) {
        guard currentStroke != nil else { return }
        let sampled = sample(point, time: time)
        currentStroke?.append(sampled)
    }

    public mutating func end() {
        guard let currentStroke else { return }
        strokes.append(currentStroke)
        self.currentStroke = nil
    }

    public mutating func undo() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
    }

    public mutating func clear() {
        strokes = []
        currentStroke = nil
        origin = nil
    }

    private func sample(_ point: CGPoint, time: TimeInterval) -> HandwritingPoint {
        let elapsed = max(0, time - (origin ?? time))
        return HandwritingPoint(
            x: Double(min(max(point.x, 0), 1)),
            y: Double(min(max(point.y, 0), 1)),
            t: Int((elapsed * 1000).rounded())
        )
    }
}
