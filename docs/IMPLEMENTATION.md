## Testing Suite (Phase 4)

Repeatable verification that grows alongside features: each new feature gets tests, and previous features stay covered.

### Testing architecture and rules

- **Framework**: Built on Apple Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect(...)`) under Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`).
- **Store isolation**: SwiftData unit tests construct an ephemeral `ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))` to ensure zero state leakage between tests and independent execution.
- **Local offline execution**: Tests require no network connection, external simulator services, or persistent disk access.

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
   - Verify timeline provider builds `DailyKanjiWidgetSnapshot` from active assignment.
   - Verify timeline reload policy refreshes at `nextMidnight`.
   - Verify interactive "Got it" AppIntent marks assignment learned and triggers timeline reloads.
7. **`SettingsPreferencesTests`**:
   - Verify `LearnerPreferencesSnapshot.load(from:)` and `save(to:)` round-trip all `LearnerPreferenceKey` values and format level and reminder summaries.
   - Verify level and order switches reassign an `.assigned` today kanji via `refreshAssignmentAfterPreferenceChange(for:preferences:)` while preserving a `.learned` assignment.
   - Verify custom kanji selections persist per `LevelSystem` and filter `DailyKanjiService.activePool(preferences:)` when `isCustomPoolActive` is enabled.
   - Verify `ReminderSettingsCoordinator.applyReminderPreferences(_:scheduler:)` rebuilds schedules when enabled, cancels reminders when disabled, and preserves the learner toggle when authorization is `.denied`.
8. **`OnboardingFlowTests`**:
   - Verify the seven steps run in order, Welcome shows no progress, and steps 1 to 6 fill 1 to 6 segments.
   - Verify back navigation walks the steps in reverse and reaches Welcome.
   - Verify switching level system selects N5 or 1st grade and clears `isCustomPoolActive`, and choosing a level writes `levelSystem` and the matching level key.
   - Verify level row counts come from `KanjiContentStore`.
   - Verify `requestAuthorization()` runs only when reminders are on, and a `.denied` result still advances.
   - Verify completion sets `hasCompletedOnboarding` without a `LearnerStore` write, and a replay with a changed level reassigns an `.assigned` today while leaving a `.learned` today alone.

## Onboarding Flow (Slice 9)

`OnboardingFlow` (`Nichiji/Views/Onboarding/OnboardingFlow.swift`) is a `@MainActor @Observable` model that owns the onboarding logic. The step views only read it and call its methods.

- **Navigation**: `step`, `direction`, `advance()`, `goBack()`, `showsProgress`, and `progressFill` (equal to `step.rawValue`, so Welcome fills nothing). `progressSegmentCount` is 6.
- **Level**: `levelRows` builds the JLPT or Jōyō rows with counts read once from `KanjiContentStore`. `selectLevelSystem(_:)` picks the system's first level. `selectLevel(_:)` writes `levelSystem`, the matching level key, and `isCustomPoolActive = false` straight to the App Group defaults.
- **Reminder**: `reminderEnabled`, `reminderHour`, and `reminderMinute` write through to defaults. `requestReminderAuthorizationIfNeeded()` shows the system prompt only while status is undecided, when the Reminder step appears with reminders on, when reminders are switched on, or when the status button is pressed. Denied status opens iOS notification settings instead. Continue always advances. Completion rebuilds the reminder window through `ReminderRefresher`.
- **Completion**: `complete()` sets `hasCompletedOnboarding`. If the level changed and today already has an assignment (a replay), it calls `LevelChangeCoordinator.applyLevelChange(preferences:dailyKanjiService:dayProvider:)`. A first run has no assignment yet, so it writes nothing to `LearnerStore` and Today's lazy rollover picks the first kanji.

`LevelChangeCoordinator` (`Nichiji/Services/LevelChangeCoordinator.swift`) is the shared reassignment path for Settings level, order, and custom pool changes and for onboarding replay. It resolves today's calendar day and calls `DailyKanjiService.refreshAssignmentAfterPreferenceChange(for:preferences:)`, which runs `LearnerStore.reassignToday(day:from:)` and keeps a `.learned` assignment.
