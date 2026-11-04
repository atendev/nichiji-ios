import SwiftUI

/*---------------------------------tiles----------------------------------*/

struct StatTilesGrid: View {
    let tiles: [StatTile]

    var body: some View {
        Grid(horizontalSpacing: LayoutTokens.space8, verticalSpacing: LayoutTokens.space8) {
            ForEach(Array(stride(from: 0, to: tiles.count, by: 2)), id: \.self) { start in
                GridRow {
                    ForEach(tiles[start..<min(start + 2, tiles.count)], id: \.label) { tile in
                        tileView(tile)
                    }
                }
            }
        }
    }

    private func tileView(_ tile: StatTile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(tile.value)
                .font(.uiText(size: 32, weight: .medium))
                .monospacedDigit()
                .foregroundColor(.nichijiInk)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(tile.label)
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkMuted)
        }
        .padding(LayoutTokens.space16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tile.label), \(tile.value == "–" ? "none yet" : tile.value)")
    }
}

/*---------------------------------freeze---------------------------------*/

struct FreezeRow: View {
    let copy: FreezeRowCopy

    var body: some View {
        HStack(spacing: LayoutTokens.space12) {
            Image(systemName: "shield")
                .imageScale(.large)
                .foregroundColor(copy.isReady ? .nichijiMatcha : .nichijiInkSubtle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(copy.title)
                    .font(.nichijiCallout.weight(.medium))
                    .foregroundColor(.nichijiInk)
                Text(copy.note)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LayoutTokens.space16)
        .padding(.vertical, LayoutTokens.space12)
        .frame(minHeight: LayoutTokens.minHitTarget)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
        .accessibilityElement(children: .combine)
    }
}

/*--------------------------------activity--------------------------------*/

struct ActivityCard: View {
    let weeks: [[ActivityCell]]

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Activity")
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("Last 12 weeks")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkSubtle)
            }

            grid
            legend
        }
        .padding(LayoutTokens.space24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private var grid: some View {
        HStack(alignment: .top, spacing: LayoutTokens.space4) {
            ForEach(weeks.indices, id: \.self) { column in
                VStack(spacing: LayoutTokens.space4) {
                    ForEach(weeks[column], id: \.calendarDay) { cell in
                        square(Self.color(for: cell.shade))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(YouCopy.activitySummary(weeks))
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Spacer()
            Text("Less")
            ForEach(0..<5, id: \.self) { shade in
                square(Self.color(for: shade))
                    .frame(width: 12, height: 12)
            }
            Text("More")
        }
        .font(.nichijiCaption)
        .foregroundColor(.nichijiInkSubtle)
        .accessibilityHidden(true)
    }

    private func square(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .aspectRatio(1, contentMode: .fit)
    }

    /// Five steps from the sunken surface to matcha; days after today stay blank.
    static func color(for shade: Int?) -> Color {
        guard let shade else { return .clear }
        switch shade {
        case 0: return .nichijiSurfaceSunken
        case 1: return .nichijiMatchaWash
        case 2: return Color.nichijiMatcha.opacity(0.45)
        case 3: return Color.nichijiMatcha.opacity(0.7)
        default: return .nichijiMatcha
        }
    }
}

/*--------------------------------by-level--------------------------------*/

struct LevelBarsCard: View {
    let rows: [LevelBarRow]

    @ScaledMetric(relativeTo: .callout) private var codeWidth: CGFloat = 36

    init(rows: [LevelBarRow]) {
        self.rows = rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text("By level")
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)

            ForEach(rows, id: \.id) { row in
                rowView(row)
            }
        }
        .padding(LayoutTokens.space24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private func rowView(_ row: LevelBarRow) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space8) {
                if let code = row.code {
                    Text(code)
                        .font(.nichijiCallout.weight(.medium))
                        .foregroundColor(.nichijiInk)
                        .frame(width: codeWidth, alignment: .leading)
                }
                Text(row.name)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
                Spacer(minLength: LayoutTokens.space8)
                Text(row.count)
                    .font(.nichijiCallout)
                    .monospacedDigit()
                    .foregroundColor(.nichijiInk)
            }
            ProgressCapsule(fraction: row.fraction, fill: .nichijiMatcha, height: 8)
        }
        .padding(.vertical, LayoutTokens.space8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\([row.code, row.name].compactMap { $0 }.joined(separator: " ")), \(row.count) learned")
    }
}

/*--------------------------------capsule---------------------------------*/

/// A thin bar filled to a fraction, used by By level and the locked milestones.
struct ProgressCapsule: View {
    let fraction: Double
    let fill: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.nichijiSurfaceSunken)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(fill)
                        .frame(width: proxy.size.width * min(max(fraction, 0), 1))
                }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
