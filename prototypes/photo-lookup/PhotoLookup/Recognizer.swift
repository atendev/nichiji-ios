import Foundation
import ImageIO
import Vision

struct RecognizedLine: Codable, Hashable, Sendable {
    var text: String
    var confidence: Float
}

struct Recognition: Sendable {
    var lines: [RecognizedLine]
    var seconds: Double
}

enum RecognizerError: Error {
    case unreadableImage
}

/// Apple Vision text recognition, set the way the shipped feature would set it: accurate, Japanese first.
enum Recognizer {
    static let languages = ["ja-JP", "en-US"]

    static func supportedLanguages() -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        return (try? request.supportedRecognitionLanguages()) ?? []
    }

    static func recognize(imageData: Data) async throws -> Recognition {
        try await Task.detached(priority: .userInitiated) { try run(imageData) }.value
    }

    private static func run(_ data: Data) throws -> Recognition {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw RecognizerError.unreadableImage
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let rawOrientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up

        let start = Date()
        let lines = try read(VNImageRequestHandler(cgImage: image, orientation: orientation))
        return Recognition(lines: lines, seconds: Date().timeIntervalSince(start))
    }

    private static func read(_ handler: VNImageRequestHandler) throws -> [RecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = true
        try handler.perform([request])
        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return RecognizedLine(text: candidate.string, confidence: candidate.confidence)
        }
    }
}
