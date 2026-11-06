import CoreGraphics
import Foundation

/*--------------------------------matcher---------------------------------*/

/// Ranks bundled KanjiVG templates against drawn strokes. A port of the prototype's "bbox + free order" variant:
/// 12 points per stroke, bounding-box normalization, and the best one-to-one stroke assignment (Hungarian),
/// so stroke-order mistakes still match.
public struct HandwritingTemplateMatcher: Sendable {
    static let pointsPerStroke = 12
    static let strokeWindow = 2
    static let missingStrokeCost = 0.6
    static let reversedStrokeExtra = 0.08

    struct Template: Sendable {
        let kanji: String
        let strokeCount: Int
        /// x, y pairs, `pointsPerStroke` per stroke, normalized.
        let points: [Double]
    }

    let templates: [Template]

    /// Every kanji the app ships, the filter for on-device candidates.
    public let shippedKanji: Set<String>

    /// `templates` are raw stroke points in template order, which breaks ties. Kanji with no strokes are dropped.
    public init(templates: [(kanji: String, strokes: [[CGPoint]])], shippedKanji: Set<String>? = nil) {
        self.templates = templates.compactMap { template in
            let prepared = Self.prepare(template.strokes)
            guard !prepared.isEmpty else { return nil }
            return Template(kanji: template.kanji, strokeCount: prepared.count, points: Self.flatten(prepared))
        }
        self.shippedKanji = shippedKanji ?? Set(templates.map(\.kanji))
    }

    /// Best first, templates within `strokeWindow` strokes of the drawing. Ties keep template order.
    public func candidates(for strokes: [[CGPoint]], limit: Int) -> [String] {
        ranked(for: strokes).prefix(limit).map(\.kanji)
    }

    func ranked(for strokes: [[CGPoint]]) -> [(kanji: String, cost: Double)] {
        let input = Self.prepare(strokes)
        guard !input.isEmpty else { return [] }
        let inputPoints = Self.flatten(input)
        var scored: [(index: Int, cost: Double)] = []
        for (index, template) in templates.enumerated() where abs(template.strokeCount - input.count) <= Self.strokeWindow {
            let cost = Self.characterCost(inputPoints, count: input.count, template.points, count: template.strokeCount)
            scored.append((index: index, cost: cost))
        }
        scored.sort { $0.cost != $1.cost ? $0.cost < $1.cost : $0.index < $1.index }
        return scored.map { (kanji: templates[$0.index].kanji, cost: $0.cost) }
    }

    /*------------------------------geometry------------------------------*/

    /// Resamples each non-empty stroke to `pointsPerStroke`, then normalizes the whole drawing.
    static func prepare(_ strokes: [[CGPoint]]) -> [[CGPoint]] {
        normalize(strokes.filter { !$0.isEmpty }.map { resample($0, count: pointsPerStroke) })
    }

    static func resample(_ points: [CGPoint], count: Int) -> [CGPoint] {
        guard let first = points.first, let last = points.last else { return [] }
        let total = length(points)
        guard points.count > 1, total > 0 else { return Array(repeating: first, count: count) }
        let step = total / Double(count - 1)
        var out = [first]
        var accumulated = 0.0
        var index = 1
        var previous = first
        while out.count < count - 1, index < points.count {
            let current = points[index]
            let segment = Double(hypot(current.x - previous.x, current.y - previous.y))
            if accumulated + segment >= step, segment > 0 {
                let fraction = CGFloat((step - accumulated) / segment)
                let point = CGPoint(
                    x: previous.x + fraction * (current.x - previous.x),
                    y: previous.y + fraction * (current.y - previous.y)
                )
                out.append(point)
                previous = point
                accumulated = 0
            } else {
                accumulated += segment
                previous = current
                index += 1
            }
        }
        while out.count < count {
            out.append(last)
        }
        return out
    }

    /// Fits the bounding box into the unit square, aspect kept, centred.
    static func normalize(_ strokes: [[CGPoint]]) -> [[CGPoint]] {
        let all = strokes.flatMap { $0 }
        guard !all.isEmpty else { return [] }
        let minX = all.map(\.x).min() ?? 0, maxX = all.map(\.x).max() ?? 0
        let minY = all.map(\.y).min() ?? 0, maxY = all.map(\.y).max() ?? 0
        let extent = max(maxX - minX, maxY - minY)
        let size = extent == 0 ? 1 : extent
        let offsetX = (size - (maxX - minX)) / 2 - minX
        let offsetY = (size - (maxY - minY)) / 2 - minY
        return strokes.map { stroke in
            stroke.map { CGPoint(x: ($0.x + offsetX) / size, y: ($0.y + offsetY) / size) }
        }
    }

    private static func length(_ points: [CGPoint]) -> Double {
        zip(points, points.dropFirst()).reduce(0.0) { $0 + Double(hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y)) }
    }

    private static func flatten(_ strokes: [[CGPoint]]) -> [Double] {
        strokes.flatMap { $0.flatMap { [Double($0.x), Double($0.y)] } }
    }

    /*--------------------------------cost--------------------------------*/

    /// Mean point distance, or the reversed stroke's plus `reversedStrokeExtra`, whichever is lower.
    static func strokeCost(_ lhs: [Double], at lhsStroke: Int, _ rhs: [Double], at rhsStroke: Int) -> Double {
        lhs.withUnsafeBufferPointer { lhsBuffer in
            rhs.withUnsafeBufferPointer { rhsBuffer in
                strokeCost(lhsBuffer, at: lhsStroke, rhsBuffer, at: rhsStroke)
            }
        }
    }

    /// The hot loop. Buffers skip the array checks that slow Debug builds.
    private static func strokeCost(
        _ lhs: UnsafeBufferPointer<Double>, at lhsStroke: Int,
        _ rhs: UnsafeBufferPointer<Double>, at rhsStroke: Int
    ) -> Double {
        let count = pointsPerStroke
        let lhsBase = lhsStroke * count * 2
        let rhsBase = rhsStroke * count * 2
        var forward = 0.0
        var reversed = 0.0
        for point in 0..<count {
            let x = lhs[lhsBase + point * 2], y = lhs[lhsBase + point * 2 + 1]
            let forwardIndex = rhsBase + point * 2
            let reversedIndex = rhsBase + (count - 1 - point) * 2
            forward += hypot(x - rhs[forwardIndex], y - rhs[forwardIndex + 1])
            reversed += hypot(x - rhs[reversedIndex], y - rhs[reversedIndex + 1])
        }
        return min(forward / Double(count), reversed / Double(count) + reversedStrokeExtra)
    }

    /// The best assignment over the square matrix, missing strokes at `missingStrokeCost`, divided by the larger count.
    static func characterCost(_ input: [Double], count inputCount: Int, _ template: [Double], count templateCount: Int) -> Double {
        let size = max(inputCount, templateCount)
        var matrix = [Double](repeating: missingStrokeCost, count: size * size)
        input.withUnsafeBufferPointer { inputBuffer in
            template.withUnsafeBufferPointer { templateBuffer in
                for row in 0..<inputCount {
                    for column in 0..<templateCount {
                        matrix[row * size + column] = strokeCost(inputBuffer, at: row, templateBuffer, at: column)
                    }
                }
            }
        }
        return HungarianSolver.minimumCost(matrix, size: size) / Double(size)
    }
}

/*-------------------------------hungarian--------------------------------*/

/// The O(n³) Hungarian algorithm with potentials, ported unchanged from the prototype. Arrays are 1-based like the original.
enum HungarianSolver {
    /// `matrix` is row-major, `size` by `size`.
    static func minimumCost(_ matrix: [Double], size: Int) -> Double {
        guard size > 0 else { return 0 }
        var state = State(size: size)
        for row in 1...size {
            state.assign(row: row, matrix: matrix)
        }
        var cost = 0.0
        for column in 1...size {
            cost += matrix[(state.p[column] - 1) * size + column - 1]
        }
        return cost
    }

    private struct State {
        let size: Int
        var u: [Double]
        var v: [Double]
        var p: [Int]
        var way: [Int]

        init(size: Int) {
            self.size = size
            u = [Double](repeating: 0, count: size + 1)
            v = [Double](repeating: 0, count: size + 1)
            p = [Int](repeating: 0, count: size + 1)
            way = [Int](repeating: 0, count: size + 1)
        }

        mutating func assign(row: Int, matrix: [Double]) {
            p[0] = row
            var column0 = 0
            var minimum = [Double](repeating: .infinity, count: size + 1)
            var used = [Bool](repeating: false, count: size + 1)
            repeat {
                used[column0] = true
                let column1 = relax(from: column0, matrix: matrix, minimum: &minimum, used: used)
                column0 = column1
            } while p[column0] != 0
            repeat {
                let previous = way[column0]
                p[column0] = p[previous]
                column0 = previous
            } while column0 != 0
        }

        /// One Dijkstra-like step: updates the reduced costs and returns the next column to visit.
        private mutating func relax(from column0: Int, matrix: [Double], minimum: inout [Double], used: [Bool]) -> Int {
            let row0 = p[column0]
            var delta = Double.infinity
            var column1 = 0
            for column in 1...size where !used[column] {
                let current = matrix[(row0 - 1) * size + column - 1] - u[row0] - v[column]
                if current < minimum[column] {
                    minimum[column] = current
                    way[column] = column0
                }
                if minimum[column] < delta {
                    delta = minimum[column]
                    column1 = column
                }
            }
            for column in 0...size {
                if used[column] {
                    u[p[column]] += delta
                    v[column] -= delta
                } else {
                    minimum[column] -= delta
                }
            }
            return column1
        }
    }
}
