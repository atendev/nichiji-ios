---
id: "007"
title: Phase 4 verification and testing suite definition
type: grilling
mode: HITL
status: closed
blocked_by: ["006"]
claimed: false
---

## Question

How should Nichiji define its Phase 4 verification suite in `docs/IMPLEMENTATION.md` to prove local-first persistence, rollover semantics, speech fallback, notification scheduling, and widget timelines?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/PROGRESS.md`.

## Resolution

- **Testing framework**: Standardized on Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect(...)`) under Swift 6 strict concurrency for all unit and integration verification.
- **Store isolation**: SwiftData tests use in-memory `ModelContainer(for: ... configurations: ModelConfiguration(isStoredInMemoryOnly: true))` to keep tests deterministic and isolated from disk.
- **Test doubles**: Defined four focused test doubles in `NichijiTests/`:
  - `TestDayProvider`: Controllable clock and calendar supporting arbitrary simulated midnight rollover, leap years, and time-zone shifts (`NSSystemTimeZoneDidChange`).
  - `TestKanjiContentStore`: Deterministic in-memory content store with fixed fixture entries (`"日"`, `"学"`, `"木"`, `"川"`).
  - `TestReminderScheduler`: Records scheduled notification requests to inspect triggers and exact notification copy without calling `UNUserNotificationCenter`.
  - `TestPronunciationService`: Records spoken text/reading and toggles simulated `ja-JP` voice availability.
- **Six test suites documented in `docs/IMPLEMENTATION.md`**:
  1. `KanjiContentStoreTests`: Verifies JSON decoding, missing content errors (`NichijiError.contentMissing`), and lazy stroke SVG loading.
  2. `LearnerStoreTests`: Verifies SwiftData `@ModelActor` mutations (`markLearned`, `forgetIt`, `reassignToday`), study log audit trails, and concurrency isolation.
  3. `DailyKanjiServiceTests`: Verifies lazy idempotent rollover, unlearned assignment return to `.new` pool, deterministic ordering (`mostCommon`, `listOrder`, date-seeded `random`), and empty-pool level completion.
  4. `PronunciationServiceTests`: Verifies speech synthesis with kana fallback to kanji, immediate stop handling, and missing voice error handling.
  5. `ReminderSchedulerTests`: Verifies 7-day rolling window structure (kanji-led or missed-day copy on day 1, generic copy on days 2–7), permission denial preservation, and time-zone rebuild triggers.
  6. `WidgetTimelineTests`: Verifies timeline entry extraction from `DailyKanjiWidgetSnapshot`, midnight refresh scheduling, and interactive "Got it" app intent reloading.
- **Deliverable**: Ticket 008 task will document the Phase 4 specification in `docs/IMPLEMENTATION.md` and create initial test double and suite skeletons in `NichijiTests/`.
