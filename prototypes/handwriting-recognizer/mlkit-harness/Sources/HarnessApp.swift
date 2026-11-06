// PROTOTYPE, throwaway. Runs ML Kit Digital Ink (ja) over the exported handwriting test set.
import MLKitDigitalInkRecognition
import SwiftUI
import UniformTypeIdentifiers

struct TestSet: Decodable {
    struct Canvas: Decodable { let width: Double; let height: Double }
    struct Sample: Decodable { let target: String; let strokes: [[[Double]]] }
    let canvas: Canvas
    let samples: [Sample]
    let pool: String?
}

struct Tally {
    var top1 = 0, top5 = 0, top10 = 0
    var misses: [Miss] = []

    mutating func add(target: String, candidates: [String]) {
        let rank = candidates.prefix(10).firstIndex(of: target).map { $0 + 1 }
        if rank == 1 { top1 += 1 }
        if let rank, rank <= 5 { top5 += 1 }
        if rank != nil { top10 += 1 }
        if rank != 1 { misses.append(Miss(target: target, rank: rank, got: candidates.prefix(3).joined(separator: " "))) }
    }
}

struct Miss: Identifiable {
    let id = UUID()
    let target: String
    let rank: Int?
    let got: String
}

@MainActor
final class Harness: ObservableObject {
    @Published var log: [String] = []
    @Published var modelReady = false
    @Published var running = false
    @Published var testSet: TestSet?
    @Published var pooled = Tally()
    @Published var raw = Tally()
    @Published var done = 0
    @Published var msPerSample = 0.0

    private let model: DigitalInkRecognitionModel
    private var recognizer: DigitalInkRecognizer?

    init() {
        // Typed optional so this compiles whether or not the initializer is failable.
        let identifier: DigitalInkRecognitionModelIdentifier? = DigitalInkRecognitionModelIdentifier(forLanguageTag: "ja")
        model = DigitalInkRecognitionModel(modelIdentifier: identifier!)
        modelReady = ModelManager.modelManager().isModelDownloaded(model)
        say(modelReady ? "ja model already on device" : "ja model not downloaded")
        NotificationCenter.default.addObserver(forName: .mlkitModelDownloadDidSucceed, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.modelReady = true; self?.say("ja model downloaded") }
        }
        NotificationCenter.default.addObserver(forName: .mlkitModelDownloadDidFail, object: nil, queue: .main) { [weak self] note in
            let error = note.userInfo?[ModelDownloadUserInfoKey.error.rawValue]
            Task { @MainActor in self?.say("download failed: \(String(describing: error))") }
        }
    }

    func say(_ line: String) {
        log.append(line)
        print("HARNESS: \(line)")
        fflush(stdout)
    }

    // CI mode: HARNESS_TESTSET=<path> loads the set, downloads the model, runs, prints the report and exits.
    func autorun(_ path: String) async {
        load(URL(fileURLWithPath: path))
        guard testSet != nil else { exit(2) }
        if !modelReady {
            download()
            for _ in 0..<600 where !modelReady {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        guard modelReady else {
            say("model not ready after 300 s")
            exit(3)
        }
        await run()
        print("HARNESS-REPORT-BEGIN\n\(report)\nHARNESS-REPORT-END")
        fflush(stdout)
        exit(0)
    }

    func download() {
        say("downloading ja model…")
        ModelManager.modelManager().download(
            model,
            conditions: ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
        )
    }

    func load(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            testSet = try JSONDecoder().decode(TestSet.self, from: Data(contentsOf: url))
            say("loaded \(testSet!.samples.count) samples")
        } catch {
            say("load failed: \(error)")
        }
    }

    func run() async {
        guard let testSet, modelReady else { return }
        let recognizer = recognizer ?? DigitalInkRecognizer.digitalInkRecognizer(options: DigitalInkRecognizerOptions(model: model))
        self.recognizer = recognizer
        running = true
        pooled = Tally(); raw = Tally(); done = 0
        let pool = testSet.pool.map { Set($0.map(String.init)) }
        let area = WritingArea(width: Float(testSet.canvas.width), height: Float(testSet.canvas.height))
        let context = DigitalInkRecognitionContext(preContext: "", writingArea: area)
        var elapsed = 0.0
        for sample in testSet.samples {
            let ink = Ink(strokes: sample.strokes.map { stroke in
                Stroke(points: stroke.map { StrokePoint(x: Float($0[0]), y: Float($0[1]), t: Int($0[2])) })
            })
            let start = Date()
            let candidates = await recognize(recognizer, ink, context)
            elapsed += Date().timeIntervalSince(start)
            raw.add(target: sample.target, candidates: candidates)
            pooled.add(target: sample.target, candidates: pool.map { p in candidates.filter(p.contains) } ?? candidates)
            done += 1
            msPerSample = elapsed * 1000 / Double(done)
        }
        running = false
        say("finished: pooled top1 \(pooled.top1)/\(done), raw top1 \(raw.top1)/\(done)")
    }

    private func recognize(_ recognizer: DigitalInkRecognizer, _ ink: Ink, _ context: DigitalInkRecognitionContext) async -> [String] {
        await withCheckedContinuation { continuation in
            recognizer.recognize(ink: ink, context: context) { result, error in
                if let error { print("recognize error: \(error)") }
                continuation.resume(returning: result?.candidates.map(\.text) ?? [])
            }
        }
    }

    var report: String {
        func pct(_ n: Int) -> String { done == 0 ? "-" : String(format: "%.1f%%", Double(n) / Double(done) * 100) }
        func row(_ t: Tally) -> String { "top-1 \(pct(t.top1))  top-5 \(pct(t.top5))  top-10 \(pct(t.top10))" }
        var lines = ["ML Kit Digital Ink (ja), \(done) samples, \(String(format: "%.0f", msPerSample)) ms/sample",
                     "Pooled to the app's kanji (primary): " + row(pooled),
                     "Raw candidates: " + row(raw), "", "Pooled misses (target, rank, top 3):"]
        lines += pooled.misses.map { "\($0.target)  \($0.rank.map(String.init) ?? "-")  \($0.got)" }
        return lines.joined(separator: "\n")
    }
}

struct HarnessView: View {
    @StateObject private var harness = Harness()
    @State private var importing = false

    var body: some View {
        NavigationStack {
            List {
                Section("PROTOTYPE · throwaway") {
                    Button(harness.modelReady ? "ja model ready" : "Download ja model", action: harness.download)
                        .disabled(harness.modelReady)
                    Button("Import test set JSON") { importing = true }
                    Button(harness.running ? "Running…" : "Run") { Task { await harness.run() } }
                        .disabled(harness.testSet == nil || !harness.modelReady || harness.running)
                    if harness.done > 0 {
                        ShareLink("Share results", item: harness.report)
                    }
                }
                if harness.done > 0 {
                    Section("Results") {
                        Text(harness.report).font(.body.monospaced()).textSelection(.enabled)
                    }
                }
                Section("Log") {
                    ForEach(Array(harness.log.enumerated()), id: \.offset) { Text($0.element).font(.footnote) }
                }
            }
            .navigationTitle("ML Kit Harness")
            .task {
                if let path = ProcessInfo.processInfo.environment["HARNESS_TESTSET"] {
                    await harness.autorun(path)
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                if case let .success(url) = result { harness.load(url) }
            }
        }
    }
}

@main
struct HarnessApp: App {
    var body: some Scene {
        WindowGroup { HarnessView() }
    }
}
