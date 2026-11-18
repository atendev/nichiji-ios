import CoreGraphics
import Foundation

/*---------------------------------states---------------------------------*/

/// The three heights the results sheet rests at.
enum ScanSheetState: Int, CaseIterable, Comparable, Sendable {
    case peek
    case half
    case full

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var higher: Self { Self(rawValue: rawValue + 1) ?? self }
    var lower: Self { Self(rawValue: rawValue - 1) ?? self }
}

/// How the frozen photo sits while the sheet is up: scaled about the design's anchor and lifted.
struct ScanPhotoPose: Equatable, Sendable {
    var scale: CGFloat
    var lift: CGFloat
}

/*--------------------------------geometry--------------------------------*/

enum ScanSheetGeometry {
    static let peekHeight: CGFloat = 112
    static let halfHeight: CGFloat = 456
    /// A drag longer than this always moves one state.
    static let snapDistance: CGFloat = 40
    /// A finger has to travel this far before a touch on the header counts as a drag.
    static let dragSlop: CGFloat = 6
    /// A grid scrolled further than this pulls the half sheet to full.
    static let scrollPull: CGFloat = 10
    /// The body hides below this height, and the header changes shape at the thresholds in `presentation`.
    static let bodyMinHeight: CGFloat = 150
    static let halfThreshold: CGFloat = 300
    static let cornerRadius: CGFloat = 20
    static let photoHalfScale: CGFloat = 0.8
    static let photoHalfLift: CGFloat = 100
    /// The photo scales about this point, as a share of the screen height (340 pt on the 844 pt artboard).
    static let photoAnchorY: CGFloat = 340 / 844
    /// The sheet rises this long after the shutter.
    static let riseAfter: TimeInterval = 1.9
    static let snapDuration: TimeInterval = 0.32

    static func height(of state: ScanSheetState, screenHeight: CGFloat) -> CGFloat {
        let full = max(screenHeight, peekHeight)
        switch state {
        case .peek: return peekHeight
        case .half: return min(halfHeight, full)
        case .full: return full
        }
    }

    static func clamp(_ value: CGFloat, screenHeight: CGFloat) -> CGFloat {
        min(max(value, peekHeight), height(of: .full, screenHeight: screenHeight))
    }

    /// The sheet's height while a finger drags the header, `translation` being how far it moved down.
    static func dragHeight(from state: ScanSheetState, translation: CGFloat, screenHeight: CGFloat) -> CGFloat {
        clamp(height(of: state, screenHeight: screenHeight) - translation, screenHeight: screenHeight)
    }

    /// The state a drag ends in: the nearest one, and never the one it started from after a drag over 40 pt.
    static func snap(from state: ScanSheetState, endHeight: CGFloat, screenHeight: CGFloat) -> ScanSheetState {
        var best = ScanSheetState.peek
        for candidate in ScanSheetState.allCases {
            let gap = abs(height(of: candidate, screenHeight: screenHeight) - endHeight)
            if gap < abs(height(of: best, screenHeight: screenHeight) - endHeight) { best = candidate }
        }
        let moved = endHeight - height(of: state, screenHeight: screenHeight)
        if moved > snapDistance { return max(best, state.higher) }
        if moved < -snapDistance { return min(best, state.lower) }
        return best
    }

    /// Which header the sheet shows at this height, which may sit between two rest states mid-drag.
    static func presentation(forHeight value: CGFloat, screenHeight: CGFloat) -> ScanSheetState {
        if value >= screenHeight - cornerRadius { return .full }
        return value >= halfThreshold ? .half : .peek
    }

    /// The top corners flatten over the last 40 pt before full.
    static func cornerRadius(forHeight value: CGFloat, screenHeight: CGFloat) -> CGFloat {
        cornerRadius * min(max((screenHeight - value) / snapDistance, 0), 1)
    }

    /// The photo is full size at peek and 0.8 scale, 100 pt up at half, and follows the sheet linearly between.
    static func photoPose(sheetHeight value: CGFloat) -> ScanPhotoPose {
        let progress = min(max((halfHeight - value) / (halfHeight - peekHeight), 0), 1)
        return ScanPhotoPose(
            scale: photoHalfScale + (1 - photoHalfScale) * progress,
            lift: photoHalfLift * (1 - progress)
        )
    }

    static func scrollPullsToFull(offset: CGFloat) -> Bool {
        offset > scrollPull
    }

    /// Seconds left before the sheet rises, counted from the moment the read began.
    static func riseDelay(readStart: Date, now: Date) -> TimeInterval {
        max(0, readStart.addingTimeInterval(riseAfter).timeIntervalSince(now))
    }
}

/*---------------------------------screen---------------------------------*/

/// The scan screen's size and safe-area insets. The tab bar counts in the bottom inset, so the total stays the screen's own height whether it shows or not.
struct ScanScreenMetrics: Equatable, Sendable {
    var size: CGSize = .zero
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0

    var screenHeight: CGFloat { size.height + topInset + bottomInset }
}
