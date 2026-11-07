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

/// Draw-to-search state. The KanjiVG matcher answers every drawing.
@MainActor
@Observable
public final class HandwritingSearchModel {
    public nonisolated static let matchLimit = 5

    public private(set) var pad = HandwritingPad()
    private(set) var matches: [String] = []
    @ObservationIgnored private(set) var recognitionTask: Task<Void, Never>?

    private var matcher: HandwritingTemplateMatcher?
    private var templatesFailed = false
    private var isLoadingTemplates = false
    private var generation = 0

    private let loadMatcher: @Sendable () throws -> HandwritingTemplateMatcher

    private nonisolated static let logger = Logger(subsystem: "com.aten.nichiji", category: "handwriting")

    public init(loadMatcher: @escaping @Sendable () throws -> HandwritingTemplateMatcher) {
        self.loadMatcher = loadMatcher
    }

    /// The app's model, matching against the bundled templates.
    public static func live(contentStore: any KanjiContentStore) -> HandwritingSearchModel {
        HandwritingSearchModel {
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

    /// Runs each time the sheet appears and loads the templates once.
    public func open() async {
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
            return
        }
        let request = generation
        let ink = pad.ink
        recognitionTask = Task { [weak self] in
            await self?.recognize(ink, with: matcher, request: request)
        }
    }

    private func recognize(_ ink: HandwritingInk, with matcher: HandwritingTemplateMatcher, request: Int) async {
        let strokes = ink.strokes.map { $0.map(\.cgPoint) }
        let limit = Self.matchLimit
        let found = await Task.detached(priority: .userInitiated) {
            matcher.candidates(for: strokes, limit: limit)
        }.value
        guard request == generation else { return }
        matches = found
        Self.logger.info("\(found.count) matches")
    }
}
