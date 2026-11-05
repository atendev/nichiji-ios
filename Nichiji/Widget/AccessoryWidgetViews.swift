import SwiftUI
import WidgetKit

/*---------------------------------copy---------------------------------------*/

/// The words the lock-screen families show, kept apart from the views so tests can pin them.
enum AccessoryWidgetCopy {
    static let appName = "Nichiji"
    static let learned = "Learned"
    static let levelComplete = "Level complete"
    static let levelCompleteDetail = "Every kanji learned."
    static let openApp = "Open Nichiji to start learning"
    static let proLocked = "Nichiji Pro"
    static let proLockedDetail = "Unlock in the app"
    static let proLockedAccessibility = "Lock screen widgets need Nichiji Pro. Unlock it in the app."

    static func inline(for content: DailyKanjiWidgetEntry.Content) -> String {
        switch content {
        case .today(let snapshot):
            "\(snapshot.kanjiID) \(snapshot.isLearned ? "learned" : snapshot.primaryMeaning)"
        case .levelComplete: levelComplete
        case .openApp: appName
        }
    }

    /// The featured word with its kana, or nil when the kanji has no example.
    static func featuredWordLine(for snapshot: DailyKanjiWidgetSnapshot) -> String? {
        snapshot.featuredWord.map { "\($0.word) \($0.kana)" }
    }

    static func accessibilityLabel(for content: DailyKanjiWidgetEntry.Content) -> String {
        switch content {
        case .today(let snapshot):
            snapshot.isLearned
                ? "\(snapshot.kanjiID), \(snapshot.primaryMeaning). Learned today."
                : "\(snapshot.kanjiID), \(snapshot.primaryMeaning)."
        case .levelComplete: "\(levelComplete). \(levelCompleteDetail)"
        case .openApp: openApp
        }
    }
}

/*---------------------------------gate---------------------------------------*/

/// Lock-screen families need Pro; the home-screen widgets stay free.
enum LockScreenWidgetGate {
    static func isLocked(family: WidgetFamily, access: ProAccess) -> Bool {
        isLockScreen(family) && !access.allows(.lockScreenWidgets)
    }

    static func isLockScreen(_ family: WidgetFamily) -> Bool {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
    }
}

/*--------------------------------circular------------------------------------*/

/// The `accessoryCircular` layout: the kanji alone, with a small check once learned.
struct AccessoryCircularWidgetView: View {
    let content: DailyKanjiWidgetEntry.Content

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            switch content {
            case .today(let snapshot):
                Text(snapshot.kanjiID)
                    .font(.kanjiDisplay(size: 34))
                    .minimumScaleFactor(0.5)
                    .widgetAccentable()
                    .overlay(alignment: .bottomTrailing) {
                        if snapshot.isLearned {
                            Image(systemName: "checkmark")
                                .font(.uiText(size: 11, weight: .medium))
                                .offset(x: 6, y: 4)
                        }
                    }
            case .levelComplete:
                Image(systemName: "checkmark")
                    .font(.uiText(size: 22, weight: .medium))
            case .openApp:
                // The brand seal is not in the widget target, so a plain 日 stands in rather than a redrawn mark.
                Text("日")
                    .font(.kanjiDisplay(size: 30))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessoryWidgetCopy.accessibilityLabel(for: content))
    }
}

/*-------------------------------rectangular----------------------------------*/

/// The `accessoryRectangular` layout: kanji leading, meaning and featured word beside it.
struct AccessoryRectangularWidgetView: View {
    let content: DailyKanjiWidgetEntry.Content

    var body: some View {
        Group {
            switch content {
            case .today(let snapshot):
                HStack(alignment: .center, spacing: LayoutTokens.space8) {
                    Text(snapshot.kanjiID)
                        .font(.kanjiDisplay(size: 38))
                        .minimumScaleFactor(0.5)
                        .widgetAccentable()

                    VStack(alignment: .leading, spacing: 1) {
                        Text(snapshot.primaryMeaning)
                            .font(.uiText(size: 14, weight: .medium))
                            .lineLimit(1)

                        if let line = AccessoryWidgetCopy.featuredWordLine(for: snapshot) {
                            Text(line)
                                .font(.uiText(size: 12))
                                .lineLimit(1)
                        }

                        if snapshot.isLearned {
                            Label(AccessoryWidgetCopy.learned, systemImage: "checkmark")
                                .font(.uiText(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .levelComplete:
                VStack(alignment: .leading, spacing: 1) {
                    Text(AccessoryWidgetCopy.levelComplete)
                        .font(.uiText(size: 14, weight: .medium))
                    Text(AccessoryWidgetCopy.levelCompleteDetail)
                        .font(.uiText(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .openApp:
                Text(AccessoryWidgetCopy.openApp)
                    .font(.uiText(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessoryWidgetCopy.accessibilityLabel(for: content))
    }
}

/*---------------------------------inline-------------------------------------*/

/// The `accessoryInline` layout: one line of text.
struct AccessoryInlineWidgetView: View {
    let content: DailyKanjiWidgetEntry.Content

    var body: some View {
        Text(AccessoryWidgetCopy.inline(for: content))
            .accessibilityLabel(AccessoryWidgetCopy.accessibilityLabel(for: content))
    }
}

/*---------------------------------locked-------------------------------------*/

/// A minimal stand-in shown on the lock screen until Pro is unlocked.
struct AccessoryLockedWidgetView: View {
    let family: WidgetFamily

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "lock.fill")
                        .font(.uiText(size: 20, weight: .medium))
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text(AccessoryWidgetCopy.proLocked)
                        .font(.uiText(size: 14, weight: .medium))
                    Text(AccessoryWidgetCopy.proLockedDetail)
                        .font(.uiText(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                Text(AccessoryWidgetCopy.proLocked)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessoryWidgetCopy.proLockedAccessibility)
    }
}
