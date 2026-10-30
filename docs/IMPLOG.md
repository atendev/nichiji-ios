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

### Slice 6: Core Design System Components

#### Requirements Report
- **Success Criteria**: Reusable `HeaderBar`, `PrimaryButton`, `KanjiCard`, and `SealStamp` components with Apple HIG hit targets, Dynamic Type-compatible typography, semantic colors, continuous corners, accessibility, Reduce Motion support, and focused tests.
- **Scope Boundary**: Shared components and component tests only; Today detail behavior, learned-state persistence, and navigation wiring remain deferred.
- **Anticipated TODOs**: Resolve the component TODOs in `Nichiji/DesignSystem/Components/`; use a native SwiftUI seal treatment because no hanko asset is present.
- **Planned Tests**: Component configuration, minimum hit-target constants, and primary-button action behavior.

#### Deviation Report
- **Deviations**: None. The missing hanko asset was handled with a native circular SwiftUI checkmark seal treatment.
- **Unanticipated TODOs**: None.
- **Test Results**: Static validation passed with `git diff --check`. Xcode build/test tools are unavailable in this environment, so the Apple test suite could not be executed.

### Slice 7: Today Tab & Detail Flow

#### Requirements Report
- **Success Criteria**: Bind Today to the shared App Group SwiftData container,
  production services, bundled kanji content, pronunciation, learner mutations,
  level completion, retry handling, romaji preferences, and stroke-order paths
  while preserving Apple HIG sizing and Dynamic Type behavior.
- **Scope Boundary**: Today and its detail cards only; reminders, WidgetKit
  rebuilds, onboarding handoff, settings UI, and handwriting practice remain
  deferred.
- **Anticipated TODOs**: Keep practice disabled, use a test learner double,
  and leave reminder/widget refresh work for later slices.
- **Planned Tests**: Today assignment resolution, learned transition, exhausted
  pool, retry path, romaji data, stroke paths, and accessibility configuration.

#### Deviation Report
- **Deviations**: The app uses a no-op reminder scheduler until the reminder
  slice supplies notification scheduling. Stroke SVG paths are rendered by a
  local KanjiVG path parser.
- **Unanticipated TODOs**: Foreground refresh re-runs Today assignment
  resolution; reminder and WidgetKit rebuilds remain deferred.
- **Test Results**: `git diff --check` passes. Xcode build and test tools are
  unavailable in this environment, so Apple validation remains pending.

### Slice 8: Settings Sheet & Preferences

#### Requirements Report
- **Success Criteria**: Settings sheet with appearance picker, level and order
  selection, custom kanji picker, reminder settings, widget guide and privacy
  screens. Pool changes reassign an unlearned today kanji immediately and leave
  a learned one alone. Today refreshes on preference changes. All controls meet
  HIG tap targets and Dynamic Type.
- **Scope Boundary**: Settings views, preference persistence, and reassignment
  wiring only. Review settings, onboarding, the live notification scheduler,
  and the widget extension remain deferred.
- **Anticipated TODOs**: Review settings row, reminder rebuild and WidgetKit
  reload after pool changes (Slices 10 and 11).
- **Planned Tests**: Preferences round-trip, reassign unlearned today, preserve
  learned today, custom selection persistence and pool, reminder coordinator.

#### Deviation Report
- **Deviations**: Added `refreshAssignmentAfterPreferenceChange(for:preferences:)`
  to `DailyKanjiService`. Default reminder time moved from 9:00 to 8:00. Preference
  loading moved into `LearnerPreferencesSnapshot.load(from:)`. Reminder times render
  lowercase (`8:00 am`). `reassignToday` now deletes an unlearned assignment when the
  new pool is empty. `reassignToday` now keeps today's kanji when it is already
  first in the updated pool, instead of always swapping to the next one.
- **Unanticipated TODOs**: None.
- **Test Results**: `git diff --check` passes. Xcode build and test tools are
  unavailable in this environment, so `SettingsPreferencesTests` and the full
  suite have not been run.

### Slice 9: Onboarding Flow

#### Requirements Report
- **Success Criteria**: `OnboardingCoordinator` runs Welcome, Daily kanji,
  Flashcards, Level, Reminder, Widget, and Ready in order, with a six-segment
  progress bar that skips Welcome, a back button on every later step, and a
  spring slide (crossfade under Reduce Motion). The flashcard demo flips and
  swipes on a static 山 card with matching buttons and no store writes. The
  Level screen reads counts from `KanjiContentStore` and writes the level keys.
  The Reminder screen requests permission only when on and never blocks on
  `.denied`. Ready sets `hasCompletedOnboarding` without creating an
  assignment, and `RootView` crossfades to the tab shell. Replay keeps progress
  and reassigns an unlearned today when the level changed. Logic lives in an
  `@MainActor @Observable OnboardingFlow`.
- **Scope Boundary**: The coordinator, seven step views, `OnboardingFlow`, the
  shared level-change helper, the `RootView` transition, and onboarding copy.
  The live notification scheduler (Slice 10), the widget extension (Slice 11),
  a Custom option or order control on the Level screen, and Review, Dictionary,
  and You screens are out.
- **Anticipated TODOs**: No permission prompt until Slice 10 replaces
  `NoopReminderScheduler`. Reminder rebuild and widget reload on completion
  (Slices 10 and 11). The widget graphic is a mock until Slice 11.
- **Planned Tests**: `OnboardingFlowTests` covering step order and progress,
  back navigation, level system switching, level writes, store-backed counts,
  reminder authorization, completion without store writes, and replay. Re-run
  `SettingsPreferencesTests` after the helper extraction.

#### Deviation Report
- **Deviations**: The back chevron and progress bar moved out of each step view
  into one bar in the coordinator, so the step views no longer take `onBack`.
  The Welcome mark is a vermilion seal drawn from shapes, not the `SealStamp`
  component, because `SealStamp` is the green "Got it" learned badge. Replay
  reassignment runs only when today already has an assignment, which keeps a
  first run free of `LearnerStore` writes even when the level changes. Besides
  `LevelChangeCoordinator`, two more Slice 8 pieces were extracted for reuse:
  `LevelSelectionRow` and the level system switch from `LevelSettingsView`, and
  `ReminderTimePicker` from `ReminderSettingsView`. `CustomKanjiPickerView` now
  calls `LevelChangeCoordinator` too. Settings behavior is unchanged, except
  that reminder time changes now sync through one `onChange` instead of
  separate preset and picker handlers.
- **Unanticipated TODOs**: The onboarding widget steps say "Tap Edit, then Add
  Widget", while the Settings widget guide still says "tap +". Slice 11 should
  align the two. The slide direction for the first step after reversing
  direction needs a simulator check, since SwiftUI may apply the previous
  removal edge to the outgoing view.
- **Test Results**: `git diff --check` passes. Xcode build and test tools are
  unavailable in this environment, so `OnboardingFlowTests`,
  `SettingsPreferencesTests`, and the full suite have not been run. Gestures and
  animations still need a manual simulator pass.

### Slice 9b: Onboarding, Today and Settings Polish (v0.4.1)

#### Requirements Report
- **Success Criteria**: Step slides never overlap in either direction. The
  flashcard swaps faces at the edge-on point and tilts less. The Reminder step
  shows the system prompt and a status button. The Ready step shows the logo,
  "You're all set" and the button. Today keeps its scroll position across
  Control Center. Settings repaints at once on a theme change. The Customize
  kanji grid uses one 12 pt gap and square cells.
- **Scope Boundary**: Onboarding paging, flashcard, reminder, ready, Today
  reload handling, Settings sheet scheme, kanji grid, and the permission half of
  the live notification scheduler. Scheduling stays in Slice 10.
- **Anticipated TODOs**: `SystemReminderScheduler.rebuildSchedule` and
  `cancelAllReminders` stay no-ops until Slice 10.
- **Planned Tests**: `OnboardingFlowTests` reminder authorization. Everything
  else is a manual simulator pass.

#### Deviation Report
- **Deviations**: The prompt also fires when the reminder toggle is switched on
  while status is undecided, which the report did not list. The pager builds the
  neighbouring steps off-screen, so `ReminderSetupView` takes `isActive` to keep
  the prompt from firing early. `OnboardingStepHeader` gained
  `reservedSubtitleLines`. Today now refreshes after a real background trip
  only, and its scroll view is keyed on the kanji so a new kanji starts at the
  top.
- **Unanticipated TODOs**: None.
- **Test Results**: No Swift toolchain in this environment, so nothing was
  built or run, including `OnboardingFlowTests`. The pager, flip, Control
  Center, theme repaint and grid fixes were written from reading the code and
  need a simulator pass. `testReminderAuthorizationOnlyWhenEnabled` was
  replaced by `testReminderAuthorizationOnlyWhenUndecided`.

### Slice 10: Reminder Scheduler & Notifications (v0.5.0)

#### Requirements Report
- **Success Criteria**: Up to 7 pending local notifications, one a day, at the
  chosen time. Time ahead and unlearned: kanji-led today. Time ahead and
  learned: today skipped. Next fire tomorrow: missed-day copy when today is
  `.assigned`, generic when learned. Days 2 through 7 generic. Off removes all
  Nichiji requests; denied adds and removes nothing. The window rebuilds on
  settings, level, order, pool, onboarding completion, launch, foreground,
  app-side Got it and time-zone changes.
- **Scope Boundary**: `SystemReminderScheduler` scheduling and cancelling with
  `DailyKanjiService` and `DayProvider` injected at init, a pure
  `ReminderPlanBuilder`, and the trigger wiring. Widget Got it and widget
  reloads stay in Slice 11. The `ReminderScheduler` protocol is unchanged.
- **Anticipated TODOs**: `LevelChangeCoordinator` takes the scheduler, so its
  three callers change. `ServiceContainer.handleTimeOrZoneChange` and onboarding
  completion rebuild reminders. DESIGN.md's reminder paragraph is rewritten.
- **Planned Tests**: Planner cases (copy, skip, boundaries, clamping, time zone),
  refresher gating, and trigger wiring against `TestReminderScheduler`. The
  notification center itself is a manual simulator check.

#### Deviation Report
- **Deviations**: Added `ReminderRefresher`, a background rebuild path that never
  prompts, because `ReminderSettingsCoordinator` requests authorization when
  undecided and would prompt on launch. With no assignment (level complete) the
  scheduler cancels instead of scheduling. `RootView` owns the launch,
  foreground, onboarding-completion and time-zone triggers, and waits for
  onboarding to finish. `OnboardingFlow.complete()` rebuilds reminders only when
  an assignment already exists (a replay), so a first run writes nothing there
  and `RootView` rebuilds once the onboarding flag flips. Reminder failures after
  a rollover are swallowed so they never show as a Today error. The scheduler
  adds the new window and then prunes stale Nichiji requests so the learner is
  never left without one.
- **Unanticipated TODOs**: The window still goes stale after 7 days without
  opening the app. Widget reloads on these triggers stay TODOs for Slice 11.
- **Test Results**: No Swift toolchain in this environment, so nothing was built
  or run. Delivery, the identifier prefix surviving a rebuild, time-zone
  rescheduling and the denied banner need a simulator pass.

### Slice 11: WidgetKit Extension (v0.6.0)

#### Requirements Report
- **Success Criteria**: `NichijiWidget` target registers `systemSmall` and
  `systemMedium` daily kanji widgets using existing design tokens; timeline
  provider queries `DailyKanjiService.widgetSnapshot(for:)` with a midnight
  `reloadPolicy`; a `MarkTodaysKanjiLearnedIntent` marks today learned,
  rebuilds reminders, and reloads timelines; host-app triggers in
  `LevelChangeCoordinator`, `OnboardingFlow`, `ServiceContainer`, and `TodayView`
  reload widget timelines; onboarding and Settings "Add Widget" wording align.
- **Scope Boundary**: Widget extension rendering, timeline provider, interactive
  AppIntent, host-app reload triggers, Add Widget copy alignment, and
  `WidgetTimelineTests` updates are in scope. Lock-screen widgets, additional
  families, configurable intents, deep-linking, Live Activities, and new
  reminder scheduling logic are out of scope.
- **Anticipated TODOs**: Leave post-MVP TODOs for lock-screen widgets,
  additional families/configuration intents, and widget deep-link to Today.
  Resolve existing TODOs in `NichijiWidgetBundle.swift`,
  `LevelChangeCoordinator.swift`, `OnboardingFlow.swift`,
  `ServiceContainer.swift`, `WidgetTimelineTests.swift`, and
  `WidgetIntroView.swift`.
- **Planned Tests**: Extend `WidgetTimelineTests.swift` with Phase 4 doubles to
  cover `systemSmall`/`systemMedium` entries, level-complete placeholder,
  interactive Got it AppIntent, host-app triggers, and Add Widget copy match.
- **Delegated Gate**: HITL grilling was performed by subagent
  `aec267a9a06af69b6` acting as the human stand-in. The subagent also flagged
  risks: lock-screen scope mismatch in the Settings guide, missing widget target
  entitlements/dependencies in `project.yml`, missing
  `Config/Nichiji.entitlements`, and the need for a `WidgetRefresher` wrapper.

#### Deviation Report
- **Deviations**: Only the medium widget has the Got it button. The small widget
  shows "TODAY", the kanji, the meaning and a "Learned" mark, and nothing on it
  is tappable, so the onboarding preview no longer shows a Got it button. The
  widget shows an open-app placeholder ("Open Nichiji to start learning.")
  before onboarding completes and after any read failure, which the report did
  not list. It waits for onboarding because reading the snapshot creates
  today's assignment with default preferences. After a failure it retries in 15
  minutes instead of waiting for midnight. Level complete has its own
  placeholder. The widget logic lives in `Nichiji/Widget/` (provider builder,
  `GotItAction`, `WidgetEnvironment`, `WidgetRefresher`, shared small view) and
  is compiled into both the app and the extension through `project.yml`, with
  only the widget, medium view and intent in `NichijiWidget/`. The extension
  also compiles all of `Nichiji/Models`, `Nichiji/Services` and the design
  tokens, so it builds code it never uses (`PronunciationService`,
  `SystemReminderScheduler`). `GotItAction` is one Got it path for Today and the
  widget; `TodayView` now calls a new `ServiceContainer.markLearned`. A tap on a
  stale widget only reloads and marks nothing, so a learner cannot mark a kanji
  they never saw. `LevelChangeCoordinator` reloads widgets before the reminder
  rebuild so a reminder failure cannot leave the old kanji on screen.
  `OnboardingFlow.complete` reloads after the onboarding flag is set, so a
  completion with a level change reloads twice. `ServiceContainer.widgetRefresher`
  defaults to `NoopWidgetRefresher`, so a call site that forgets to pass one
  silently never reloads. `project.yml` also gained `MARKETING_VERSION "1.0"`
  and `CURRENT_PROJECT_VERSION "1"` so the extension matches the app, and the
  `NSExtensionPrincipalClass` key was removed from the widget Info.plist
  because the bundle uses `@main`. The Settings guide now shares
  `AddWidgetCopy.steps` with onboarding and its lock-screen card is a
  post-MVP placeholder. The Got it AppIntent itself is not unit tested, because
  the test target cannot see the extension. Its logic is covered through
  `GotItAction.performFromWidget`. No test renders the small or medium views.
- **Unanticipated TODOs**: Post-MVP TODOs were added for lock-screen widgets and
  configuration intents (`NichijiWidgetBundle.swift`, `SettingsSupportViews.swift`)
  and the widget deep link to Today (`DailyKanjiWidget.swift`). The widget
  reads through `widgetSnapshot`, which can create the day's assignment and run
  rollover from the extension process, racing the app on first open of a day.
  Trim the extension sources to what it needs once CI builds. Both targets now
  share source files, so a type that pulls in app-only UI would break the
  extension build; check `Nichiji/Models` and `Nichiji/Services` first if CI
  fails. XcodeGen regenerates `NichijiWidget/Info.plist` and both
  `Config/*.entitlements` from `project.yml`, so edit them there. The app
  falls back to a standalone store when the App Group is missing, while the
  widget shows the placeholder; a sideloaded install will never fill the
  widget. `MARKETING_VERSION` is "1.0" while the release notes say v0.6.0.
  Swift 6 strict concurrency risks to watch: `Timeline` passed across
  `@Sendable` completions in `DailyKanjiProvider` and the `@Parameter` /
  `static let title` in the intent.
- **Test Results**: No Swift toolchain in this environment, so nothing was
  built or run, including the new `WidgetTimelineTests` cases and the updated
  `OnboardingFlowTests` and `ReminderSchedulerTests`. The first build is remote
  CI. The widget gallery, the medium Got it tap, Increase Contrast, the midnight
  reload and the Add Widget flow need a simulator pass. The level-complete test
  assumes an empty content store yields a nil snapshot and is unverified.
