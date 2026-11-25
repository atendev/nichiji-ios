import CoreGraphics
import Foundation
import SwiftUI

/*-------------------------------playback--------------------------------*/

/// What the stroke player shows: which strokes are drawn, how far the current one has got, and whether time is running.
/// A plain value, so tests drive it with `advance(by:)` and no clock. The view only renders it.
struct StrokePlayback: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case idle
        case drawing
        case resting
        case paused
        case finished
    }

    /// Seconds a stroke takes to draw on, one per stroke. They are ignored when `animates` is false.
    let durations: [TimeInterval]
    /// False under Reduce Motion: strokes appear whole, and Play shows one every `staticStepInterval`.
    var animates = true

    private(set) var phase = Phase.idle
    /// Strokes shown whole.
    private(set) var completed = 0
    /// Linear 0 to 1 time through the stroke at index `completed`. Draw `fraction(ofStroke:)`, which eases it.
    private(set) var progress: Double = 0

    private var restElapsed: TimeInterval = 0
    private var pausedInRest = false
    /// Next was tapped: stop after the stroke that is drawing instead of resting and carrying on.
    private var stepsOnce = false

    static let restInterval: TimeInterval = 0.35
    static let staticStepInterval: TimeInterval = 0.8
    private static let viewBoxUnitsPerSecond: CGFloat = 100
    private static let shortestDuration: TimeInterval = 0.3
    private static let longestDuration: TimeInterval = 1.0

    init(durations: [TimeInterval]) {
        self.durations = durations
    }

    /// `strokePaths` are KanjiVG `d` strings, as `PracticeTarget.strokePaths` holds them.
    init(strokePaths: [String]) {
        self.init(durations: strokePaths.map { Self.duration(forLength: StrokePathParser.length(of: $0)) })
    }

    var strokeCount: Int { durations.count }

    /// True while time is running: drawing or resting. A Next step also runs time but is not "playing".
    var needsTicks: Bool { phase == .drawing || phase == .resting }
    var isPlaying: Bool { needsTicks && !stepsOnce }

    var canPlay: Bool { strokeCount > 0 }
    var canNext: Bool { phase != .finished && completed < strokeCount }
    var canPrevious: Bool { completed > 0 || progress > 0 }
    var canReplay: Bool { phase != .idle }

    /// The stroke drawn in the darkest ink, or nil on the empty stage and once the kanji is finished.
    var currentStrokeIndex: Int? {
        if phase == .finished { return nil }
        if progress > 0 { return completed }
        return completed > 0 ? completed - 1 : nil
    }

    /// Strokes started so far, counting the one drawing.
    var strokesShown: Int { completed + (progress > 0 ? 1 : 0) }

    var counterLabel: String {
        strokesShown == 0 ? "\(strokeCount) strokes" : "Stroke \(strokesShown) of \(strokeCount)"
    }

    /// How much of stroke `index` to draw, 0 to 1, for `trimmedPath(from: 0, to:)`.
    func fraction(ofStroke index: Int) -> Double {
        if index < completed { return 1 }
        if index == completed, progress > 0 { return Self.ease(progress) }
        return 0
    }

    // MARK: Controls

    mutating func play() {
        guard canPlay else { return }
        switch phase {
        case .idle:
            phase = .drawing
        case .paused:
            phase = pausedInRest || completed == strokeCount ? .resting : .drawing
        case .finished:
            reset()
            phase = .drawing
        case .drawing, .resting:
            break
        }
        stepsOnce = false
    }

    mutating func pause() {
        guard needsTicks else { return }
        pausedInRest = phase == .resting
        stepsOnce = false
        phase = .paused
    }

    /// Finishes the stroke that is drawing, or else draws the next one, then stops.
    mutating func next() {
        guard canNext else { return }
        if progress > 0 {
            completeStroke(stepping: true)
            return
        }
        pausedInRest = false
        restElapsed = 0
        stepsOnce = true
        phase = .drawing
    }

    /// Removes the current stroke and shows the one before it whole. There is no reverse animation.
    mutating func previous() {
        guard canPrevious else { return }
        if progress > 0 {
            progress = 0
        } else {
            completed -= 1
        }
        pausedInRest = false
        restElapsed = 0
        stepsOnce = false
        phase = completed == 0 ? .idle : .paused
    }

    /// Clears the stage. Pass `autoplay: false` under Reduce Motion, where Replay stays paused.
    mutating func replay(autoplay: Bool = true) {
        reset()
        if autoplay { play() }
    }

    /// Moves time forward. It does nothing unless drawing or resting, so a stray tick after a pause is harmless.
    mutating func advance(by seconds: TimeInterval) {
        var remaining = max(seconds, 0)
        // Each pass finishes a stroke or a rest, so this bound is never reached.
        for _ in 0..<(2 * strokeCount + 2) {
            switch phase {
            case .drawing:
                let duration = animates ? durations[completed] : 0
                let needed = duration * (1 - progress)
                if duration > 0, remaining < needed {
                    progress += remaining / duration
                    return
                }
                remaining -= needed
                completeStroke(stepping: stepsOnce)
            case .resting:
                let interval = animates ? Self.restInterval : Self.staticStepInterval
                let needed = interval - restElapsed
                if remaining < needed {
                    restElapsed += remaining
                    return
                }
                remaining -= needed
                restElapsed = 0
                phase = completed == strokeCount ? .finished : .drawing
            case .idle, .paused, .finished:
                return
            }
        }
    }

    // MARK: Private

    private mutating func reset() {
        phase = .idle
        completed = 0
        progress = 0
        restElapsed = 0
        pausedInRest = false
        stepsOnce = false
    }

    private mutating func completeStroke(stepping: Bool) {
        completed += 1
        progress = 0
        restElapsed = 0
        pausedInRest = false
        stepsOnce = false
        if stepping {
            phase = completed == strokeCount ? .finished : .paused
        } else {
            phase = .resting
        }
    }

    // MARK: Timing

    /// Length ÷ 100 viewBox units per second, clamped to 0.3 to 1.0 s so a dot stays visible and a long sweep stays one motion.
    nonisolated static func duration(forLength length: CGFloat) -> TimeInterval {
        min(max(TimeInterval(length / viewBoxUnitsPerSecond), shortestDuration), longestDuration)
    }

    /// Ease-in-out on the trim value.
    nonisolated static func ease(_ progress: Double) -> Double {
        let t = min(max(progress, 0), 1)
        return t < 0.5 ? 2 * t * t : 1 - 2 * (1 - t) * (1 - t)
    }
}

/*--------------------------------length----------------------------------*/

extension StrokePathParser {
    private static let flatteningSteps = 16

    /// The length of one stroke in viewBox units, with each curve flattened to straight pieces.
    nonisolated static func length(of data: String) -> CGFloat {
        length(of: path(from: data))
    }

    nonisolated static func length(of path: Path) -> CGFloat {
        var total: CGFloat = 0
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        path.forEach { element in
            switch element {
            case let .move(to):
                current = to
                subpathStart = to
            case let .line(to):
                total += distance(current, to)
                current = to
            case let .quadCurve(to, control):
                total += flattenedLength(from: current) { t in
                    let u = 1 - t
                    return CGPoint(
                        x: u * u * current.x + 2 * u * t * control.x + t * t * to.x,
                        y: u * u * current.y + 2 * u * t * control.y + t * t * to.y
                    )
                }
                current = to
            case let .curve(to, control1, control2):
                total += flattenedLength(from: current) { t in
                    let u = 1 - t
                    return CGPoint(
                        x: u * u * u * current.x + 3 * u * u * t * control1.x + 3 * u * t * t * control2.x + t * t * t * to.x,
                        y: u * u * u * current.y + 3 * u * u * t * control1.y + 3 * u * t * t * control2.y + t * t * t * to.y
                    )
                }
                current = to
            case .closeSubpath:
                total += distance(current, subpathStart)
                current = subpathStart
            }
        }
        return total
    }

    private nonisolated static func flattenedLength(from start: CGPoint, point: (CGFloat) -> CGPoint) -> CGFloat {
        var total: CGFloat = 0
        var previous = start
        for step in 1...flatteningSteps {
            let next = point(CGFloat(step) / CGFloat(flatteningSteps))
            total += distance(previous, next)
            previous = next
        }
        return total
    }

    private nonisolated static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }
}
