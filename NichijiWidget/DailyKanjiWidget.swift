import SwiftUI
import WidgetKit

/*---------------------------------widget-------------------------------------*/

struct DailyKanjiWidget: Widget {
    static let kind = "com.aten.nichiji.widget.daily-kanji"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: DailyKanjiProvider()) { entry in
            DailyKanjiWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.nichijiSurfaceRaised
                }
        }
        .configurationDisplayName("Today's kanji")
        .description("See today's kanji on your home screen and mark it learned.")
        .supportedFamilies([.systemSmall, .systemMedium])
        // TODO: Add a widget deep link to Today (`.widgetURL`) after the MVP.
    }
}

/*---------------------------------provider-----------------------------------*/

struct DailyKanjiProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyKanjiWidgetEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (DailyKanjiWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
            return
        }
        Task {
            completion(await Self.plan().entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<DailyKanjiWidgetEntry>) -> Void) {
        Task {
            completion(await Self.plan().timeline())
        }
    }

    private static func plan() async -> DailyKanjiTimelinePlan {
        guard let environment = try? WidgetEnvironment.live() else {
            let now = Date()
            return DailyKanjiTimelinePlan(
                entry: DailyKanjiWidgetEntry(date: now, content: .openApp),
                reloadDate: now.addingTimeInterval(DailyKanjiTimelineBuilder.retryInterval)
            )
        }
        return await environment.timelineBuilder.build()
    }
}

/*--------------------------------entry-view----------------------------------*/

struct DailyKanjiWidgetEntryView: View {
    let entry: DailyKanjiWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            DailyKanjiMediumWidgetView(content: entry.content)
        default:
            DailyKanjiSmallWidgetView(content: entry.content)
        }
    }
}
