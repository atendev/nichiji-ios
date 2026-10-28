# Implementation

Filled in from Phase 1 onward.

---

## Data (Phase 1)

### Overview and rationale

Nichiji splits its data layer into three storage tiers so the main app and the WidgetKit extension share a single offline source of truth without duplicating bundled reference content inside the database:

1. **Bundled immutable kanji content (`Nichiji/Models/KanjiContent.swift`)**: `KanjiEntry` and its child value types (`KanjiReading`, `KanjiRadical`, `ExampleWord`, `JLPTLevel`, `JoyoGrade`) are `Codable`, `Sendable`, `Hashable` structs decoded on demand from the app bundle. Keying every entry by its single-character kanji literal (`id: String`, e.g. `"学"`) keeps foreign keys human-readable and stable across dataset updates.
2. **Scalar learner preferences (`Nichiji/Models/LearnerPreferences.swift`)**: Small settings that drive immediate view state (`hasCompletedOnboarding`, `appearanceMode`, `showsRomaji`, `streakFreezeEnabled`, `reminderEnabled`, `reminderHour`, `reminderMinute`, `levelSystem`, `selectedJLPTLevel`, `selectedJoyoGrade`, `dailyOrder`, `isCustomPoolActive`) live in shared App Group `UserDefaults` (`group.com.aten.nichiji`). Views bind to them directly with `@AppStorage` without running database queries.
3. **Structured learner records (`Nichiji/Models/LearnerModels.swift`)**: Mutable records that grow over time or require indexed queries live in a shared App Group SwiftData `ModelContainer`:
   - `KanjiProgress` tracks per-kanji `StudyStage` (`new`, `learning`, `familiar`, `known`), review scheduling timestamps, and `gotItCount` / `forgotItCount` from the start so later Review and You slices need no schema migration.
   - `DailyAssignment` binds one `kanjiID` to a local calendar day (`yyyy-MM-dd`) with status `assigned`, `learned`, or `missed`. If a day ends while its assignment is still `assigned`, rollover marks the assignment `missed` and keeps `KanjiProgress.stage` at `.new` so the learner never loses the chance to see that kanji on Today.
   - `CustomKanjiSelection` stores custom study-pool picks separately from `KanjiProgress` so toggling custom membership never alters learning history.
   - `StudyLogEntry` records an append-only audit trail of daily "Got it" actions, review answers, and resets for streak calculation and the You history list.
4. **Navigation and widget snapshots (`Nichiji/Models/NavigationState.swift`)**: Value types for the four-tab shell (`AppTab`), Settings sub-routes (`SettingsDestination`), onboarding steps (`OnboardingStep`), and the self-contained `DailyKanjiWidgetSnapshot` used by WidgetKit timelines.

### Bundled content types (`Nichiji/Models/KanjiContent.swift`)

- `JLPTLevel` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.n5`, `.n4`, `.n3`, `.n2`, `.n1`.
- `JoyoGrade` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.grade1`, `.grade2`, `.grade3`, `.grade4`, `.grade5`, `.grade6`, `.secondary`.
- `ReadingKind` (`String`, `Codable`, `Sendable`): `.onyomi`, `.kunyomi`.
- `KanjiReading` (`Codable`, `Hashable`, `Sendable`):
  - `kind: ReadingKind`
  - `kana: String` (katakana for onyomi, hiragana with `-` okurigana separator for kunyomi)
  - `romaji: String`
- `KanjiRadical` (`Codable`, `Hashable`, `Sendable`):
  - `character: String`
  - `meaning: String`
- `ExampleWord` (`Codable`, `Hashable`, `Sendable`, `Identifiable`):
  - `id: String`
  - `word: String`
  - `kana: String`
  - `romaji: String`
  - `meaning: String`
  - `maxJLPTLevel: JLPTLevel?`
  - `maxJoyoGrade: JoyoGrade?`
- `KanjiEntry` (`Codable`, `Hashable`, `Sendable`, `Identifiable`):
  - `id: String` (the kanji character literal, e.g. `"学"`)
  - `meanings: [String]` (primary meaning at index 0)
  - `onyomi: [KanjiReading]`
  - `kunyomi: [KanjiReading]`
  - `radical: KanjiRadical`
  - `strokeCount: Int`
  - `strokePaths: [String]` (ordered SVG path strings in a `109x109` coordinate box)
  - `jlptLevel: JLPTLevel?`
  - `joyoGrade: JoyoGrade?`
  - `frequencyRank: Int?`
  - `listIndex: Int`
  - `exampleWords: [ExampleWord]`

### Learner preference enums and keys (`Nichiji/Models/LearnerPreferences.swift`)

- `AppStorageGroup`:
  - `suiteName = "group.com.aten.nichiji"`
- `AppearanceMode` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.system`, `.light`, `.dark`.
- `LevelSystem` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.jlpt`, `.joyo`.
- `DailyOrder` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.mostCommon`, `.listOrder`, `.random`.
- `LearnerPreferenceKey` (`String`, `Sendable`): string keys for `hasCompletedOnboarding`, `appearanceMode`, `showsRomaji`, `streakFreezeEnabled`, `reminderEnabled`, `reminderHour`, `reminderMinute`, `levelSystem`, `selectedJLPTLevel`, `selectedJoyoGrade`, `dailyOrder`, and `isCustomPoolActive`.
- `LearnerPreferencesSnapshot` (`Codable`, `Equatable`, `Sendable`): value snapshot of all scalar preferences for service consumption.

### SwiftData learner models (`Nichiji/Models/LearnerModels.swift`)

- `StudyStage` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.new`, `.learning`, `.familiar`, `.known`.
- `DailyAssignmentStatus` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.assigned`, `.learned`, `.missed`.
- `StudyAction` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.learnedDaily`, `.gotItReview`, `.forgotItReview`, `.resetToNew`.
- `@Model final class KanjiProgress`:
  - `@Attribute(.unique) var kanjiID: String`
  - `var stageRaw: String` (`StudyStage` backing value)
  - `var firstLearnedAt: Date?`
  - `var lastReviewedAt: Date?`
  - `var nextReviewAt: Date?`
  - `var gotItCount: Int`
  - `forgotItCount: Int`
- `@Model final class DailyAssignment`:
  - `@Attribute(.unique) var calendarDay: String` (`yyyy-MM-dd` in local calendar)
  - `var kanjiID: String`
  - `var statusRaw: String` (`DailyAssignmentStatus` backing value)
  - `var assignedAt: Date`
  - `var completedAt: Date?`
- `@Model final class CustomKanjiSelection`:
  - `@Attribute(.unique) var kanjiID: String`
  - `var levelSystemRaw: String` (`LevelSystem` backing value)
  - `var selectedAt: Date`
- `@Model final class StudyLogEntry`:
  - `@Attribute(.unique) var id: UUID`
  - `var kanjiID: String`
  - `var actionRaw: String` (`StudyAction` backing value)
  - `var timestamp: Date`
  - `var calendarDay: String`

### Navigation and widget snapshot types (`Nichiji/Models/NavigationState.swift`)

- `AppTab` (`String`, `Codable`, `CaseIterable`, `Sendable`): `.today`, `.dictionary`, `.review`, `.you`.
- `OnboardingStep` (`Int`, `Codable`, `CaseIterable`, `Sendable`): `.welcome`, `.dailyKanji`, `.flashcards`, `.levelSelection`, `.reminder`, `.widgetIntro`, `.ready`.
- `SettingsDestination` (`Hashable`, `Sendable`): `.level`, `.customizeKanji`, `.dailyReminder`, `.review`, `.widgets`, `.privacy`.
- `ReminderNotificationKind` (`Equatable`, `Sendable`):
  - `.dailyReady(kanjiID: String, dueReviewCount: Int)` (`"学 · Today's kanji is ready"`)
  - `.missedYesterday(dueReviewCount: Int)` (`"You missed yesterday's kanji. That's okay, check it now."`)
  - `.genericReady(dueReviewCount: Int)` (`"Today's kanji is ready"`, used for days 2 through 7 in the rolling window)
- `DailyKanjiWidgetSnapshot` (`Codable`, `Equatable`, `Sendable`):
  - `calendarDay: String`
  - `kanjiID: String`
  - `primaryMeaning: String`
  - `onyomiKana: [String]`
  - `kunyomiKana: [String]`
  - `featuredWord: ExampleWord?`
  - `isLearned: Bool`

---

## Interfaces (Phase 2)

### Overview and rationale

Nichiji's runtime behavior is divided into five `Sendable` service protocols plus an injected clock boundary (`DayProvider`), bundled in a `ServiceContainer` that lives in the SwiftUI environment with no singletons:

1. **Injected time and calendar (`Nichiji/Services/DayProvider.swift`)**: `DayProvider` is the single source of the current instant, active local calendar, `yyyy-MM-dd` day formatting, and next local midnight calculation so missed-day rollover and time-zone changes can be verified deterministically in tests.
2. **Bundled content access (`Nichiji/Services/KanjiContentStore.swift`)**: `KanjiContentStore` decodes bundled `KanjiEntry` records (`kanji-index.json` and `kanji/<hex-codepoint>.json`) shared across the main app and widget extension, while loading stroke SVG paths (`stroke-order/<hex-codepoint>.svg`) lazily in the main app target only.
3. **Actor-isolated persistence (`Nichiji/Services/LearnerStore.swift`)**: `LearnerStore` is backed by a `@ModelActor` in both the app and the widget extension against the shared App Group `ModelContainer`. Views read via `@Query` and never call `context.save()`; all mutations (`markLearned`, `forgetIt`, `setCustomSelection`, `reassignToday`) go through `LearnerStore`. Because SwiftData `@Model` instances are not `Sendable` across actors under Swift 6 strict concurrency, `LearnerStore` and `DailyKanjiService` return `DailyAssignmentSnapshot` value projections across actor boundaries.
4. **Lazy idempotent daily selection and rollover (`Nichiji/Services/DailyKanjiService.swift`)**: `DailyKanjiService.assignment(for:)` marks any `.assigned` rows strictly before the requested day as `.missed` (never rewriting `.learned` or `.missed` rows and keeping `KanjiProgress.stage` at `.new`), then returns or creates today's row from the active `.new` study pool. Selection is a pure function of the pool, `DailyOrder`, excluded IDs, and `calendarDay` (with `.random` seeded by `calendarDay` so the app and widget always agree). An empty pool returns `nil` so Today renders a quiet "level complete, pick another level" state. Missing content for an assigned ID logs and selects the next candidate without surfacing a user error.
5. **Main-actor Japanese speech (`Nichiji/Services/PronunciationService.swift`)**: `PronunciationService` wraps `AVSpeechSynthesizer` on `@MainActor`, speaking the kana reading when available and falling back to kanji text. When no `ja-JP` voice is installed, speaker controls are disabled with an explanatory footnote and no alert.
6. **Rolling 7-day notifications (`Nichiji/Services/ReminderScheduler.swift`)**: `ReminderScheduler` maintains up to 7 pending daily notification requests. The first upcoming fire uses specific copy (`dailyReady` if today is learned, `missedYesterday` if today is still `.assigned`), while days 2 through 7 use `genericReady` (`"Today's kanji is ready"`). The schedule is rebuilt on launch, on foreground, after "Got it" (app or widget), and after any reminder, level, pool, or time-zone change. Denied permission leaves the user's preference toggle intact and surfaces an inline Settings link row.
7. **Widgets and clock changes (`Nichiji/Services/ServiceContainer.swift`)**: `systemSmall` and `systemMedium` widgets read through `DailyKanjiService.widgetSnapshot(for:)`, expose an interactive "Got it" `AppIntent` while `.assigned`, refresh `.after(nextMidnight)`, and fall back to a placeholder snapshot on error. On `NSSystemTimeZoneDidChange` or `significantTimeChange`, `ServiceContainer.handleTimeOrZoneChange(preferences:)` reruns rollover, rebuilds the 7-day notification window, and reloads widget timelines.

### Domain error type (`Nichiji/Services/NichijiError.swift`)

- `enum NichijiError: Error, Equatable, Sendable`:
  - `case storeUnavailable`
  - `case contentMissing(kanjiID: String)`
  - `case notificationsDenied`
  - `case speechUnavailable`

### Time and calendar boundary (`Nichiji/Services/DayProvider.swift`)

- `protocol DayProvider: Sendable`:
  - `var now: Date { get }` — TODO: Return `Date.now` in the live provider and a controllable date in tests.
  - `var calendar: Calendar { get }` — TODO: Return `Calendar.autoupdatingCurrent` in the live provider and a fixed time-zone calendar in tests.
  - `func calendarDay(for date: Date) -> String` — TODO: Format `date` in the provider's calendar and time zone using a zero-padded `yyyy-MM-dd` representation.
  - `func nextMidnight(after date: Date) -> Date` — TODO: Advance to the next local midnight in the provider's calendar for widget timeline refresh and reminder scheduling.

### Bundled content store (`Nichiji/Services/KanjiContentStore.swift`)

- `protocol KanjiContentStore: Sendable`:
  - `func entry(for kanjiID: String) throws -> KanjiEntry` — TODO: Decode and cache `kanji/<hex-codepoint>.json` from the active bundle, throwing `NichijiError.contentMissing` if absent.
  - `func entries(for jlptLevel: JLPTLevel) throws -> [KanjiEntry]` — TODO: Filter the decoded bundle index by `jlptLevel` and return entries sorted by `listIndex`.
  - `func entries(for joyoGrade: JoyoGrade) throws -> [KanjiEntry]` — TODO: Filter the decoded bundle index by `joyoGrade` and return entries sorted by `listIndex`.
  - `func strokePaths(for kanjiID: String) throws -> [String]` — TODO: Parse `stroke-order/<hex-codepoint>.svg` on demand and throw `NichijiError.contentMissing` when the glyph resource is absent.

### Actor-isolated learner store (`Nichiji/Services/LearnerStore.swift`)

- `struct DailyAssignmentSnapshot: Codable, Equatable, Sendable`:
  - `let calendarDay: String`
  - `let kanjiID: String`
  - `let status: DailyAssignmentStatus`
  - `let assignedAt: Date`
  - `let completedAt: Date?`
- `protocol LearnerStore: Sendable`:
  - `func assignment(for calendarDay: String) async throws -> DailyAssignmentSnapshot?` — TODO: Query the shared App Group `ModelContainer` for `calendarDay` and map the row to `DailyAssignmentSnapshot`.
  - `func markPastAssignedAsMissed(before calendarDay: String) async throws -> [DailyAssignmentSnapshot]` — TODO: Transition rows with `calendarDay < today` and `status == .assigned` to `.missed`, leaving `.learned` or `.missed` rows untouched and keeping `KanjiProgress` at `.new`.
  - `func createAssignment(calendarDay: String, kanjiID: String, assignedAt: Date) async throws -> DailyAssignmentSnapshot` — TODO: Insert a `.assigned` `DailyAssignment` row for `calendarDay` and `kanjiID`, save the context, and return its snapshot.
  - `func nonNewKanjiIDs() async throws -> Set<String>` — TODO: Fetch all `KanjiProgress` rows where `stageRaw != StudyStage.new.rawValue` so daily selection excludes learned kanji.
  - `func customSelectionIDs(for levelSystem: LevelSystem) async throws -> Set<String>` — TODO: Fetch `CustomKanjiSelection` rows matching `levelSystem` and return their `kanjiID` set.
  - `func markLearned(day: String) async throws -> DailyAssignmentSnapshot` — TODO: Set the day's assignment to `.learned`, advance `KanjiProgress` from `.new` to `.learning` with `firstLearnedAt`, append a `.learnedDaily` `StudyLogEntry`, and return the updated snapshot.
  - `func forgetIt(kanjiID: String) async throws` — TODO: Reset `KanjiProgress` for `kanjiID` to `.new` and append a `.resetToNew` `StudyLogEntry`.
  - `func setCustomSelection(_ kanjiIDs: Set<String>, levelSystem: LevelSystem) async throws` — TODO: Replace all `CustomKanjiSelection` rows for `levelSystem` with `kanjiIDs` and save the context.
  - `func reassignToday(from pool: [KanjiEntry]) async throws -> DailyAssignmentSnapshot?` — TODO: Leave today's row untouched if already `.learned`; otherwise replace or clear the `.assigned` row from `pool` and save.

### Daily kanji selection and rollover (`Nichiji/Services/DailyKanjiService.swift`)

- `protocol DailyKanjiService: Sendable`:
  - `func assignment(for day: String) async throws -> DailyAssignmentSnapshot?` — TODO: Idempotently mark `.assigned` rows before `day` as `.missed`, then return the existing row for `day` or create one from the active `.new` pool (returning `nil` if the pool is empty).
  - `func activePool(preferences: LearnerPreferencesSnapshot) async throws -> [KanjiEntry]` — TODO: Load candidate entries from `KanjiContentStore` for the active level or custom set and filter to kanji still at `StudyStage.new`.
  - `func selectKanjiID(from pool: [KanjiEntry], order: DailyOrder, excluding excludedIDs: Set<String>, day: String) -> String?` — TODO: Pure selection from `pool` minus `excludedIDs` using `frequencyRank`, `listIndex`, or a generator seeded by `day` so app and widget always agree.
  - `func widgetSnapshot(for day: String) async throws -> DailyKanjiWidgetSnapshot?` — TODO: Run lazy rollover via `assignment(for:)` and combine the assigned `KanjiEntry` with its learned state, returning `nil` when the study pool is empty.

### Japanese speech synthesis (`Nichiji/Services/PronunciationService.swift`)

- `@MainActor protocol PronunciationService: Sendable`:
  - `var isSpeaking: Bool { get }` — TODO: Observe `AVSpeechSynthesizer` delegate callbacks to keep `isSpeaking` in sync with playback.
  - `var isJapaneseVoiceAvailable: Bool { get }` — TODO: Check `AVSpeechSynthesisVoice(language: "ja-JP")` so views can disable speaker controls with a footnote when unavailable.
  - `func speak(_ text: String, reading: String?) throws` — TODO: Stop any active utterance and speak `reading ?? text` with `AVSpeechSynthesizer` in `ja-JP`, throwing `NichijiError.speechUnavailable` if no voice exists.
  - `func stop()` — TODO: Call `stopSpeaking(at: .immediate)` when the learner taps stop or the current screen disappears.

### Local reminder scheduling (`Nichiji/Services/ReminderScheduler.swift`)

- `enum ReminderAuthorizationStatus: String, Codable, Equatable, Sendable`: `.notDetermined`, `.authorized`, `.denied`.
- `protocol ReminderScheduler: Sendable`:
  - `func authorizationStatus() async -> ReminderAuthorizationStatus` — TODO: Read `UNUserNotificationCenter` `notificationSettings` and map `authorizationStatus` to `ReminderAuthorizationStatus`.
  - `func requestAuthorization() async throws -> Bool` — TODO: Request alert and sound authorization from `UNUserNotificationCenter`, throwing `NichijiError.notificationsDenied` if denied.
  - `func rebuildSchedule(preferences: LearnerPreferencesSnapshot) async throws` — TODO: Schedule up to 7 daily requests where the next fire uses kanji-led or missed-day copy based on today's assignment status and days 2 through 7 use generic copy.
  - `func cancelAllReminders() async` — TODO: Remove pending notification requests created by Nichiji from `UNUserNotificationCenter`.

### Service container (`Nichiji/Services/ServiceContainer.swift`)

- `struct ServiceContainer: Sendable`:
  - `let dayProvider: any DayProvider`
  - `let contentStore: any KanjiContentStore`
  - `let learnerStore: any LearnerStore`
  - `let dailyKanjiService: any DailyKanjiService`
  - `let pronunciationService: any PronunciationService`
  - `let reminderScheduler: any ReminderScheduler`
  - `func handleTimeOrZoneChange(preferences: LearnerPreferencesSnapshot) async throws` — TODO: Re-run `DailyKanjiService.assignment(for:)`, rebuild `ReminderScheduler`, and reload `WidgetCenter` timelines when `NSSystemTimeZoneDidChange` or `significantTimeChange` fires.

### Notes for review

- **Swift 6 `@ModelActor` boundary (`DailyAssignmentSnapshot`)**: Because `project.yml` enables `SWIFT_STRICT_CONCURRENCY: complete` under Swift 6, SwiftData `@Model` classes (`DailyAssignment`, `KanjiProgress`) cannot cross actor boundaries from a `@ModelActor` `LearnerStore` to `@MainActor` callers. `DailyAssignmentSnapshot` carries `DailyAssignment` state across actor boundaries while SwiftUI views continue reading `@Model` rows directly via `@Query`.

---

## Testing Suite (Phase 4)

Repeatable verification that grows with each feature.

_Not started._
