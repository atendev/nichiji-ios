import Observation
import PhotosUI
import SwiftUI

enum PhotoKind: String, Codable, CaseIterable, Identifiable {
    case shopSign = "Shop sign"
    case printedPage = "Printed page"
    case menuOrLabel = "Menu or label"
    case other = "Other"

    var id: String { rawValue }
}

enum TextLayout: String, Codable, CaseIterable, Identifiable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case mixed = "Mixed"

    var id: String { rawValue }
}

enum Verdict: String, Codable, CaseIterable, Identifiable {
    case good = "Good"
    case partial = "Partial"
    case failed = "Failed"

    var id: String { rawValue }
}

struct Trial: Codable, Identifiable, Sendable {
    var id = UUID()
    var date = Date()
    var kind: PhotoKind = .shopSign
    var layout: TextLayout = .horizontal
    var verdict: Verdict?
    var notes = ""
    var lines: [RecognizedLine] = []
    var seconds: Double = 0
    var error: String?
}

struct SummaryRow: Identifiable {
    var label: String
    var good = 0
    var partial = 0
    var failed = 0

    var id: String { label }
    var total: Int { good + partial + failed }
    var goodRate: Double { total == 0 ? 0 : Double(good) / Double(total) }
    var usableRate: Double { total == 0 ? 0 : Double(good + partial) / Double(total) }
}

@MainActor
@Observable
final class TrialStore {
    private(set) var trials: [Trial] = []
    private(set) var thumbnails: [UUID: UIImage] = [:]
    private(set) var pending = 0
    let supportedLanguages = Recognizer.supportedLanguages()

    var hasJapanese: Bool { supportedLanguages.contains { $0.hasPrefix("ja") } }

    private let fileURL = URL.documentsDirectory.appending(path: "trials.json")

    init() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Trial].self, from: data) {
            trials = saved
        }
    }

    func trial(_ id: UUID) -> Trial? { trials.first { $0.id == id } }

    func update(_ trial: Trial) {
        guard let index = trials.firstIndex(where: { $0.id == trial.id }) else { return }
        trials[index] = trial
        save()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets { thumbnails[trials[index].id] = nil }
        trials.remove(atOffsets: offsets)
        save()
    }

    func removeAll() {
        trials = []
        thumbnails = [:]
        save()
    }

    func add(_ items: [PhotosPickerItem]) async {
        pending += items.count
        for item in items {
            defer { pending -= 1 }
            var trial = Trial()
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    thumbnails[trial.id] = image.preparingThumbnail(of: CGSize(width: 900, height: 900))
                }
                do {
                    let result = try await Recognizer.recognize(imageData: data)
                    trial.lines = result.lines
                    trial.seconds = result.seconds
                } catch {
                    trial.error = String(describing: error)
                }
            } else {
                trial.error = "Photo could not be loaded"
            }
            trials.insert(trial, at: 0)
            save()
        }
    }

    // MARK: Summary

    var unrated: Int { trials.filter { $0.verdict == nil && $0.error == nil }.count }

    var summaryByKind: [SummaryRow] {
        summary(PhotoKind.allCases.map(\.rawValue)) { $0.kind.rawValue }
    }

    var summaryByLayout: [SummaryRow] {
        summary(TextLayout.allCases.map(\.rawValue)) { $0.layout.rawValue }
    }

    var summaryAll: SummaryRow {
        summary(["All rated photos"]) { _ in "All rated photos" }[0]
    }

    private func summary(_ labels: [String], key: (Trial) -> String) -> [SummaryRow] {
        var rows = labels.map { SummaryRow(label: $0) }
        for trial in trials {
            guard let verdict = trial.verdict, let index = rows.firstIndex(where: { $0.label == key(trial) }) else { continue }
            switch verdict {
            case .good: rows[index].good += 1
            case .partial: rows[index].partial += 1
            case .failed: rows[index].failed += 1
            }
        }
        return rows
    }

    var csv: String {
        let header = "date,kind,layout,verdict,seconds,notes,recognized_text"
        let rows = trials.map { trial -> String in
            let text = trial.lines.map(\.text).joined(separator: " / ")
            let fields = [
                trial.date.formatted(.iso8601),
                trial.kind.rawValue,
                trial.layout.rawValue,
                trial.verdict?.rawValue ?? "",
                String(format: "%.2f", trial.seconds),
                trial.notes,
                text
            ]
            return fields.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(trials) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
