import Foundation
@testable import Nichiji

/// A scripted on-device recognizer. Holding a call parks it until the test releases it.
@MainActor
final class TestOnDeviceHandwritingModel: OnDeviceHandwritingModel {
    struct Failure: Error {}

    var isModelReady: Bool
    /// What successive `prepareModel()` calls report; an empty script reports a failed download.
    var prepareResults: [Bool]
    var candidatesResult: Result<[String], Failure> = .success([])
    var holdsPrepare = false
    var holdsCandidates = false

    private(set) var prepareCalls = 0
    private(set) var candidateCalls = 0
    private(set) var lastInk: HandwritingInk?
    private var heldPrepares: [CheckedContinuation<Void, Never>] = []
    private var heldCandidates: [CheckedContinuation<Void, Never>] = []

    init(isModelReady: Bool = false, prepareResults: [Bool] = []) {
        self.isModelReady = isModelReady
        self.prepareResults = prepareResults
    }

    var hasHeldPrepare: Bool { !heldPrepares.isEmpty }
    var hasHeldCandidates: Bool { !heldCandidates.isEmpty }

    func prepareModel() async -> Bool {
        prepareCalls += 1
        if holdsPrepare {
            await withCheckedContinuation { heldPrepares.append($0) }
        }
        let isReady = prepareResults.isEmpty ? false : prepareResults.removeFirst()
        isModelReady = isReady
        return isReady
    }

    func candidates(for ink: HandwritingInk, limit: Int) async throws -> [String] {
        candidateCalls += 1
        lastInk = ink
        if holdsCandidates {
            await withCheckedContinuation { heldCandidates.append($0) }
        }
        return Array(try candidatesResult.get().prefix(limit))
    }

    func releasePrepare() {
        let held = heldPrepares
        heldPrepares = []
        held.forEach { $0.resume() }
    }

    func releaseCandidates() {
        let held = heldCandidates
        heldCandidates = []
        held.forEach { $0.resume() }
    }
}
