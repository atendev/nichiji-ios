import SwiftUI

struct TrialDetailView: View {
    let id: UUID
    @Environment(TrialStore.self) private var store

    var body: some View {
        if let trial = store.trial(id) {
            Form {
                if let image = store.thumbnails[id] {
                    Section {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets())
                    }
                }
                recognizedSection(trial)
                rateSection(trial)
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Photo removed", systemImage: "trash")
        }
    }

    private func recognizedSection(_ trial: Trial) -> some View {
        Section {
            if let error = trial.error {
                Text(error).foregroundStyle(.red)
            } else if trial.lines.isEmpty {
                Text("No text found").foregroundStyle(.secondary)
            }
            ForEach(Array(trial.lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline) {
                    JapaneseText(text: line.text).textSelection(.enabled)
                    Spacer()
                    Text(line.confidence, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Recognized")
        } footer: {
            Text("Read in \(trial.seconds, format: .number.precision(.fractionLength(2))) s")
        }
    }

    private func rateSection(_ trial: Trial) -> some View {
        Section {
            Picker("Photo type", selection: binding(trial, \.kind)) {
                ForEach(PhotoKind.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Text layout", selection: binding(trial, \.layout)) {
                ForEach(TextLayout.allCases) { Text($0.rawValue).tag($0) }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Did it read the kanji well enough to look up?")
                HStack(spacing: 8) {
                    ForEach(Verdict.allCases) { verdict in
                        verdictButton(verdict, trial: trial)
                    }
                }
            }
            .padding(.vertical, 8)
            TextField("Notes", text: binding(trial, \.notes), axis: .vertical)
                .frame(minHeight: 44)
        } header: {
            Text("Rate")
        }
    }

    private func verdictButton(_ verdict: Verdict, trial: Trial) -> some View {
        let selected = trial.verdict == verdict
        return Button {
            var changed = trial
            changed.verdict = selected ? nil : verdict
            store.update(changed)
        } label: {
            Label(verdict.rawValue, systemImage: selected ? "checkmark" : "circle")
                .labelStyle(.titleAndIcon)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(selected ? Color.accentColor : Color.secondary)
    }

    private func binding<Value>(_ trial: Trial, _ keyPath: WritableKeyPath<Trial, Value>) -> Binding<Value> {
        Binding(
            get: { store.trial(id)?[keyPath: keyPath] ?? trial[keyPath: keyPath] },
            set: { newValue in
                guard var changed = store.trial(id) else { return }
                changed[keyPath: keyPath] = newValue
                store.update(changed)
            }
        )
    }
}
