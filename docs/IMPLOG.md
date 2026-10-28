# Implementation Log

Running log of phase history and slices. Each slice gets its Requirements Report and Deviation Report here.

---

## Phase 0: Design

- Approved `docs/DESIGN.md` covering the initial Onboarding + Today scope, bundled offline kanji content, SwiftData + `UserDefaults` persistence split, Washi/Sumi themes, daily reminders, initial WidgetKit support, and future iPhone Duo / iPad two-pane readiness.

## Phase 1: Data

- Defined bundled immutable kanji types (`KanjiEntry`, `KanjiReading`, `KanjiRadical`, `ExampleWord`, `JLPTLevel`, `JoyoGrade`), scalar App Group `UserDefaults` preferences (`LearnerPreferencesSnapshot`, `LearnerPreferenceKey`, `AppearanceMode`, `LevelSystem`, `DailyOrder`), SwiftData learner models (`KanjiProgress`, `DailyAssignment`, `CustomKanjiSelection`, `StudyLogEntry`), and navigation/widget state types (`AppTab`, `OnboardingStep`, `SettingsDestination`, `ReminderNotificationKind`, `DailyKanjiWidgetSnapshot`).
- Specified the missed-day rollover rule: unlearned daily assignments are marked `.missed` at day rollover while their `KanjiProgress.stage` stays `.new` so they remain in the unlearned study pool, and the next day's reminder uses `"You missed yesterday's kanji. That's okay, check it now."`

## Phase 2: Interfaces

- Defined `DayProvider`, `KanjiContentStore`, `LearnerStore`, `DailyKanjiService`, `PronunciationService`, `ReminderScheduler`, `ServiceContainer`, `DailyAssignmentSnapshot`, `ReminderAuthorizationStatus`, and `NichijiError` in `Nichiji/Services/` and `docs/IMPLEMENTATION.md`.
- Updated `docs/DESIGN.md` and `CONTEXT.md` to record lazy idempotent daily rollover, `@ModelActor` write isolation, the rolling 7-day notification window, small and medium interactive widgets, and clock/time-zone change handling.

## Phase 3: TODOs

- Created view and design-system file skeletons under `Nichiji/DesignSystem/` and `Nichiji/Views/` covering Onboarding (7 screens), Today (hero, cards, quiet level complete, retry), Settings sheet (appearance, level, reminders), and the 4-tab app shell.
- Populated specific in-code TODO comments across views, design tokens, components, app lifecycle, and widget extension stubs.
- Added `NichijiWidget` target skeleton to `project.yml` with shared App Group container setup.
- Structured `docs/PROGRESS.md` with 11 ordered vertical slices mapping the roadmap to MVP release.

## Phase 4: Verification/Testing

- Standardized on Apple Swift Testing framework (`import Testing`) with in-memory SwiftData containers (`isStoredInMemoryOnly: true`) for deterministic local execution under Swift 6 strict concurrency.
- Created test doubles under `NichijiTests/TestDoubles/` (`TestDayProvider`, `TestKanjiContentStore`, `TestPronunciationService`, `TestReminderScheduler`).
- Documented testing suite architecture and invariants across 6 feature areas in `docs/IMPLEMENTATION.md` and established test suite stubs under `NichijiTests/Suites/`.

## Phase 5: Slices

### Slice 1: Design Tokens & Typography

#### Requirements Report
- **Success Criteria**:
  1. Full semantic color token palette matching `tokens.json` in Washi and Sumi modes with accessible contrast.
  2. Dynamic Type typography scale using Shippori Mincho and Zen Kaku Gothic New with system `.serif` and `.default` fallbacks, adhering to weight <= 500.
  3. Layout tokens establishing 8pt grid metrics, continuous corner radii, and a reusable `.minTouchTarget()` modifier enforcing Apple HIG 44x44 pt minimums.
  4. Swift Testing suite `DesignTokensTests` in `NichijiTests/Suites/` verifying tokens and invariants.
- **Scope Boundary**: Tokens, layout metrics, and unit tests in scope; custom view components (`HeaderBar`, `PrimaryButton`, `KanjiCard`, `SealStamp`) deferred to Slice 6.
- **Anticipated TODOs**: Resolves Slice 1 font fallback and layout modifier TODOs.
- **Planned Tests**: Verified in `DesignTokensTests`.

#### Deviation Report
- **Deviations**: None. Implemented self-contained dynamic UIKit color resolution for light/dark traits to support offline preview and test execution without asset catalogs.
- **Unanticipated TODOs**: None.
- **Test Results**: All 4 tests in `DesignTokensTests` passing (layout targets, typography instantiation, hex color parsing, dynamic trait resolution).

### Slice 2: Content Dataset & Bundled JSON Store

#### Requirements Report
- **Success Criteria**:
  1. `BundledKanjiContentStore` conforming to `KanjiContentStore` with thread-safe in-memory caching.
  2. Bundled seed dataset with complete `KanjiEntry` models (meanings, readings, radical, stroke paths, example words).
  3. Stable retrieval by ID and filtering by JLPT level and Joyo grade in canonical list order.
  4. Proper error mapping using `NichijiError.contentMissing` and `NichijiError.contentCorrupted`.
  5. Comprehensive Swift Testing suite covering lookups, filtering, stroke paths, and error scenarios.
- **Scope Boundary**: Bundled store implementation, caching, seed dataset, and test doubles in scope; SwiftData learner models and daily rollover engine deferred to Slices 3 and 4.
- **Anticipated TODOs**: Resolves all TODOs in `Nichiji/Services/KanjiContentStore.swift`.
- **Planned Tests**: Verified in `KanjiContentStoreTests`.

#### Deviation Report
- **Deviations**: None. Store includes embedded `SeedKanjiDataset` for core N5 and Grade 1 kanji (`日`, `一`, `二`, `三`, `山`, `川`, `学`) with real stroke-order SVG paths and example words to guarantee deterministic offline execution.
- **Unanticipated TODOs**: None.
- **Test Results**: All 6 tests in `KanjiContentStoreTests` passing (valid entry lookup, JLPT level filtering and ordering, Joyo grade filtering and ordering, SVG stroke paths validation, typed error throwing on missing glyphs, and `TestKanjiContentStore` double verification).

### Slice 3: SwiftData Learner Store

#### Requirements Report
- **Success Criteria**:
  1. `SwiftDataLearnerStore` implementing `LearnerStore` using SwiftData's `@ModelActor` macro for background context writes.
  2. Sendable `DailyAssignmentSnapshot` carrying assignment state across actor boundaries.
  3. Strict adherence to rollover invariants: past unlearned assignments become `.missed` while `KanjiProgress.stage` remains `.new`.
  4. Complete mutation methods: `markLearned`, `forgetIt`, `reassignToday`, `setCustomSelection`.
  5. In-memory SwiftData container unit tests in `LearnerStoreTests.swift`.
- **Scope Boundary**: Learner models, `@ModelActor` store, projections, and unit tests in scope; daily selection logic deferred to Slice 4.
- **Anticipated TODOs**: Resolves all TODOs in `Nichiji/Services/LearnerStore.swift`.
- **Planned Tests**: Verified in `LearnerStoreTests`.

#### Deviation Report
- **Deviations**: Added `reassignToday(day:from:)` overload so caller can supply explicit calendar day in addition to the default zero-argument day overload.
- **Unanticipated TODOs**: None.
- **Test Results**: All 7 tests in `LearnerStoreTests` passing (clean container setup, assignment creation and fetch, marking learned with stage advancement and logging, marking past assigned as missed while keeping stage `.new`, `forgetIt` reset, custom selection persistence, and `reassignToday` preservation of learned assignments).

### Slice 4: DayProvider & Daily Kanji Rollover

#### Requirements Report
- **Success Criteria**:
  1. `SystemDayProvider` implementing `DayProvider` with zero-padded `yyyy-MM-dd` date formatting and next midnight calculation.
  2. `DefaultDailyKanjiService` implementing lazy idempotent rollover, converting past `.assigned` rows to `.missed` while keeping stage `.new`.
  3. Deterministic daily kanji selection by frequency rank, list index, or day-hash pseudo-random order.
  4. Quiet level-complete state returning `nil` when the active pool is exhausted.
  5. Generating self-contained `DailyKanjiWidgetSnapshot` for WidgetKit timeline and UI consumption.
  6. Comprehensive Swift Testing suite in `DailyKanjiServiceTests.swift`.
- **Scope Boundary**: Clock boundary, rollover engine, selection logic, and widget snapshot in scope; UI presentations deferred to Slice 7, WidgetKit timeline extension to Slice 11.
- **Anticipated TODOs**: Resolves all TODOs in `Nichiji/Services/DayProvider.swift` and `Nichiji/Services/DailyKanjiService.swift`.
- **Planned Tests**: Verified in `DailyKanjiServiceTests`.

#### Deviation Report
- **Deviations**: Implemented deterministic hashing algorithm for `DailyOrder.random` so widgets and app target compute identical pseudo-random selection for any given calendar date without non-deterministic system random state.
- **Unanticipated TODOs**: None.
- **Test Results**: All 6 tests in `DailyKanjiServiceTests` passing (date formatting, lazy rollover marking past assigned rows as missed while keeping stage `.new`, same-day idempotency, deterministic selection across ordering strategies, quiet level complete state when study pool is exhausted, and widget snapshot compilation reflecting learned state).

### Slice 5: Japanese Pronunciation Audio

#### Requirements Report
- **Success Criteria**:
  1. `AVSpeechPronunciationService` conforming to `@MainActor PronunciationService` and `AVSpeechSynthesizerDelegate`.
  2. Detection of installed `ja-JP` speech voices via `AVSpeechSynthesisVoice`.
  3. Kana-preferred utterance playback with speech rate calibrated for pronunciation study (0.9x default speech rate).
  4. Instant playback cancellation via `stop()`.
  5. Accurate tracking of `isSpeaking` state via synthesizer and delegate callbacks.
  6. Swift Testing suite in `PronunciationServiceTests.swift`.
- **Scope Boundary**: Speech service, delegate hooks, voice check, and unit tests in scope; UI buttons in Today view deferred to Slices 6 and 7.
- **Anticipated TODOs**: Resolves all TODOs in `Nichiji/Services/PronunciationService.swift`.
- **Planned Tests**: Verified in `PronunciationServiceTests`.

#### Deviation Report
- **Deviations**: None.
- **Unanticipated TODOs**: None.
- **Test Results**: All 5 tests in `PronunciationServiceTests` passing (utterance playback recording, fallback to text when reading is absent, typed exception throwing when `ja-JP` voice is missing, immediate stopping and state reset, and live service initialization/inspection).
