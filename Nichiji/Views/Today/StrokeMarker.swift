import SwiftUI

/*-------------------------------stroke-marker-----------------------------*/

/// Where a KanjiVG stroke starts and which way it first heads, in the 109-unit viewBox.
struct StrokeMarker: Equatable, Sendable {
    enum Segment: Equatable, Sendable {
        case line(from: CGPoint, to: CGPoint)
        case curve(from: CGPoint, control1: CGPoint, control2: CGPoint, to: CGPoint)

        var origin: CGPoint {
            switch self {
            case let .line(from, _), let .curve(from, _, _, _):
                return from
            }
        }
    }

    /// The direction points along the chord from the start to the point this far along the stroke.
    static let chordLength: CGFloat = 10
    static let curveSamples = 64

    static let dotRadius: CGFloat = 4.5
    static let haloRadius: CGFloat = 6
    static let arrowShaft: CGFloat = 11
    static let arrowArm: CGFloat = 4
    static let arrowArmAngle: CGFloat = 0.75
    static let arrowOffset: CGFloat = 8
    static let arrowLead: CGFloat = 2
    static let arrowWidth: CGFloat = 1.8
    static let arrowHaloWidth: CGFloat = 4.8

    let start: CGPoint
    /// A unit vector, or nil when the stroke has no length.
    let direction: CGVector?

    init(start: CGPoint, direction: CGVector?) {
        self.start = start
        self.direction = direction
    }

    init?(start: CGPoint?, segments: [Segment]) {
        guard let start else { return nil }
        let end = Self.point(alongLength: Self.chordLength, from: start, segments: segments)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = (dx * dx + dy * dy).squareRoot()
        self.init(start: start, direction: length > 0 ? CGVector(dx: dx / length, dy: dy / length) : nil)
    }

    private static func point(alongLength target: CGFloat, from start: CGPoint, segments: [Segment]) -> CGPoint {
        var previous = start
        var travelled: CGFloat = 0
        for segment in segments {
            previous = segment.origin
            for next in samples(of: segment) {
                let step = hypot(next.x - previous.x, next.y - previous.y)
                if step > 0, travelled + step >= target {
                    let fraction = (target - travelled) / step
                    return CGPoint(x: previous.x + fraction * (next.x - previous.x), y: previous.y + fraction * (next.y - previous.y))
                }
                travelled += step
                previous = next
            }
        }
        return previous
    }

    private static func samples(of segment: Segment) -> [CGPoint] {
        switch segment {
        case let .line(_, to):
            return [to]
        case let .curve(from, control1, control2, to):
            return (1...curveSamples).map { index in
                let t = CGFloat(index) / CGFloat(curveSamples)
                let u = 1 - t
                let a = u * u * u
                let b = 3 * u * u * t
                let c = 3 * u * t * t
                let d = t * t * t
                return CGPoint(
                    x: a * from.x + b * control1.x + c * control2.x + d * to.x,
                    y: a * from.y + b * control1.y + c * control2.y + d * to.y
                )
            }
        }
    }
}

/*----------------------------stroke-marker-shapes-------------------------*/

extension StrokeMarker {
    /// Filled circle of `radius` around the start point.
    func dotPath(radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: start.x - radius, y: start.y - radius, width: radius * 2, height: radius * 2))
    }

    /// A shaft with a chevron at its tip, parallel to the direction and beside the stroke on the left of travel.
    func arrowPath() -> Path? {
        guard let direction else { return nil }
        let ux = direction.dx
        let uy = direction.dy
        let tailX = start.x + uy * Self.arrowOffset + ux * Self.arrowLead
        let tailY = start.y - ux * Self.arrowOffset + uy * Self.arrowLead
        let tip = CGPoint(x: tailX + ux * Self.arrowShaft, y: tailY + uy * Self.arrowShaft)
        let cosine = cos(Self.arrowArmAngle)
        let sine = sin(Self.arrowArmAngle)
        let arm = Self.arrowArm
        var path = Path()
        path.move(to: CGPoint(x: tailX, y: tailY))
        path.addLine(to: tip)
        path.move(to: CGPoint(x: tip.x - arm * (ux * cosine + uy * sine), y: tip.y - arm * (uy * cosine - ux * sine)))
        path.addLine(to: tip)
        path.addLine(to: CGPoint(x: tip.x - arm * (ux * cosine - uy * sine), y: tip.y - arm * (uy * cosine + ux * sine)))
        return path
    }

    /// Draws a sunken halo and the vermilion dot. The caller draws the current stroke after it.
    func drawDot(in context: GraphicsContext) {
        context.fill(dotPath(radius: Self.haloRadius), with: .color(.nichijiSurfaceSunken))
        context.fill(dotPath(radius: Self.dotRadius), with: .color(.nichijiVermilion))
    }

    func drawArrow(in context: GraphicsContext) {
        guard let arrow = arrowPath() else { return }
        for (color, width) in [(Color.nichijiSurfaceSunken, Self.arrowHaloWidth), (Color.nichijiVermilion, Self.arrowWidth)] {
            context.stroke(arrow, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
    }
}

/*-----------------------------stroke-marker-label-------------------------*/

extension StrokeMarker {
    /// Clockwise from right, in the viewBox's y-down space.
    private static let directionWords = ["right", "down-right", "down", "down-left", "left", "up-left", "up", "up-right"]

    /// One of eight words for the starting direction, or nil when the stroke has none.
    var directionWord: String? {
        guard let direction else { return nil }
        let degrees = atan2(direction.dy, direction.dx) * 180 / .pi
        let sector = (Int((degrees / 45).rounded()) + 8) % 8
        return Self.directionWords[sector]
    }

    static func accessibilityLabel(stroke: Int, of count: Int, marker: StrokeMarker?) -> String {
        let label = "Stroke \(stroke) of \(count)"
        guard let word = marker?.directionWord else { return label }
        return "\(label), starts going \(word)"
    }
}
