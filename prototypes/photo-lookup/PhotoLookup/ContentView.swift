import PhotosUI
import SwiftUI

/// Japanese text drawn with Japanese glyph shapes, whatever the phone's language is.
struct JapaneseText: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .typesettingLanguage(.explicit(Locale.Language(identifier: "ja")))
    }
}

struct ContentView: View {
    @Environment(TrialStore.self) private var store
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            List {
                languageSection
                if store.pending > 0 {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Reading \(store.pending) photos")
                        }
                    }
                }
                if store.trials.isEmpty && store.pending == 0 {
                    ContentUnavailableView(
                        "No photos yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Add at least 30 photos of real signage and printed pages, mixed vertical and horizontal.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section("Photos (\(store.trials.count), \(store.unrated) unrated)") {
                        ForEach(store.trials) { trial in
                            NavigationLink(value: trial.id) { TrialRow(trial: trial) }
                        }
                        .onDelete { store.remove(at: $0) }
                    }
                }
            }
            .navigationTitle("Photo lookup")
            .navigationDestination(for: UUID.self) { TrialDetailView(id: $0) }
            .navigationDestination(for: SummaryDestination.self) { _ in SummaryView() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: SummaryDestination.summary) { Label("Summary", systemImage: "chart.bar") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $selection, maxSelectionCount: 40, matching: .images) {
                        Label("Add photos", systemImage: "plus")
                    }
                }
            }
            .onChange(of: selection) { _, items in
                guard !items.isEmpty else { return }
                selection = []
                Task { await store.add(items) }
            }
        }
    }

    private var languageSection: some View {
        Section {
            Label {
                Text(store.hasJapanese ? "Japanese recognition is available" : "Japanese recognition is not listed on this device")
            } icon: {
                Image(systemName: store.hasJapanese ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(store.hasJapanese ? Color.green : Color.red)
            }
            Text(store.supportedLanguages.joined(separator: ", "))
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Device")
        }
    }
}

enum SummaryDestination: Hashable {
    case summary
}

private struct TrialRow: View {
    let trial: Trial
    @Environment(TrialStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image = store.thumbnails[trial.id] {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Color(.secondarySystemFill)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(.rect(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                if let error = trial.error {
                    Text(error).foregroundStyle(.red)
                } else if let first = trial.lines.first {
                    JapaneseText(text: first.text).lineLimit(1)
                } else {
                    Text("No text found").foregroundStyle(.secondary)
                }
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 60)
    }

    private var subtitle: String {
        "\(trial.kind.rawValue), \(trial.layout.rawValue) · \(trial.verdict?.rawValue ?? "Unrated")"
    }
}
