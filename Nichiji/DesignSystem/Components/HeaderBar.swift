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
        .accessibilityElement(children: .contain)
    }
}

/*--------------------------------caption---------------------------------*/

/// Small tracked caps line under a `HeaderBar` ("LEARNING SINCE SEP 2026").
public struct HeaderCaption: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.uiText(size: 11, weight: .medium))
            .tracking(0.66)
            .foregroundColor(.nichijiInkSubtle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutTokens.space16)
            .padding(.top, LayoutTokens.space4)
    }
}
