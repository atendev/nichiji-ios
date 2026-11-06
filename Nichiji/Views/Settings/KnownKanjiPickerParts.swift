import SwiftUI

/*--------------------------------cell------------------------------------*/

/// One kanji tile in the Known kanji picker. Studied kanji are dimmed and cannot be toggled.
struct KnownKanjiCell: View {
    let kanjiID: String
    let meaning: String
    let levelLabel: String?
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        let spoken = KanjiGridTile.accessibilityLabel(kanji: kanjiID, meaning: meaning)

        Button(action: action) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    KanjiGridTile(kanji: kanjiID, isSelected: isSelected)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.nichijiVermilion)
                            .padding(6)
                    }
                }

                if let levelLabel {
                    Text(levelLabel)
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .buttonStyle(.plain)
        .minTouchTarget()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(isEnabled ? spoken : "\(spoken), already studying")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/*-------------------------------group-header-----------------------------*/

/// Group title with its known count and, when the group has kanji to mark, a Select all / Clear all button.
struct KnownKanjiGroupHeader: View {
    let title: String
    let detail: String
    let showsButton: Bool
    let isAllSelected: Bool
    let onToggleAll: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: LayoutTokens.space12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)

                Text(detail)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }

            Spacer()

            if showsButton {
                Button(action: onToggleAll) {
                    Text(isAllSelected ? "Clear all" : "Select all")
                        .font(.uiText(size: 12, weight: .medium))
                        .foregroundColor(.nichijiInk)
                        .padding(.horizontal, LayoutTokens.space12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                                .stroke(Color.nichijiBorderControl, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .minTouchTarget()
                .accessibilityLabel("\(isAllSelected ? "Clear all" : "Select all") in \(title)")
            }
        }
    }
}

/*-------------------------------bottom-bar-------------------------------*/

/// Count of marked kanji and the Done button.
struct KnownKanjiBottomBar: View {
    let count: Int
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: LayoutTokens.space16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) known")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)

                Text("Kanji you study or review stay as they are.")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiOnVermilion)
                    .padding(.horizontal, LayoutTokens.space24)
                    .frame(minWidth: 120, minHeight: 48)
                    .background(Color.nichijiVermilion)
                    .continuousCornerRadius(LayoutTokens.cornerRadiusSmall)
            }
            .buttonStyle(.plain)
            .minTouchTarget()
            .accessibilityLabel("Done choosing known kanji")
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.vertical, LayoutTokens.space12)
        .background(Color.nichijiSurfaceRaised)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.nichijiHairline)
                .frame(height: 1)
        }
    }
}
