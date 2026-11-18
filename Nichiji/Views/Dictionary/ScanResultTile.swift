import SwiftUI

/*---------------------------------copy-----------------------------------*/

extension PhotoLookupCopy {
    static let newOnly = "New only"
    static let newOnlyHint = "Shows only the kanji that are new to you"
    static let nothingNew = "Nothing new here. You have already learned every kanji in this photo."
    static let newTag = "NEW"
    static let learnedMark = "Already learned"
    static let tileHint = "Opens kanji details"
    static let sheetLabel = "Recognized kanji"
    static let swipeUp = "Swipe up"
    static let peekHint = "Opens the list of kanji found"
    static let sheetSize = "Results size"
    static let yourPhoto = "Your photo"
    static let scannedJustNow = "Scanned just now"
    static let viewPhoto = "View photo"
    static let backToPhoto = "Back to photo"
    static let scanTitle = "Scan"
    static let scanKanji = "\u{5199}"

    static func newLine(_ count: Int) -> String {
        "\(count) new to you"
    }

    /// "X new to you · Y learned", or "Showing X new" with the filter on.
    static func subtitle(new: Int, learned: Int, newOnly: Bool) -> String {
        newOnly ? "Showing \(new) new" : "\(new) new to you \u{00B7} \(learned) learned"
    }

    static func tileLabel(kanji: String, meaning: String, isNew: Bool) -> String {
        let base = meaning.isEmpty ? "Kanji \(kanji)" : "Kanji \(kanji), \(meaning)"
        return "\(base), \(isNew ? "new to you" : "already learned")"
    }

    static func sheetValue(_ state: ScanSheetState) -> String {
        switch state {
        case .peek: return "Collapsed"
        case .half: return "Half open"
        case .full: return "Full screen"
        }
    }
}

/*---------------------------------tile-----------------------------------*/

/// One kanji found: the glyph, its short meaning, and a NEW tag (raised tile, darker border) or a green check (quiet tile).
struct ScanResultTile: View {
    let kanji: String
    let meaning: String
    let isNew: Bool

    static let height: CGFloat = 112
    static let columns = Array(repeating: GridItem(.flexible(), spacing: LayoutTokens.space8), count: 3)

    private static let tagRadius: CGFloat = 4

    var body: some View {
        VStack(spacing: 6) {
            Text(kanji)
                .font(.kanjiDisplay(size: 44))
                .foregroundColor(isNew ? Color.nichijiInk : Color.nichijiInkMuted)
            Text(meaning)
                .font(.nichijiCaption)
                .foregroundColor(isNew ? Color.nichijiInkMuted : Color.nichijiInkSubtle)
                .lineLimit(1)
        }
        .padding(.top, 22)
        .padding(.horizontal, LayoutTokens.space8)
        .padding(.bottom, LayoutTokens.space8)
        .frame(maxWidth: .infinity, minHeight: Self.height)
        .overlay(alignment: .topLeading) {
            if isNew { newTag }
        }
        .overlay(alignment: .topTrailing) {
            if !isNew { learnedCheck }
        }
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .fill(isNew ? Color.nichijiSurfaceRaised : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .strokeBorder(isNew ? Color.nichijiBorderControl : Color.nichijiHairline, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PhotoLookupCopy.tileLabel(kanji: kanji, meaning: meaning, isNew: isNew))
        .accessibilityHint(PhotoLookupCopy.tileHint)
        .accessibilityAddTraits(.isButton)
    }

    private var newTag: some View {
        Text(PhotoLookupCopy.newTag)
            .font(.uiText(size: 11, weight: .medium))
            .tracking(0.66)
            .foregroundColor(.nichijiVermilion)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: Self.tagRadius, style: .continuous).fill(Color.nichijiVermilionWash))
            .padding(LayoutTokens.space8)
    }

    private var learnedCheck: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.nichijiMatcha)
            .padding(LayoutTokens.space8)
    }
}
