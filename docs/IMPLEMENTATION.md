## Testing Suite (Phase 4)

Repeatable verification that grows alongside features: each new feature gets tests, and previous features stay covered.

### Testing architecture and rules

- **Framework**: Built on Apple Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect(...)`) under Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`).
- **Store isolation**: SwiftData unit tests construct an ephemeral `ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))` to ensure zero state leakage between tests and independent execution.
- **Local offline execution**: Tests require no network connection, external simulator services, or persistent disk access.
- **UI launch smoke test**: `NichijiUITests` is the one XCTest target. Its single test launches the app and waits up to 15 s for the shared `primaryButton` or, on a simulator where today is already learned, Today's "Learned today" seal. CI starts fresh on onboarding, so it covers the button branch. The `Nichiji` scheme runs it under `make test`.

### Test doubles (`NichijiTests/TestDoubles/`)

1. **`TestDayProvider`**:
   - Injected clock and calendar double holding mutable `simulatedDate` and `simulatedCalendar`.
   - Supports `advance(bySeconds:)` and `advance(byDays:)` to simulate midnight rollover, time-zone changes, and daylight saving transitions deterministically.
2. **`TestKanjiContentStore`**:
   - In-memory dictionary holding fixed `KanjiEntry` fixtures (`"日"`, `"学"`, `"木"`, `"川"`).
   - Throws typed `NichijiError.contentMissing` for unseeded IDs and validates index generation.
3. **`TestPronunciationService`**:
   - `@MainActor` test double recording spoken text and reading tuples.
   - Provides toggleable `isJapaneseVoiceAvailable` flag to verify graceful error and disabled state handling without hardware speech synthesis dependencies.
4. **`TestReminderScheduler`**:
   - Double recording scheduled notification requests, simulated authorization statuses (`.authorized`, `.denied`), and rebuild invocations without contacting `UNUserNotificationCenter`.
5. **`TestWidgetRefresher`**:
   - Double counting `reloadTimelines()` calls so widget reload triggers can be asserted without `WidgetCenter`.

### Planned feature test suites (`NichijiTests/Suites/`)

1. **`KanjiContentStoreTests`**:
   - Verify bundled JSON index decoding matches model types.
   - Verify single entry decoding by kanji ID literal.
   - Verify missing kanji ID throws `NichijiError.contentMissing(kanjiID:)`.
   - Verify stroke order SVG path retrieval.
2. **`LearnerStoreTests`**:
   - Verify `markLearned(day:)` transitions assignment status to `.learned`, advances `KanjiProgress.stage` from `.new` to `.learning`, and logs `StudyLogEntry`.
   - Verify `forgetIt(kanjiID:)` resets stage to `.new` and restores kanji to the unlearned pool.
   - Verify `reassignToday(from:)` swaps unlearned assignments while preserving learned assignments.
   - Verify `DailyAssignmentSnapshot` isolates state across the `@ModelActor` boundary.
3. **`DailyKanjiServiceTests`**:
   - Verify lazy idempotent rollover: calling `assignment(for:)` repeatedly on the same day returns the identical assignment.
   - Verify past unlearned assignments are marked `.missed` on day rollover, while `KanjiProgress.stage` remains `.new` so they return to the study pool.
   - Verify deterministic daily selection algorithms across `mostCommon`, `listOrder`, and date-seeded `random`.
   - Verify exhausted study pool returns `nil` to display the quiet level-complete state.
   - Verify `refreshAssignmentAfterPreferenceChange(for:preferences:)` re-evaluates the active pool, orders candidates according to `DailyOrder`, and swaps an `.assigned` today assignment while leaving a `.learned` assignment untouched.
4. **`PronunciationServiceTests`**:
   - Verify `speak(_:reading:)` utters kana reading when available and falls back to kanji literal.
   - Verify missing Japanese voice throws `NichijiError.speechUnavailable`.
   - Verify `stop()` cancels ongoing speech immediately.
5. **`ReminderSchedulerTests`**:
   - Verify 7-day rolling window creates exactly 7 scheduled requests.
   - Verify Day 1 notification uses kanji-led copy when learned and missed-day copy when assigned.
   - Verify Days 2 through 7 use generic copy (`"Today's kanji is ready"`).
   - Verify denied authorization preserves learner settings toggle without throwing silent failures.
6. **`WidgetTimelineTests`**:
   - Verify `DailyKanjiTimelineBuilder` builds a today entry from the active assignment, flags a learned day, and returns the level-complete and open-app placeholders.
   - Verify the reload date is `nextMidnight`, or 15 minutes later after a read failure.
   - Verify `GotItAction` marks the day learned, rebuilds reminders, and reloads timelines, and that a stale widget tap only reloads.
   - Verify level change, time-zone change, onboarding completion, and Today's Got it each reload timelines through `WidgetRefresher`.
7. **`SettingsPreferencesTests`**:
   - Verify `LearnerPreferencesSnapshot.load(from:)` and `save(to:)` round-trip all `LearnerPreferenceKey` values and format level and reminder summaries.
   - Verify level and order switches reassign an `.assigned` today kanji via `refreshAssignmentAfterPreferenceChange(for:preferences:)` while preserving a `.learned` assignment.
   - Verify custom kanji selections persist per `LevelSystem` and filter `DailyKanjiService.activePool(preferences:)` when `isCustomPoolActive` is enabled.
   - Verify `ReminderSettingsCoordinator.applyReminderPreferences(_:scheduler:)` rebuilds schedules when enabled, cancels reminders when disabled, and preserves the learner toggle when authorization is `.denied`.
   - Verify `ReviewPreferencesSnapshot` round-trips every review setting, formats the Settings row summary and chip labels, keeps the last card type on through save and load, and that a saved order and session size drive `ReviewScheduler.dueQueue`.
8. **`OnboardingFlowTests`**:
   - Verify the seven steps run in order, Welcome shows no progress, and steps 1 to 6 fill 1 to 6 segments.
   - Verify back navigation walks the steps in reverse and reaches Welcome.
   - Verify switching level system selects N5 or 1st grade and clears `isCustomPoolActive`, and choosing a level writes `levelSystem` and the matching level key.
   - Verify level row counts come from `KanjiContentStore`.
   - Verify `requestAuthorization()` runs only when reminders are on, and a `.denied` result still advances.
   - Verify completion sets `hasCompletedOnboarding` without a `LearnerStore` write, and a replay with a changed level reassigns an `.assigned` today while leaving a `.learned` today alone.
9. **`AppDeepLinkTests`**:
   - Verify `AppDeepLink.today` round-trips through `nichiji://today`, matches scheme and host case-insensitively, accepts a trailing slash, and rejects other schemes, hosts and paths.
   - Verify the today link selects `AppTab.today`.

## Onboarding Flow (Slice 9)

`OnboardingFlow` (`Nichiji/Views/Onboarding/OnboardingFlow.swift`) is a `@MainActor @Observable` model that owns the onboarding logic. The step views only read it and call its methods.

- **Navigation**: `step`, `direction`, `advance()`, `goBack()`, `showsProgress`, and `progressFill` (equal to `step.rawValue`, so Welcome fills nothing). `progressSegmentCount` is 6.
- **Level**: `levelRows` builds the JLPT or Jōyō rows with counts read once from `KanjiContentStore`. `selectLevelSystem(_:)` picks the system's first level. `selectLevel(_:)` writes `levelSystem`, the matching level key, and `isCustomPoolActive = false` straight to the App Group defaults.
- **Reminder**: `reminderEnabled`, `reminderHour`, and `reminderMinute` write through to defaults. `requestReminderAuthorizationIfNeeded()` shows the system prompt only while status is undecided, when the Reminder step appears with reminders on, when reminders are switched on, or when the status button is pressed. Denied status opens iOS notification settings instead. Continue always advances. Completion rebuilds the reminder window through `ReminderRefresher`.
- **Completion**: `complete()` sets `hasCompletedOnboarding`. If the level changed and today already has an assignment (a replay), it calls `LevelChangeCoordinator.applyLevelChange(preferences:dailyKanjiService:dayProvider:)`. A first run has no assignment yet, so it writes nothing to `LearnerStore` and Today's lazy rollover picks the first kanji.

`LevelChangeCoordinator` (`Nichiji/Services/LevelChangeCoordinator.swift`) is the shared reassignment path for Settings level, order, and custom pool changes and for onboarding replay. It resolves today's calendar day and calls `DailyKanjiService.refreshAssignmentAfterPreferenceChange(for:preferences:)`, which runs `LearnerStore.reassignToday(day:from:)` and keeps a `.learned` assignment.

## Widget Extension (Slice 11)

The `NichijiWidget` target compiles `Nichiji/Models`, `Nichiji/Services`, `Nichiji/DesignSystem/Tokens`, and `Nichiji/Widget` directly, so the extension and the app share one set of types. Logic lives in `Nichiji/Widget/` so `@testable import Nichiji` can reach it; only SwiftUI glue and the AppIntent sit in `NichijiWidget/`.

- **`WidgetRefresher`**: protocol with `reloadTimelines()`. `SystemWidgetRefresher` calls `WidgetCenter.shared.reloadAllTimelines()`; `NoopWidgetRefresher` is the `ServiceContainer` default. It is the only place that touches `WidgetCenter`.
- **`DailyKanjiTimelineBuilder`**: `build()` returns a `DailyKanjiTimelinePlan` with one `DailyKanjiWidgetEntry` and a reload date. Content is `.today(snapshot)`, `.levelComplete`, or `.openApp` (onboarding unfinished or the store unreadable). The reload date is the next local midnight, or 15 minutes out after a read failure.
- **`WidgetEnvironment`**: builds the App Group store, `DailyKanjiService`, and `SystemReminderScheduler` for the extension. `live()` throws `NichijiError.storeUnavailable` when the group container is missing.
- **`GotItAction`**: `perform(...)` marks learned, rebuilds reminders, and reloads widgets; it backs Today (through `ServiceContainer.markLearned`) and the widget. `performFromWidget(calendarDay:environment:)` only reloads when the widget's day is no longer today.
- **`MarkTodaysKanjiLearnedIntent`**: the interactive Got it button on `systemMedium`. It carries the day the widget showed.
- **Reload triggers**: `LevelChangeCoordinator.applyLevelChange` (before the reminder rebuild), `OnboardingFlow.complete()`, `ServiceContainer.handleTimeOrZoneChange(preferences:)`, and `ServiceContainer.markLearned`.
- **Shared copy and layout**: `AddWidgetCopy.steps` feeds the onboarding step and the Settings guide. `DailyKanjiSmallWidgetView` renders both the real small widget and the onboarding preview.
- **Deep link**: `AppDeepLink` (`Nichiji/Models/NavigationState.swift`) builds and parses `nichiji://today`. Both widgets set it with `.widgetURL`; `MainTabView.onOpenURL` closes Settings and selects Today. The `nichiji` scheme is registered in `project.yml` through `Config/Nichiji-Info.plist`, so Safari and Shortcuts reach it too.
- **Post-MVP**: lock-screen families and configurable widgets are TODOs.
