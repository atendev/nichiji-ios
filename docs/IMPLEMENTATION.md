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
  - `var forgotItCount: Int`
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

Function signatures with short TODO descriptions, plus open choices for the user.

_Not started._

## Testing Suite (Phase 4)

Repeatable verification that grows with each feature.

_Not started._
