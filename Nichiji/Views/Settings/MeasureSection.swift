import SwiftUI

/// Temporary measurement panel for ticket 088. Remove before merging to main.
struct MeasureSection: View {
    @State private var widgetReport = ""
    @State private var indexReport = "Not run yet."

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            Text("MEASURE")
                .font(.uiText(size: 12, weight: .medium))
                .foregroundColor(.nichijiInk)
            Text(widgetReport)
            Button("Refresh widget numbers") {
                widgetReport = WidgetMemoryProbe.summary()
            }
            Button("Measure search index") {
                indexReport = Self.measureIndex()
            }
            Text(indexReport)
        }
        .font(.uiText(size: 14, weight: .regular))
        .foregroundColor(.nichijiInk)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            widgetReport = WidgetMemoryProbe.summary()
        }
    }

    private static func measureIndex() -> String {
        let before = WidgetMemoryProbe.residentMB()
        let start = ContinuousClock.now
        do {
            let index = try DictionarySearchIndex.load(
                contentStore: BundledKanjiContentStore(),
                source: BundledDictionarySearchSource()
            )
            let elapsed = ContinuousClock.now - start
            let growth = WidgetMemoryProbe.residentMB() - before
            let milliseconds = Double(elapsed.components.seconds) * 1_000
                + Double(elapsed.components.attoseconds) / 1e15
            let report = String(format: "Search index %.0f ms, memory +%.1f MB", milliseconds, growth)
            withExtendedLifetime(index) {}
            return report
        } catch {
            return "Search index failed: \(error)"
        }
    }
}
