import SwiftUI

/*----------------------------------card----------------------------------*/

public struct KanjiCard<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            content
        }
        .padding(LayoutTokens.space16)
        .background(Color.nichijiSurfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusMedium, style: .continuous)
                .stroke(Color.nichijiHairline, lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
    }
}
