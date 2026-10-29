import SwiftUI

/*----------------------------selectable-card-----------------------------*/

struct SelectableCard: ViewModifier {
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
    func selectableCard(isSelected: Bool) -> some View {
        modifier(SelectableCard(isSelected: isSelected))
    }
}
