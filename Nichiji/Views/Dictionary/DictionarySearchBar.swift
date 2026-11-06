import SwiftUI

/*-------------------------------search-bar-------------------------------*/

/// Search field above the browse grid. Typing is read by `DictionaryView`, which debounces and searches.
struct DictionarySearchBar: View {
    @Binding var text: String
    var placeholder = "Search kanji, words, readings"
    var accessibilityName = "Search the dictionary"

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: LayoutTokens.space8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.nichijiInkMuted)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)
                .focused($isFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { isFocused = false }
                .accessibilityLabel(accessibilityName)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.nichijiInkMuted)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
                .minTouchTarget()
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, LayoutTokens.space16)
        .padding(.trailing, text.isEmpty ? LayoutTokens.space16 : 0)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .stroke(Color.nichijiBorderControl, lineWidth: 1)
        )
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.top, LayoutTokens.space8)
        .padding(.bottom, LayoutTokens.space8)
    }
}
