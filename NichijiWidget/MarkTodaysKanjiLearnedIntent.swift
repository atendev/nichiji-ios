import AppIntents

/*---------------------------------intent-------------------------------------*/

/// Interactive Got it button on the medium widget. Runs in the extension, so it opens the shared store itself.
struct MarkTodaysKanjiLearnedIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark today's kanji learned"

    /// The day the widget was showing, so a widget left over from yesterday cannot mark a kanji the learner never saw.
    @Parameter(title: "Calendar day")
    var calendarDay: String

    init() {}

    init(calendarDay: String) {
        self.calendarDay = calendarDay
    }

    func perform() async throws -> some IntentResult {
        try await GotItAction.performFromWidget(calendarDay: calendarDay, environment: WidgetEnvironment.live())
        return .result()
    }
}
