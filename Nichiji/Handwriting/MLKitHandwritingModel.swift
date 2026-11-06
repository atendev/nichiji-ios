#if !targetEnvironment(simulator)
import Foundation
@preconcurrency import MLKitDigitalInkRecognition

/*---------------------------------model----------------------------------*/

/// ML Kit Digital Ink (`ja`) on device. The pods ship no arm64 Simulator slice, so this compiles for devices only.
/// Every ML Kit object stays on the main actor.
@MainActor
final class MLKitHandwritingModel: OnDeviceHandwritingModel {
    /// The writing area ML Kit is told about; unit pad coordinates are scaled to it.
    private static let writingAreaSide: Float = 360

    private(set) var isModelReady = false

    private let model: DigitalInkRecognitionModel?
    private var recognizer: DigitalInkRecognizer?
    private var downloadWaiters: [CheckedContinuation<Bool, Never>] = []
    private var observers: [NSObjectProtocol] = []

    init() {
        // Typed optional so this compiles whether or not the initializer is failable.
        let identifier: DigitalInkRecognitionModelIdentifier? = DigitalInkRecognitionModelIdentifier(forLanguageTag: "ja")
        model = identifier.map { DigitalInkRecognitionModel(modelIdentifier: $0) }
        if let model {
            isModelReady = ModelManager.modelManager().isModelDownloaded(model)
        }
        observeDownloads()
    }

    func prepareModel() async -> Bool {
        guard let model else { return false }
        if isModelReady || ModelManager.modelManager().isModelDownloaded(model) {
            isModelReady = true
            return true
        }
        return await withCheckedContinuation { continuation in
            downloadWaiters.append(continuation)
            guard downloadWaiters.count == 1 else { return }
            let conditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
            _ = ModelManager.modelManager().download(model, conditions: conditions)
        }
    }

    func candidates(for ink: HandwritingInk, limit: Int) async throws -> [String] {
        guard let model, isModelReady else { throw HandwritingRecognitionError.modelUnavailable }
        let recognizer = recognizer ?? DigitalInkRecognizer.digitalInkRecognizer(options: DigitalInkRecognizerOptions(model: model))
        self.recognizer = recognizer
        let side = Self.writingAreaSide
        let strokes = ink.strokes.map { stroke in
            Stroke(points: stroke.map { StrokePoint(x: Float($0.x) * side, y: Float($0.y) * side, t: $0.t) })
        }
        let context = DigitalInkRecognitionContext(preContext: "", writingArea: WritingArea(width: side, height: side))
        let texts: [String] = try await withCheckedThrowingContinuation { continuation in
            recognizer.recognize(ink: Ink(strokes: strokes), context: context) { @Sendable result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result?.candidates.map(\.text) ?? [])
                }
            }
        }
        return Array(texts.prefix(limit))
    }

    /*-------------------------------download-----------------------------*/

    /// ML Kit posts on the main queue, so the blocks run on the main actor.
    private func observeDownloads() {
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: .mlkitModelDownloadDidSucceed, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.finishDownload() }
            },
            center.addObserver(forName: .mlkitModelDownloadDidFail, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.finishDownload() }
            }
        ]
    }

    private func finishDownload() {
        if let model {
            isModelReady = ModelManager.modelManager().isModelDownloaded(model)
        }
        let waiters = downloadWaiters
        downloadWaiters = []
        for waiter in waiters {
            waiter.resume(returning: isModelReady)
        }
    }
}
#endif
