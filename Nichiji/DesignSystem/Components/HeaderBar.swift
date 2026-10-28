import SwiftUI

/*---------------------------------header---------------------------------*/

public struct HeaderBar<TrailingContent: View>: View {
    public let kanjiTitle: String
    public let englishTitle: String
    public let trailing: TrailingContent

    public init(
        kanjiTitle: String,
        englishTitle: String,
        @ViewBuilder trailing: () -> TrailingContent = { EmptyView() }
    ) {
        self.kanjiTitle = kanjiTitle
        self.englishTitle = englishTitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: LayoutTokens.space8) {
            Text(kanjiTitle)
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)

            Text("|")
                .foregroundColor(.nichijiInkSubtle)

            Text(englishTitle)
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)

            Spacer()

            trailing
        }
        .padding(.horizontal, LayoutTokens.space16)
        .frame(minHeight: LayoutTokens.minHitTarget)
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Connect the standard header bar across Today, Dictionary, Review, and You views in Slice 6.
