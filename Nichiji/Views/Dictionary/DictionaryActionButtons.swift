import SwiftUI

/*--------------------------------buttons---------------------------------*/

/// "Draw a kanji" and "Scan a kanji", side by side under the search bar. They stack at accessibility text sizes.
struct DictionaryActionButtons: View {
    let onDraw: () -> Void
    let onScan: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: LayoutTokens.space8))
            : AnyLayout(HStackLayout(spacing: LayoutTokens.space8))

        layout {
            DictionaryActionButton(
                systemName: "pencil.and.scribble",
                title: HandwritingSearchCopy.buttonTitle,
                hint: HandwritingSearchCopy.buttonHint,
                action: onDraw
            )
            DictionaryActionButton(
                systemName: "camera",
                title: PhotoLookupCopy.buttonTitle,
                hint: PhotoLookupCopy.buttonHint,
                action: onScan
            )
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.bottom, LayoutTokens.space8)
    }
}

private struct DictionaryActionButton: View {
    let systemName: String
    let title: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space8) {
                Image(systemName: systemName)
                    .accessibilityHidden(true)
                Text(title)
                    .multilineTextAlignment(.center)
            }
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .frame(maxWidth: .infinity)
            .frame(minHeight: LayoutTokens.minHitTarget)
            .padding(.horizontal, LayoutTokens.space12)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(Color.nichijiBorderControl, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
