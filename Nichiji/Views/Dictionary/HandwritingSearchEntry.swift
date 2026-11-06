import SwiftUI

/*---------------------------------entry----------------------------------*/

/// What a tap on "Draw a kanji to search" does.
enum HandwritingSearchEntry {
    case paywall(ProFeature)
    case pad(HandwritingSearchModel)

    /// Locked, the paywall opens and no model is made, so nothing downloads. Unlocked, the existing model is reused.
    @MainActor
    static func open(
        access: ProAccess,
        existing: HandwritingSearchModel?,
        makeModel: () -> HandwritingSearchModel
    ) -> HandwritingSearchEntry {
        guard access.allows(.handwritingSearch) else { return .paywall(.handwritingSearch) }
        return .pad(existing ?? makeModel())
    }
}

/*----------------------------------copy----------------------------------*/

enum HandwritingSearchCopy {
    static let buttonTitle = "Draw a kanji to search"
    static let buttonHint = "Opens a pad to draw a kanji"
    static let sheetTitle = "Draw to search"
    static let placeholder = "Draw a kanji here"
    static let matchesHeader = "Matches"
    static let preparing = "Preparing"
    static let unavailable = "Handwriting search is unavailable."
    static let noMatches = "No matches yet. Keep drawing."

    static func tileLabel(kanji: String) -> String {
        "Search for \(kanji)"
    }

    static func padLabel(strokeCount: Int) -> String {
        strokeCount == 1 ? "Drawing pad, 1 stroke" : "Drawing pad, \(strokeCount) strokes"
    }

    /// Debug builds show which recognizer answered, for the on-device check.
    static func recognizerNote(_ source: HandwritingRecognizerSource) -> String {
        switch source {
        case .matcher: "Recognizer: matcher"
        case .onDevice: "Recognizer: ML Kit"
        }
    }
}

/*---------------------------------layout---------------------------------*/

enum HandwritingSearchLayout {
    static let buttonMinHeight = LayoutTokens.minHitTarget
    static let controlMinSide = LayoutTokens.minHitTarget
    /// The design's match row height.
    static let tileMinSide: CGFloat = 56
    static let tileCount = HandwritingSearchModel.matchLimit
    static let padMaxSide: CGFloat = 420
    /// Proportions of the 342 pt pad in the design.
    static let inkWidthRatio: CGFloat = 7 / 342
    static let crosshairInsetRatio: CGFloat = 6 / 342
}

/*---------------------------------button---------------------------------*/

/// The full-width button under `DictionarySearchBar`.
struct DrawSearchButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space8) {
                Image(systemName: "pencil.and.scribble")
                    .accessibilityHidden(true)
                Text(HandwritingSearchCopy.buttonTitle)
            }
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .frame(maxWidth: .infinity)
            .frame(minHeight: HandwritingSearchLayout.buttonMinHeight)
            .padding(.horizontal, LayoutTokens.space16)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(Color.nichijiBorderControl, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(HandwritingSearchCopy.buttonTitle)
        .accessibilityHint(HandwritingSearchCopy.buttonHint)
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.bottom, LayoutTokens.space8)
    }
}
