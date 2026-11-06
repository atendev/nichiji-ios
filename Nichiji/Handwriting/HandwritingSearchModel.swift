import CoreGraphics
import Foundation
import Observation
import os

/*---------------------------------state----------------------------------*/

/// What the MATCHES row shows.
public enum HandwritingMatchState: Equatable, Sendable {
    /// The matcher's templates are still loading.
    case preparing
    /// The templates failed to load, so nothing can be recognized.
    case unavailable
    /// The pad is empty.
    case waiting
    case matches([String])
}

/*---------------------------------model----------------------------------*/

/// Draw-to-search state. The KanjiVG matcher answers until the on-device model is ready; an on-device error,
/// or an on-device result with no shipped kanji, falls back to the matcher for that drawing.
@MainActor
@Observable
public final class HandwritingSearchModel {
    public nonisolated static let matchLimit = 5
    nonisolated static let onDeviceCandidateLimit = 10

    public private(set) var pad = HandwritingPad()
    public private(set) var source: HandwritingRecognizerSource = .matcher
    private(set) var matches: [String] = []
    @ObservationIgnored private(set) var recognitionTask: Task<Void, Never>?

    private var matcher: HandwritingTemplateMatcher?
    private var templatesFailed = false
    private var isLoadingTemplates = false
    private var isRequestingModel = false
    private var generation = 0

    private let onDevice: (any OnDeviceHandwritingModel)?
    private let loadMatcher: @Sendable () throws -> HandwritingTemplateMatcher

    private nonisolated static let logger = Logger(subsystem: "com.aten.nichiji", category: "handwriting")

    public init(
        onDevice: (any OnDeviceHandwritingModel)?,
        loadMatcher: @escaping @Sendable () throws -> HandwritingTemplateMatcher
    ) {
        self.onDevice = onDevice
        self.loadMatcher = loadMatcher
    }

    /// The app's model: the bundled templates, plus ML Kit on device.
    public static func live(contentStore: any KanjiContentStore) -> HandwritingSearchModel {
        HandwritingSearchModel(onDevice: OnDeviceHandwritingModelFactory.make()) {
            try HandwritingTemplateBuilder.matcher(contentStore: contentStore)
        }
    }

    public var matchState: HandwritingMatchState {
        if matcher == nil {
            return templatesFailed ? .unavailable : .preparing
        }
        return pad.strokes.isEmpty ? .waiting : .matches(matches)
    }

    /*------------------------------opening-------------------------------*/

    /// Runs each time the sheet appears: loads the templates once, and requests the model download while it is missing.
    public func open() async {
        async let templates: Void = loadTemplatesIfNeeded()
        async let model: Void = prepareOnDeviceModelIfNeeded()
        _ = await (templates, model)
    }

    private func loadTemplatesIfNeeded() async {
        guard matcher == nil, !isLoadingTemplates else { return }
        isLoadingTemplates = true
        templatesFailed = false
        let load = loadMatcher
        let result = await Task.detached(priority: .userInitiated) { Result { try load() } }.value
        isLoadingTemplates = false
        switch result {
        case .success(let loaded):
            matcher = loaded
            refresh()
        case .failure(let error):
            templatesFailed = true
            Self.logger.error("templates failed to load: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// At most one request in flight. A failed download leaves the matcher in use until the next open asks again.
    private func prepareOnDeviceModelIfNeeded() async {
        guard let onDevice, !onDevice.isModelReady, !isRequestingModel else { return }
        isRequestingModel = true
        Self.logger.info("requesting the on-device model")
        let isReady = await onDevice.prepareModel()
        isRequestingModel = false
        Self.logger.info("on-device model \(isReady ? "ready" : "unavailable", privacy: .public)")
        if isReady {
            refresh()
        }
    }

    /*-------------------------------drawing------------------------------*/

    public func beginStroke(at point: CGPoint, time: TimeInterval) {
        pad.begin(at: point, time: time)
    }

    public func extendStroke(to point: CGPoint, time: TimeInterval) {
        pad.extend(to: point, time: time)
    }

    /// Matches refresh after each finished stroke, never mid-stroke.
    public func endStroke() {
        pad.end()
        refresh()
    }

    public func undo() {
        pad.undo()
        refresh()
    }

    public func clear() {
        pad.clear()
        refresh()
    }

    /// The kanji to put in the search bar, if it is one of the current matches.
    public func choose(_ kanji: String) -> String? {
        matches.contains(kanji) ? kanji : nil
    }

    /*-----------------------------recognition----------------------------*/

    private func refresh() {
        generation += 1
        recognitionTask?.cancel()
        recognitionTask = nil
        guard let matcher, !pad.strokes.isEmpty else {
            matches = []
            source = .matcher
            return
        }
        let request = generation
        let ink = pad.ink
        recognitionTask = Task { [weak self] in
            await self?.recognize(ink, with: matcher, request: request)
        }
    }

    private func recognize(_ ink: HandwritingInk, with matcher: HandwritingTemplateMatcher, request: Int) async {
        if let found = await onDeviceMatches(for: ink, shipped: matcher.shippedKanji) {
            guard request == generation else { return }
            publish(found, from: .onDevice)
            return
        }
        let strokes = ink.strokes.map { $0.map(\.cgPoint) }
        let limit = Self.matchLimit
        let found = await Task.detached(priority: .userInitiated) {
            matcher.candidates(for: strokes, limit: limit)
        }.value
        guard request == generation else { return }
        publish(found, from: .matcher)
    }

    /// Nil means "use the matcher": no ready model, an error, or nothing shipped among the candidates.
    private func onDeviceMatches(for ink: HandwritingInk, shipped: Set<String>) async -> [String]? {
        guard let onDevice, onDevice.isModelReady else { return nil }
        do {
            let raw = try await onDevice.candidates(for: ink, limit: Self.onDeviceCandidateLimit)
            let filtered = Self.shippedCandidates(raw, shipped: shipped)
            return filtered.isEmpty ? nil : filtered
        } catch {
            Self.logger.error("on-device recognition failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func publish(_ found: [String], from newSource: HandwritingRecognizerSource) {
        matches = found
        source = newSource
        Self.logger.info("\(found.count) matches from \(newSource.logName, privacy: .public)")
    }

    /// Single shipped kanji only, deduplicated, best first, at most `matchLimit`.
    nonisolated static func shippedCandidates(_ raw: [String], shipped: Set<String>) -> [String] {
        var seen = Set<String>()
        var kept: [String] = []
        for text in raw where text.count == 1 && shipped.contains(text) && seen.insert(text).inserted {
            kept.append(text)
            if kept.count == matchLimit { break }
        }
        return kept
    }
}
