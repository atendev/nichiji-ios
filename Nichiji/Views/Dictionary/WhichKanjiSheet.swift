import SwiftUI

/*---------------------------------sheet----------------------------------*/

/// Opens from a word row with two or more distinct kanji. A tile closes the sheet and opens that kanji's detail.
struct WhichKanjiSheet: View {
    let result: WordResult
    let showsRomaji: Bool
    let onSelect: (String) -> Void

    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: LayoutTokens.space12, alignment: .top)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                wordSummary

                VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                    Text("Which kanji?")
                        .font(.nichijiHeading)
                        .foregroundColor(.nichijiInk)
                        .accessibilityAddTraits(.isHeader)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: LayoutTokens.space12) {
                        ForEach(result.kanji) { entry in
                            tile(entry)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutTokens.screenMarginRegular)
            .padding(.top, LayoutTokens.space32)
            .padding(.bottom, LayoutTokens.space32)
        }
        .background(Color.nichijiSurfaceRaised.ignoresSafeArea())
        // A presented sheet does not follow the root's live scheme change, so it applies its own.
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.nichijiSurfaceRaised)
    }

    private var wordSummary: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text(result.word.word)
                .font(.kanjiDisplay(size: 40))
                .foregroundColor(.nichijiInk)
            Text(showsRomaji ? "\(result.word.kana) · \(result.word.romaji)" : result.word.kana)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
            Text(result.word.meaning)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private func tile(_ entry: KanjiIndexEntry) -> some View {
        Button {
            onSelect(entry.id)
        } label: {
            VStack(spacing: LayoutTokens.space4) {
                KanjiGridTile(kanji: entry.id)
                Text(entry.primaryMeaning)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(KanjiGridTile.accessibilityLabel(kanji: entry.id, meaning: entry.primaryMeaning))
        .accessibilityHint("Opens kanji details")
    }
}
