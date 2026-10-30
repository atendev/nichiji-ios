import WidgetKit

/*-------------------------------protocols------------------------------------*/

/// Single seam for asking WidgetKit to refresh, so triggers stay testable and `WidgetCenter` is called in one place.
protocol WidgetRefresher: Sendable {
    /// Requests a fresh timeline for every Nichiji widget.
    func reloadTimelines()
}

/*-------------------------------refreshers-----------------------------------*/

/// Live refresher backed by `WidgetCenter`.
struct SystemWidgetRefresher: WidgetRefresher {
    func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Refresher for previews and call sites that have no widget to update.
struct NoopWidgetRefresher: WidgetRefresher {
    func reloadTimelines() {}
}
