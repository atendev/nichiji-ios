import CoreGraphics

/*----------------------------------pad-----------------------------------*/

/// The strokes drawn on the practice pad, in unit coordinates so they survive a resize.
/// Each drag is one stroke; a tap with no movement also counts as one.
public struct PracticePad: Equatable, Sendable {
    public private(set) var strokes: [[CGPoint]] = []
    public private(set) var currentStroke: [CGPoint]?

    public init() {}

    public var strokeCount: Int { strokes.count + (currentStroke == nil ? 0 : 1) }
    public var isEmpty: Bool { strokeCount == 0 }
    public var canUndo: Bool { !strokes.isEmpty }

    public var allStrokes: [[CGPoint]] {
        guard let currentStroke else { return strokes }
        return strokes + [currentStroke]
    }

    public mutating func begin(at point: CGPoint) {
        currentStroke = [Self.clamped(point)]
    }

    public mutating func extend(to point: CGPoint) {
        guard currentStroke != nil else { return }
        currentStroke?.append(Self.clamped(point))
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
    }

    public func countLabel(total: Int) -> String {
        let drawn = strokeCount == 1 ? "1 stroke drawn" : "\(strokeCount) strokes drawn"
        return "\(drawn) · \(total) in the kanji"
    }

    private static func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
    }
}

/*---------------------------------target---------------------------------*/

/// The kanji a practice sheet opens on. Callers build it from content they already loaded.
public struct PracticeTarget: Identifiable, Equatable, Sendable {
    public let kanji: String
    public let meaning: String
    public let strokeCount: Int
    public let strokePaths: [String]

    public var id: String { kanji }

    public init(kanji: String, meanings: [String], strokeCount: Int, strokePaths: [String]) {
        self.kanji = kanji
        self.meaning = meanings.first ?? ""
        self.strokeCount = strokeCount
        self.strokePaths = strokePaths
    }

    public init(entry: KanjiEntry, strokePaths: [String]) {
        self.init(kanji: entry.id, meanings: entry.meanings, strokeCount: entry.strokeCount, strokePaths: strokePaths)
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Stroke checking is out of v1.0 ("Fix the v1.0 scope"); a later checker can read `strokes` as they are.
