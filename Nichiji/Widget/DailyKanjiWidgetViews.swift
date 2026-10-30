import SwiftUI

/*----------------------------------small-------------------------------------*/

/// The `systemSmall` layout, shared with the onboarding preview so the two cannot drift apart.
struct DailyKanjiSmallWidgetView: View {
    let content: DailyKanjiWidgetEntry.Content

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        switch content {
        case .today(let snapshot):
            VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                Text("TODAY")
                    .font(.nichijiCaption)
                    .foregroundColor(contrast == .increased ? .nichijiInkMuted : .nichijiInkSubtle)
                    .kerning(0.6)

                Text(snapshot.kanjiID)
                    .font(.kanjiWidget)
                    .foregroundColor(.nichijiInk)

                Text(snapshot.primaryMeaning)
                    .font(.nichijiCaption)
                    .foregroundColor(contrast == .increased ? .nichijiInk : .nichijiInkMuted)
                    .lineLimit(2)

                Spacer(minLength: 0)

                if snapshot.isLearned {
                    Label("Learned", systemImage: "checkmark")
                        .font(.uiText(size: 13, weight: .medium))
                        .foregroundColor(.nichijiMatcha)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .combine)
        case .levelComplete, .openApp:
            DailyKanjiWidgetMessageView(content: content)
        }
    }
}

/*---------------------------------message------------------------------------*/

/// Quiet placeholder for the level-complete and open-app states. It has no button, so nothing is tappable.
struct DailyKanjiWidgetMessageView: View {
    let content: DailyKanjiWidgetEntry.Content

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text(title)
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)

            Text(detail)
                .font(.nichijiCaption)
                .foregroundColor(contrast == .increased ? .nichijiInk : .nichijiInkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch content {
        case .levelComplete: "Level complete"
        case .openApp, .today: "Nichiji"
        }
    }

    private var detail: String {
        switch content {
        case .levelComplete: "You have learned every kanji in this level."
        case .openApp, .today: "Open Nichiji to start learning."
        }
    }
}
