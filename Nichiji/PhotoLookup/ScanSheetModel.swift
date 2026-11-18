import Observation
import SwiftUI

/*---------------------------------model----------------------------------*/

/// Where the results sheet rests and how far a finger has dragged it. `state` stays nil until the sheet first rises.
@MainActor
@Observable
final class ScanSheetModel {
    private(set) var state: ScanSheetState?
    private(set) var dragHeight: CGFloat?
    private(set) var metrics = ScanScreenMetrics()

    var isVisible: Bool { state != nil }
    var isFull: Bool { state == .full }

    /// The height the sheet is drawn at, following the finger mid-drag.
    var height: CGFloat {
        guard let state else { return 0 }
        return dragHeight ?? ScanSheetGeometry.height(of: state, screenHeight: metrics.screenHeight)
    }

    /// The frozen photo's pose for the current height, or untouched while there is no sheet.
    var photoPose: ScanPhotoPose {
        guard isVisible else { return ScanPhotoPose(scale: 1, lift: 0) }
        return ScanSheetGeometry.photoPose(sheetHeight: height)
    }

    static func animation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .timingCurve(0.2, 0.8, 0.2, 1, duration: ScanSheetGeometry.snapDuration)
    }

    func update(metrics: ScanScreenMetrics) {
        self.metrics = metrics
    }

    /// The sheet comes up at half height once. A sheet already up keeps its state, so coming back from a detail screen restores it.
    func rise(reduceMotion: Bool) {
        guard state == nil else { return }
        withAnimation(Self.animation(reduceMotion: reduceMotion)) {
            state = .half
        }
    }

    func reset() {
        state = nil
        dragHeight = nil
    }

    func drag(translation: CGFloat) {
        guard let state else { return }
        dragHeight = ScanSheetGeometry.dragHeight(from: state, translation: translation, screenHeight: metrics.screenHeight)
    }

    func endDrag(translation: CGFloat, reduceMotion: Bool) {
        guard let state else { return }
        let end = ScanSheetGeometry.dragHeight(from: state, translation: translation, screenHeight: metrics.screenHeight)
        let next = ScanSheetGeometry.snap(from: state, endHeight: end, screenHeight: metrics.screenHeight)
        settle(on: next, reduceMotion: reduceMotion)
    }

    func move(to next: ScanSheetState, reduceMotion: Bool) {
        guard state != nil else { return }
        settle(on: next, reduceMotion: reduceMotion)
    }

    /// One state up or down, for VoiceOver's adjustable action.
    func step(up: Bool, reduceMotion: Bool) {
        guard let state else { return }
        settle(on: up ? state.higher : state.lower, reduceMotion: reduceMotion)
    }

    /// Scrolling the half grid pulls the sheet to full. A drag in progress keeps control.
    func pullToFull(reduceMotion: Bool) {
        guard state == .half, dragHeight == nil else { return }
        settle(on: .full, reduceMotion: reduceMotion)
    }

    private func settle(on next: ScanSheetState, reduceMotion: Bool) {
        withAnimation(Self.animation(reduceMotion: reduceMotion)) {
            state = next
            dragHeight = nil
        }
    }
}

/*---------------------------------photo----------------------------------*/

extension View {
    /// Scales and lifts the frozen photo with the sheet, so its highlights stay visible above it.
    func scanSheetPhotoPose(_ sheet: ScanSheetModel) -> some View {
        let pose = sheet.photoPose
        return scaleEffect(pose.scale, anchor: UnitPoint(x: 0.5, y: ScanSheetGeometry.photoAnchorY))
            .offset(y: -pose.lift)
    }
}
