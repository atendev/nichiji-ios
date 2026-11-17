import ImageIO
import UIKit
import Vision
import VisionKit

/*--------------------------------protocols---------------------------------*/

/// Reads the text in a photo. The app's reader runs on device; tests swap in a stub.
protocol PhotoTextReader: Sendable {
    func read(imageData: Data) async throws -> PhotoTextReading
}

enum PhotoTextError: Error, Equatable {
    case unreadableImage
}

/*---------------------------------reader-----------------------------------*/

/// Vision first (accurate, Japanese then English), then Live Text when Vision reads under four characters.
struct SystemPhotoTextReader: PhotoTextReader {
    static let languages = ["ja-JP", "en-US"]

    func read(imageData: Data) async throws -> PhotoTextReading {
        let vision = await Task.detached(priority: .userInitiated) {
            Result { try Self.visionLines(imageData) }
        }.value
        let visionLines = (try? vision.get()) ?? []
        let visionBoxes = visionLines.map(\.boxes)
        let visionText = visionLines.map(\.text)
        guard PhotoTextReading.needsLiveText(visionLines: visionText) else {
            return PhotoTextReading(visionLines: visionText, liveTextLines: [], visionBoxes: visionBoxes)
        }
        let liveTextLines = await Self.liveTextLines(imageData)
        // A Vision failure only matters when Live Text found nothing to cover for it.
        if case .failure(let error) = vision, liveTextLines.isEmpty {
            throw error
        }
        return PhotoTextReading(visionLines: visionText, liveTextLines: liveTextLines, visionBoxes: visionBoxes)
    }

    private struct VisionLine: Sendable {
        let text: String
        let boxes: [CGRect?]
    }

    private static func visionLines(_ data: Data) throws -> [VisionLine] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw PhotoTextError.unreadableImage
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let rawOrientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = true
        try VNImageRequestHandler(cgImage: image, orientation: orientation).perform([request])
        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return VisionLine(text: candidate.string, boxes: characterBoxes(of: candidate))
        }
    }

    /// One box per character, flipped to a top-left origin. A character Vision cannot box stays nil.
    private static func characterBoxes(of candidate: VNRecognizedText) -> [CGRect?] {
        let text = candidate.string
        return text.indices.map { start in
            let range = start..<text.index(after: start)
            guard let box = try? candidate.boundingBox(for: range)?.boundingBox else { return nil }
            return PhotoBox.topLeftOrigin(fromVision: box)
        }
    }

    /// Live Text is a backup, so any failure reads as no text rather than an error.
    @MainActor
    private static func liveTextLines(_ data: Data) async -> [String] {
        guard ImageAnalyzer.isSupported, let image = UIImage(data: data) else { return [] }
        guard let analysis = try? await ImageAnalyzer().analyze(image, configuration: ImageAnalyzer.Configuration(.text)) else {
            return []
        }
        return analysis.transcript.split(whereSeparator: \.isNewline).map(String.init)
    }
}
