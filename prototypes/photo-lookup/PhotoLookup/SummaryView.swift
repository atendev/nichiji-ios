import SwiftUI

struct SummaryView: View {
    @Environment(TrialStore.self) private var store
    @State private var confirmClear = false

    var body: some View {
        List {
            Section {
                row(store.summaryAll)
            } footer: {
                Text("Good = the kanji came back right. Usable = Good plus Partial. \(store.unrated) photos are still unrated.")
            }
            Section("By photo type") {
                ForEach(store.summaryByKind.filter { $0.total > 0 }) { row($0) }
            }
            Section("By text layout") {
                ForEach(store.summaryByLayout.filter { $0.total > 0 }) { row($0) }
            }
            Section {
                ShareLink(item: store.csv, preview: SharePreview("photo-lookup-results.csv")) {
                    Label("Export results as CSV", systemImage: "square.and.arrow.up")
                        .frame(minHeight: 44)
                }
                Button("Delete all photos", role: .destructive) { confirmClear = true }
                    .frame(minHeight: 44)
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete all results?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) { store.removeAll() }
        }
    }

    private func row(_ row: SummaryRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.label).font(.headline)
            Text("\(row.total) photos · Good \(row.good) · Partial \(row.partial) · Failed \(row.failed)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Good \(row.goodRate, format: .percent.precision(.fractionLength(0))) · Usable \(row.usableRate, format: .percent.precision(.fractionLength(0)))")
                .font(.subheadline.monospacedDigit())
        }
        .frame(minHeight: 60, alignment: .leading)
    }
}
