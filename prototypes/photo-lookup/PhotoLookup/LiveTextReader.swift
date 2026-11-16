import UIKit
import VisionKit

/// Live Text, the engine behind tap-to-select text in Photos. Read next to Vision to compare them on the same photo.
enum LiveTextReader {
    @MainActor
    static func read(imageData: Data) async -> LiveTextResult {
        guard ImageAnalyzer.isSupported else { return LiveTextResult(lines: [], error: "Live Text is not supported on this device") }
        guard let image = UIImage(data: imageData) else { return LiveTextResult(lines: [], error: "Photo could not be decoded") }
        do {
            let analysis = try await ImageAnalyzer().analyze(image, configuration: ImageAnalyzer.Configuration(.text))
            let lines = analysis.transcript.split(whereSeparator: \.isNewline).map(String.init)
            return LiveTextResult(lines: lines, error: nil)
        } catch {
            return LiveTextResult(lines: [], error: String(describing: error))
        }
    }
}

struct LiveTextResult: Codable, Hashable, Sendable {
    var lines: [String]
    var error: String?
}
