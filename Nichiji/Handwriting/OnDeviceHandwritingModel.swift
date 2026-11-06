import Foundation

/*-------------------------------protocols--------------------------------*/

/// The on-device recognizer seam. ML Kit implements it on device; the Simulator and tests have none, or a fake.
@MainActor
public protocol OnDeviceHandwritingModel: AnyObject {
    /// Whether the recognition model is on device and can answer now.
    var isModelReady: Bool { get }

    /// Starts the model download if it is missing and waits for it. Returns whether the model is ready.
    func prepareModel() async -> Bool

    /// Recognizes the ink, best candidate first. Throws when the model is unavailable or recognition fails.
    func candidates(for ink: HandwritingInk, limit: Int) async throws -> [String]
}

/// Which recognizer produced the current matches.
public enum HandwritingRecognizerSource: Equatable, Sendable {
    case matcher
    case onDevice

    var logName: String {
        switch self {
        case .matcher: "matcher"
        case .onDevice: "mlkit"
        }
    }
}

public enum HandwritingRecognitionError: Error, Equatable {
    case modelUnavailable
}

/*--------------------------------factory---------------------------------*/

public enum OnDeviceHandwritingModelFactory {
    /// ML Kit has no arm64 Simulator slice, so the Simulator gets no on-device model and uses the matcher.
    @MainActor
    public static func make() -> (any OnDeviceHandwritingModel)? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return MLKitHandwritingModel()
        #endif
    }
}
