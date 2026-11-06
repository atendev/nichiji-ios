import SwiftUI

/*--------------------------------builder---------------------------------*/

/// Builds the matcher's templates at runtime from the bundled KanjiVG stroke SVGs, so no new data file ships.
public enum HandwritingTemplateBuilder {
    /// Points sampled per cubic, as in the prototype's `build_templates.py`.
    static let samplesPerCurve = 8

    /// Reads every shipped kanji's strokes in `listIndex` order. A kanji with no stroke SVG is skipped, not fatal.
    public static func matcher(contentStore: any KanjiContentStore) throws -> HandwritingTemplateMatcher {
        let entries = try contentStore.indexEntries().sorted {
            $0.listIndex != $1.listIndex ? $0.listIndex < $1.listIndex : $0.id < $1.id
        }
        let templates = entries.compactMap { entry -> (kanji: String, strokes: [[CGPoint]])? in
            guard let paths = try? contentStore.strokePaths(for: entry.id) else { return nil }
            return (kanji: entry.id, strokes: strokes(fromSVGPaths: paths))
        }
        return HandwritingTemplateMatcher(templates: templates, shippedKanji: Set(entries.map(\.id)))
    }

    /// One point list per SVG path, in KanjiVG's 109-unit space.
    static func strokes(fromSVGPaths paths: [String]) -> [[CGPoint]] {
        paths.map { flatten(StrokePathParser.path(from: $0)) }
    }

    /// Keeps move and line end points and samples each curve at `samplesPerCurve` steps, endpoint included.
    static func flatten(_ path: Path) -> [CGPoint] {
        var points: [CGPoint] = []
        var current = CGPoint.zero
        path.forEach { element in
            switch element {
            case .move(let end), .line(let end):
                points.append(end)
                current = end
            case let .quadCurve(end, control):
                points += sampleCurve(from: current, control, control, end)
                current = end
            case let .curve(end, control1, control2):
                points += sampleCurve(from: current, control1, control2, end)
                current = end
            case .closeSubpath:
                break
            }
        }
        return points
    }

    private static func sampleCurve(from start: CGPoint, _ control1: CGPoint, _ control2: CGPoint, _ end: CGPoint) -> [CGPoint] {
        (1...samplesPerCurve).map { step in
            let t = CGFloat(step) / CGFloat(samplesPerCurve)
            let u = 1 - t
            let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
            return CGPoint(
                x: a * start.x + b * control1.x + c * control2.x + d * end.x,
                y: a * start.y + b * control1.y + c * control2.y + d * end.y
            )
        }
    }
}
