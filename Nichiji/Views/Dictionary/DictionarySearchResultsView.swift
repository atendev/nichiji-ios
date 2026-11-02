import SwiftUI

/*---------------------------------results--------------------------------*/

/// Kanji grid and word rows for one query. Rendering only: matching and ranking live in `DictionarySearchIndex`.
struct DictionarySearchResultsView: View {
    let results: DictionarySearchResults
    let showsRomaji: Bool
    let onSelectWord: (WordResult) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                Text(heading)
                    .font(results.isEmpty ? .nichijiHeading : .nichijiCaption)
                    .foregroundColor(results.isEmpty ? .nichijiInk : .nichijiInkMuted)
                    .accessibilityAddTraits(.isHeader)

                if !results.kanji.isEmpty {
                    kanjiSection
                }
                if !results.words.isEmpty {
                    wordsSection
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutTokens.screenMarginCompact)
            .padding(.top, LayoutTokens.space8)
            .padding(.bottom, LayoutTokens.space32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var heading: String {
        results.isEmpty ? "No matches for \u{201C}\(results.query)\u{201D}" : "Closest matches for \u{201C}\(results.query)\u{201D}"
    }

    private var kanjiSection: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            sectionTitle("Kanji")

            LazyVGrid(columns: KanjiGridTile.columns, spacing: KanjiGridTile.spacing) {
                ForEach(results.kanji) { entry in
                    NavigationLink(value: KanjiDetailRoute(kanjiID: entry.id)) {
                        KanjiGridTile(kanji: entry.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(KanjiGridTile.accessibilityLabel(kanji: entry.id, meaning: entry.primaryMeaning))
                    .accessibilityHint("Opens kanji details")
                }
            }
        }
    }

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Words")
                .padding(.bottom, LayoutTokens.space8)

            ForEach(Array(results.words.enumerated()), id: \.element.id) { index, result in
                if index > 0 {
                    Rectangle()
                        .fill(Color.nichijiHairline)
                        .frame(height: 1)
                }
                wordRow(result)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.nichijiHeading)
            .foregroundColor(.nichijiInk)
            .accessibilityAddTraits(.isHeader)
    }

    private func wordRow(_ result: WordResult) -> some View {
        Button {
            onSelectWord(result)
        } label: {
            VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space12) {
                    Text(result.word.word)
                        .font(.kanjiDisplay(size: 20))
                        .foregroundColor(.nichijiInk)
                    Text(result.word.kana)
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                    if showsRomaji {
                        Text(result.word.romaji)
                            .font(.nichijiCaption)
                            .foregroundColor(.nichijiInkSubtle)
                    }
                }
                Text(result.word.meaning)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, LayoutTokens.space12)
            .frame(minHeight: LayoutTokens.minHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(result.tapAction == .unavailable)
        .accessibilityElement(children: .combine)
        .accessibilityHint(result.tapAction == .unavailable ? "" : "Opens the kanji in this word")
    }
}
