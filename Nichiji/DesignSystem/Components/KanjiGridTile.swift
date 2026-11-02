import SwiftUI

private struct SelectionCellBackground: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .fill(isSelected ? Color.nichijiVermilionWash : Color.nichijiSurfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(isSelected ? Color.nichijiVermilion : Color.nichijiBorderControl, lineWidth: 1)
            )
    }
}

extension View {
    func selectionCellBackground(isSelected: Bool) -> some View {
        modifier(SelectionCellBackground(isSelected: isSelected))
    }
}

/*-----------------------------kanji-grid-tile----------------------------*/

/// Square kanji cell shared by the Dictionary browse grid and the custom kanji picker.
public struct KanjiGridTile: View {
    public let kanji: String
    public let isSelected: Bool

    /// Tiles never shrink below the 44 pt hit target, even in narrow columns.
    public static let minimumSide: CGFloat = LayoutTokens.minHitTarget
    /// Same gap between columns and between rows.
    public static let spacing: CGFloat = LayoutTokens.space12
    public static let columnCount = 5

    public static var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    public init(kanji: String, isSelected: Bool = false) {
        self.kanji = kanji
        self.isSelected = isSelected
    }

    public var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(minWidth: Self.minimumSide, minHeight: Self.minimumSide)
            .overlay {
                Text(kanji)
                    .font(.kanjiDisplay(size: 30))
                    .foregroundColor(.nichijiInk)
            }
            .selectionCellBackground(isSelected: isSelected)
    }

    /// VoiceOver reads the glyph, then its meaning when one is known.
    public static func accessibilityLabel(kanji: String, meaning: String) -> String {
        meaning.isEmpty ? kanji : "\(kanji), \(meaning)"
    }
}
