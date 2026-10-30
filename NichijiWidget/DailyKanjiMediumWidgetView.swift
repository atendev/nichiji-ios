import AppIntents
import SwiftUI
import WidgetKit

/*---------------------------------medium-------------------------------------*/

/// The `systemMedium` layout: kanji, meaning, readings, one example word, and Got it.
struct DailyKanjiMediumWidgetView: View {
    let content: DailyKanjiWidgetEntry.Content

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        switch content {
        case .today(let snapshot):
            HStack(alignment: .top, spacing: LayoutTokens.space16) {
                VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                    Text(snapshot.kanjiID)
                        .font(.kanjiWidget)
                        .foregroundColor(.nichijiInk)

                    Text(snapshot.primaryMeaning)
                        .font(.nichijiCaption)
                        .foregroundColor(secondaryColor)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    gotItControl(for: snapshot)
                }

                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    readingRow(label: "On", kana: snapshot.onyomiKana)
                    readingRow(label: "Kun", kana: snapshot.kunyomiKana)

                    if let word = snapshot.featuredWord {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(word.word)
                                .font(.kanjiWord)
                                .foregroundColor(.nichijiInk)
                            Text("\(word.kana) · \(word.meaning)")
                                .font(.nichijiCaption)
                                .foregroundColor(secondaryColor)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .levelComplete, .openApp:
            DailyKanjiWidgetMessageView(content: content)
        }
    }

    private var secondaryColor: Color {
        contrast == .increased ? .nichijiInk : .nichijiInkMuted
    }

    private func readingRow(label: String, kana: [String]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space8) {
            Text(label)
                .font(.nichijiCaption)
                .foregroundColor(contrast == .increased ? .nichijiInkMuted : .nichijiInkSubtle)
                .frame(width: 28, alignment: .leading)

            Text(kana.isEmpty ? "—" : kana.joined(separator: "、"))
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInk)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func gotItControl(for snapshot: DailyKanjiWidgetSnapshot) -> some View {
        if snapshot.isLearned {
            Label("Learned", systemImage: "checkmark")
                .font(.uiText(size: 13, weight: .medium))
                .foregroundColor(.nichijiMatcha)
                .frame(minHeight: LayoutTokens.minHitTarget, alignment: .leading)
        } else {
            Button(intent: MarkTodaysKanjiLearnedIntent(calendarDay: snapshot.calendarDay)) {
                Text("Got it")
                    .font(.uiText(size: 13, weight: .medium))
                    .foregroundColor(.nichijiOnVermilion)
                    .padding(.horizontal, LayoutTokens.space16)
                    .frame(minHeight: LayoutTokens.minHitTarget)
                    .background(Capsule().fill(Color.nichijiVermilion))
            }
            .buttonStyle(.plain)
        }
    }
}
