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
