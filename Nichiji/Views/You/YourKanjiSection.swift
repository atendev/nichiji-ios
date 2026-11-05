import SwiftUI

/*-------------------------------your-kanji-------------------------------*/

enum YourKanjiMode: CaseIterable, Sendable {
    case learned
    case history

    var title: String {
        switch self {
        case .learned: "Learned"
        case .history: "History"
        }
    }
}

/// Learned grid or day-by-day history, with the CSV export under History.
struct YourKanjiSection: View {
    let learnedCount: Int
    let learnedKanjiIDs: [String]
    let meanings: [String: String]
    let logCount: Int

    @Environment(\.serviceContainer) private var services
    @Environment(ProAccessModel.self) private var proAccess: ProAccessModel?

    @State private var mode: YourKanjiMode = .learned
    @State private var history: [HistoryDay]?
    @State private var historyError: String?
    @State private var exportURL: URL?
    @State private var exportFailed = false

    init(learnedCount: Int, learnedKanjiIDs: [String], meanings: [String: String], logCount: Int) {
        self.learnedCount = learnedCount
        self.learnedKanjiIDs = learnedKanjiIDs
        self.meanings = meanings
        self.logCount = logCount
    }

    /// Stays opened after the first visit to History, so going back to Learned does not reload.
    private struct HistoryRequest: Hashable {
        let isOpened: Bool
        let logCount: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your kanji")
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(YouCopy.learnedCount(learnedCount))
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkSubtle)
            }
            .padding(.horizontal, LayoutTokens.space8)
            .padding(.top, LayoutTokens.space8)

            YourKanjiPicker(mode: $mode)

            switch mode {
            case .learned: learnedGrid
            case .history: historyList
            }
        }
        .task(id: HistoryRequest(isOpened: mode == .history || history != nil, logCount: logCount)) {
            await loadHistory()
        }
    }

    /*------------------------------learned-------------------------------*/

    @ViewBuilder private var learnedGrid: some View {
        if let message = YouCopy.learnedMessage(learnedKanjiIDs) {
            note(message)
        } else {
            LazyVGrid(columns: KanjiGridTile.columns, spacing: KanjiGridTile.spacing) {
                ForEach(learnedKanjiIDs, id: \.self) { kanjiID in
                    NavigationLink(value: KanjiDetailRoute(kanjiID: kanjiID)) {
                        KanjiGridTile(kanji: kanjiID)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(KanjiGridTile.accessibilityLabel(kanji: kanjiID, meaning: meanings[kanjiID] ?? ""))
                    .accessibilityHint("Opens kanji details")
                }
            }
            note("Tap a kanji to see its details.")
        }
    }

    /*------------------------------history-------------------------------*/

    @ViewBuilder private var historyList: some View {
        if let historyError {
            note(historyError)
        } else if let history {
            if let message = YouCopy.historyMessage(history) {
                note(message)
            } else {
                LazyVStack(alignment: .leading, spacing: LayoutTokens.space16) {
                    ForEach(history, id: \.calendarDay) { day in
                        HistoryDayView(day: day, calendar: services?.dayProvider.calendar ?? .current)
                    }
                }
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: LayoutTokens.minHitTarget)
        }

        exportControl
            .padding(.top, LayoutTokens.space4)
        if exportFailed {
            note(YouCopy.exportFailed)
        }
        note("Saves a CSV of your history. Nothing leaves your phone unless you share the file.")
    }

    // TODO: "Build the paywall and locked states" makes a locked export open the paywall instead of staying disabled.
    /// A disabled stand-in until the file is ready or while Pro is locked, so a stale or missing file is never shared.
    @ViewBuilder private var exportControl: some View {
        if YouCopy.canExport(logIsEmpty: logCount == 0, fileURL: exportURL, access: proAccess?.access ?? .locked), let exportURL {
            ShareLink(item: exportURL) {
                exportLabel
            }
            .buttonStyle(SecondaryButtonStyle())
        } else {
            Button(action: {}, label: { exportLabel })
                .buttonStyle(SecondaryButtonStyle())
                .disabled(true)
        }
    }

    private var exportLabel: some View {
        Label("Export history", systemImage: "square.and.arrow.down")
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.nichijiCaption)
            .foregroundColor(.nichijiInkSubtle)
            .padding(.horizontal, LayoutTokens.space8)
    }

    /// Runs once History has been opened, then again whenever the log changes.
    private func loadHistory() async {
        guard mode == .history || history != nil, let services else { return }
        exportURL = nil
        exportFailed = false
        do {
            let days = try await services.statsService.history()
            guard !Task.isCancelled else { return }
            history = days
            historyError = nil
        } catch {
            guard !Task.isCancelled else { return }
            historyError = error.localizedDescription
        }
        await prepareExport(services: services)
    }

    private func prepareExport(services: ServiceContainer) async {
        do {
            let export = try await services.statsService.historyExport()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(export.fileName)
            try export.data.write(to: url, options: .atomic)
            guard !Task.isCancelled else { return }
            exportURL = url
        } catch {
            guard !Task.isCancelled else { return }
            exportFailed = true
        }
    }
}

/*---------------------------------picker---------------------------------*/

struct YourKanjiPicker: View {
    @Binding var mode: YourKanjiMode

    var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            ForEach(YourKanjiMode.allCases, id: \.self) { option in
                segment(option)
            }
        }
        .padding(LayoutTokens.space4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.nichijiSurfaceSunken)
        )
    }

    private func segment(_ option: YourKanjiMode) -> some View {
        let isSelected = mode == option
        return Button {
            mode = option
        } label: {
            Text(option.title)
                .font(.uiText(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .nichijiInk : .nichijiInkMuted)
                .frame(maxWidth: .infinity, minHeight: LayoutTokens.minHitTarget)
                .background(
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                        .fill(isSelected ? Color.nichijiSurfaceRaised : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                        .stroke(isSelected ? Color.nichijiBorderControl : Color.clear, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/*------------------------------history-day-------------------------------*/

struct HistoryDayView: View {
    let day: HistoryDay
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            Text(day.heading)
                .font(.uiText(size: 11, weight: .medium))
                .tracking(0.66)
                .foregroundColor(.nichijiInkSubtle)
                .padding(.horizontal, LayoutTokens.space8)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(Array(day.entries.enumerated()), id: \.offset) { index, entry in
                    if index > 0 {
                        Divider().overlay(Color.nichijiHairline)
                    }
                    row(entry)
                }
            }
            .padding(.horizontal, LayoutTokens.space24)
            .padding(.vertical, LayoutTokens.space4)
            .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
        }
    }

    private func row(_ entry: StudyLogRecord) -> some View {
        NavigationLink(value: KanjiDetailRoute(kanjiID: entry.kanjiID)) {
            HStack(spacing: LayoutTokens.space12) {
                Text(entry.kanjiID)
                    .font(.kanjiDisplay(size: 24))
                    .foregroundColor(.nichijiInk)
                    .frame(minWidth: 36, alignment: .leading)
                Text(YouCopy.historyAction(entry.action))
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                Spacer(minLength: LayoutTokens.space8)
                Text(YouCopy.historyTime(entry.timestamp, calendar: calendar))
                    .font(.nichijiCaption)
                    .monospacedDigit()
                    .foregroundColor(.nichijiInkSubtle)
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens kanji details")
    }
}
