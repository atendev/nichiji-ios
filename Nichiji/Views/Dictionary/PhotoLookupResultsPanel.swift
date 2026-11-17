import SwiftUI

/*-------------------------------results----------------------------------*/

/// The panel over the frozen shot: reading, then the found count, "New to you" and the grid, with Retake.
struct PhotoLookupResultsPanel: View {
    @Bindable var model: PhotoLookupModel
    let maxHeight: CGFloat
    let onPick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space16) {
            HStack(alignment: .center, spacing: LayoutTokens.space12) {
                panelStatus
                Spacer(minLength: LayoutTokens.space8)
                Button {
                    model.retake()
                } label: {
                    Label(PhotoLookupCopy.retake, systemImage: "arrow.counterclockwise")
                        .font(.nichijiCallout.weight(.medium))
                        .foregroundColor(.nichijiInk)
                        .padding(.horizontal, LayoutTokens.space16)
                        .frame(minHeight: LayoutTokens.minHitTarget)
                        .background(Capsule().fill(Color.nichijiSurfaceSunken))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint(PhotoLookupCopy.retakeHint)
            }

            if model.state == .found {
                Toggle(PhotoLookupCopy.newToYou, isOn: $model.showsNewOnly)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInk)
                    .tint(.nichijiVermilion)
                    .frame(minHeight: LayoutTokens.minHitTarget)
            }

            panelBody
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.top, LayoutTokens.space24)
        .padding(.bottom, LayoutTokens.space16)
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: LayoutTokens.cornerRadiusLarge,
                topTrailingRadius: LayoutTokens.cornerRadiusLarge,
                style: .continuous
            )
            .fill(Color.nichijiSurfaceRaised)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder private var panelStatus: some View {
        switch model.state {
        case .reading, .empty:
            HStack(spacing: LayoutTokens.space12) {
                ProgressView()
                Text(PhotoLookupCopy.reading)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }
            .accessibilityElement(children: .combine)
        case .found:
            Text(PhotoLookupCopy.foundCount(model.kanji.count))
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)
        case .noKanji:
            note(PhotoLookupCopy.noKanji)
        case .failed:
            note(PhotoLookupCopy.failed)
        }
    }

    @ViewBuilder private var panelBody: some View {
        if model.state == .found {
            if model.filterHidesEverything {
                note(PhotoLookupCopy.allStarted)
            } else {
                // The panel hugs a short grid and scrolls a long one.
                ViewThatFits(in: .vertical) {
                    kanjiGrid
                    ScrollView(showsIndicators: false) {
                        kanjiGrid
                    }
                }
            }
        }
    }

    private var kanjiGrid: some View {
        LazyVGrid(columns: KanjiGridTile.columns, spacing: KanjiGridTile.spacing) {
            ForEach(model.visibleKanji, id: \.self) { id in
                Button {
                    onPick(id)
                } label: {
                    KanjiGridTile(kanji: id)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(id)
                .accessibilityHint("Opens kanji details")
            }
        }
        .padding(.bottom, LayoutTokens.space8)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.nichijiCallout)
            .foregroundColor(.nichijiInkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}
