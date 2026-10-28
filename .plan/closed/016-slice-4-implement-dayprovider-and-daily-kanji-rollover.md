---
id: "016"
title: "Implement Slice 4: DayProvider & Daily Kanji Rollover"
type: task
mode: AFK
status: closed
blocked_by: ["015"]
claimed: false
---

## Question

Implement Slice 4 on feature branch `feat/slice-4-dayprovider-and-daily-kanji-rollover`: implement `SystemDayProvider`, `DefaultDailyKanjiService`, make `DailyKanjiWidgetSnapshot` public, write comprehensive tests in `DailyKanjiServiceTests.swift`, and write the Deviation Report.

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Source of truth: [Slice 4 Requirements Report](../closed/015-slice-4-dayprovider-and-daily-kanji-rollover-requirements.md).
Follow `docs/workflow.md` slice execution steps.

## Resolution

- Implemented `SystemDayProvider` in `Nichiji/Services/DayProvider.swift` providing current time, calendar, zero-padded `calendarDay(for:)`, and next midnight computation.
- Implemented `DefaultDailyKanjiService` in `Nichiji/Services/DailyKanjiService.swift` with lazy idempotent rollover, study pool filtering, deterministic daily selection, quiet level-complete (`nil`), and `DailyKanjiWidgetSnapshot` compilation.
- Made `DailyKanjiWidgetSnapshot` and `LearnerPreferencesSnapshot` public across modules.
- Added comprehensive unit tests in `NichijiTests/Suites/DailyKanjiServiceTests.swift`.
- Updated `docs/PROGRESS.md` marking Slice 4 `done`, logged reports in `docs/IMPLOG.md`, and bumped version to `v0.0.10` in `docs/CHANGELOG.md`.
