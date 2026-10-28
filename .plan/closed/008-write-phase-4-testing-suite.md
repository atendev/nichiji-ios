---
id: "008"
title: Write Phase 4 testing suite specification and test doubles
type: task
mode: AFK
status: closed
blocked_by: ["007"]
claimed: false
---

## Question

Turn the decisions in the closed Phase 4 grilling ticket into the Phase 4 deliverable: document the testing suite architecture and test cases in `docs/IMPLEMENTATION.md`, implement test doubles (`TestDayProvider`, `TestKanjiContentStore`, `TestReminderScheduler`, `TestPronunciationService`) and test suite stubs in `NichijiTests/`.

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Source of truth: [Phase 4 verification and testing suite definition](../closed/007-phase-4-verification-and-testing-suite.md).
Follow `docs/workflow.md` Phase 4 rules:
- Define a repeatable way to prove the implementation actually works beyond "it compiles".
- Use Swift Testing (`import Testing`).
- Stop at user approval before beginning Phase 5 vertical slice implementation.

## Resolution

- Documented the Phase 4 testing suite architecture in `docs/IMPLEMENTATION.md`: Swift Testing (`@Suite`, `@Test`), in-memory SwiftData containers, test double definitions, and 6 planned test suites.
- Created test doubles under `NichijiTests/TestDoubles/`:
  - `TestDayProvider`: controllable clock and calendar with `advance(bySeconds:)` and `advance(byDays:)`.
  - `TestKanjiContentStore`: in-memory fixture store with typed error throwing.
  - `TestPronunciationService`: `@MainActor` utterance recorder with simulated voice availability.
  - `TestReminderScheduler`: scheduled request recorder with configurable authorization statuses.
- Created 6 test suite stubs under `NichijiTests/Suites/` (`KanjiContentStoreTests`, `LearnerStoreTests`, `DailyKanjiServiceTests`, `PronunciationServiceTests`, `ReminderSchedulerTests`, `WidgetTimelineTests`).
- Updated `docs/IMPLOG.md` with Phase 4 summary.
