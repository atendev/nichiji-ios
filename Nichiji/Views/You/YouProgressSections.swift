import SwiftUI

/*-------------------------------milestones-------------------------------*/

struct MilestonesCard: View {
    let milestones: [Milestone]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Milestones")
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(YouCopy.milestoneCount(milestones))
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkSubtle)
            }
            .padding(.bottom, LayoutTokens.space4)

            ForEach(Array(milestones.map(YouCopy.milestoneRow).enumerated()), id: \.offset) { index, row in
                if index > 0 {
                    Divider().overlay(Color.nichijiHairline)
                }
                rowView(row)
            }
        }
        .padding(LayoutTokens.space24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private func rowView(_ row: MilestoneRow) -> some View {
        HStack(spacing: LayoutTokens.space12) {
            badge(isEarned: row.isEarned)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space8) {
                    Text(row.title)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)
                    Spacer(minLength: 0)
                    Text(row.note)
                        .font(.nichijiCaption)
                        .monospacedDigit()
                        .foregroundColor(.nichijiInkMuted)
                }
                if !row.isEarned {
                    ProgressCapsule(fraction: row.progress, fill: .nichijiBorderControl, height: 6)
                }
            }
        }
        .padding(.vertical, LayoutTokens.space8)
        .frame(minHeight: LayoutTokens.minHitTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.isEarned ? "\(row.title), earned" : "\(row.title), locked, \(row.note)")
    }

    /// Earned shows the matcha seal mark; locked shows a padlock.
    private func badge(isEarned: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(isEarned ? Color.nichijiMatchaWash : Color.nichijiSurfaceSunken)
            .frame(width: 40, height: 40)
            .overlay {
                if isEarned {
                    ZStack {
                        Circle()
                            .stroke(Color.nichijiMatcha, lineWidth: 1.5)
                        Image(systemName: "checkmark")
                            .font(.nichijiCaption.weight(.semibold))
                            .foregroundColor(.nichijiMatcha)
                    }
                    .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "lock")
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkSubtle)
                }
            }
            .accessibilityHidden(true)
    }
}

/*----------------------------needs-attention-----------------------------*/

struct NeedsAttentionCard: View {
    let items: [NeedsAttentionItem]
    let meanings: [String: String]

    private static var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: LayoutTokens.space8), count: 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Needs attention")
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)
            Text("Kanji you forget most often.")
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .padding(.top, LayoutTokens.space4)
                .padding(.bottom, LayoutTokens.space12)

            if let message = YouCopy.needsAttentionMessage(items) {
                Text(message)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkSubtle)
            } else {
                LazyVGrid(columns: Self.columns, spacing: LayoutTokens.space8) {
                    ForEach(items, id: \.kanjiID) { item in
                        tile(item)
                    }
                }
            }
        }
        .padding(LayoutTokens.space24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private func tile(_ item: NeedsAttentionItem) -> some View {
        let note = YouCopy.forgotNote(item.forgotCount)
        return NavigationLink(value: KanjiDetailRoute(kanjiID: item.kanjiID)) {
            VStack(spacing: LayoutTokens.space4) {
                Text(item.kanjiID)
                    .font(.kanjiDisplay(size: 40))
                    .foregroundColor(.nichijiInk)
                Text(note)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }
            .frame(maxWidth: .infinity, minHeight: LayoutTokens.minHitTarget)
            .padding(.vertical, LayoutTokens.space12)
            .padding(.horizontal, LayoutTokens.space8)
            .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurface, stroke: .nichijiBorderControl)
            .contentShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(KanjiGridTile.accessibilityLabel(kanji: item.kanjiID, meaning: meanings[item.kanjiID] ?? "")), \(note)")
        .accessibilityHint("Opens kanji details")
    }
}
