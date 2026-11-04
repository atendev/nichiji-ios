import SwiftUI

/*--------------------------------sources---------------------------------*/

/// Attribution and licence links for the bundled dataset, read from `DATA-SOURCES.md`.
public struct SourcesView: View {
    @State private var state: SourcesState?

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    Text(SourcesCopy.title)
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)

                    Text(SourcesCopy.intro)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, LayoutTokens.space8)

                switch state {
                case .loaded(let document):
                    if let attribution = document.section(SourcesCopy.attributionSection) {
                        ForEach(Array(attribution.items.enumerated()), id: \.offset) { _, item in
                            attributionCard(item)
                        }
                    }

                    if let snapshots = document.section(SourcesCopy.snapshotsSection) {
                        snapshotsSection(snapshots)
                    }
                case .missing:
                    Text(SourcesCopy.missing)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                case nil:
                    EmptyView()
                }
            }
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.bottom, LayoutTokens.space48)
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
        .navigationTitle(SourcesCopy.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if state == nil {
                state = .load(from: .main)
            }
        }
    }

    private func attributionCard(_ item: DataSourceItem) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            Text(item.text)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)
                .fixedSize(horizontal: false, vertical: true)

            if !item.links.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(item.links.enumerated()), id: \.offset) { index, link in
                        if index > 0 {
                            dividerLine
                        }
                        linkRow(link)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LayoutTokens.space24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.nichijiHairline, lineWidth: 1)
        )
    }

    private func linkRow(_ link: DataSourceItem.Link) -> some View {
        Link(destination: link.url) {
            HStack(spacing: LayoutTokens.space8) {
                Text(link.title)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInk)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.nichijiInkSubtle)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens in Safari")
    }

    private func snapshotsSection(_ section: DataSourcesDocument.Section) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            sectionHeader(section.title.uppercased())

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        dividerLine
                    }
                    Text(item.text)
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, LayoutTokens.space16)
                }
            }
            .settingsGroupBackground()
        }
    }
}
