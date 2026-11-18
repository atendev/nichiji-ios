import SwiftUI

/*---------------------------------host-----------------------------------*/

/// Everything the scan screen needs to run the results sheet: its screen metrics, the tab bar at full, the rise after the shutter and the reset on a new photo.
private struct ScanSheetHost: ViewModifier {
    let sheet: ScanSheetModel
    let state: PhotoLookupState
    let sweep: ScanSweep?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .toolbar(sheet.isFull ? .visible : .hidden, for: .tabBar)
            .onGeometryChange(for: ScanScreenMetrics.self) { proxy in
                ScanScreenMetrics(size: proxy.size, topInset: proxy.safeAreaInsets.top, bottomInset: proxy.safeAreaInsets.bottom)
            } action: { sheet.update(metrics: $0) }
            .onChange(of: state, initial: true) { _, next in
                if next == .empty || next == .reading { sheet.reset() }
            }
            // The sheet rises about 1.9 s after the shutter, once results exist.
            .task(id: sweep?.resultsAt) {
                guard let sweep, sweep.resultsAt != nil else { return }
                let delay = ScanSheetGeometry.riseDelay(readStart: sweep.readStart, now: .now)
                try? await Task.sleep(for: .seconds(delay))
                if !Task.isCancelled { sheet.rise(reduceMotion: reduceMotion) }
            }
    }
}

extension View {
    func scanSheetHost(_ sheet: ScanSheetModel, state: PhotoLookupState, sweep: ScanSweep?) -> some View {
        modifier(ScanSheetHost(sheet: sheet, state: state, sweep: sweep))
    }
}
