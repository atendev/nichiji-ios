---
id: "015"
title: "Slice 4 Requirements Report: DayProvider & Daily Kanji Rollover"
type: grilling
mode: HITL
status: closed
blocked_by: ["014"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 4 (DayProvider & Daily Kanji Rollover) before creating the feature branch?

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/IMPLEMENTATION.md`, `Nichiji/Services/DailyKanjiService.swift`, `Nichiji/Services/DayProvider.swift`.

## Resolution

- **Slice Name**: `slice-4-dayprovider-and-daily-kanji-rollover`.
- **Success Criteria**:
  1. `SystemDayProvider` implementing `DayProvider` with zero-padded `yyyy-MM-dd` date formatting and next midnight calculation.
  2. `DefaultDailyKanjiService` implementing lazy idempotent rollover, converting past `.assigned` rows to `.missed` while keeping stage `.new`.
  3. Deterministic daily kanji selection by frequency rank, list index, or day-hash pseudo-random order.
  4. Quiet level-complete state returning `nil` when the active pool is exhausted.
  5. Generating self-contained `DailyKanjiWidgetSnapshot` for WidgetKit timeline and UI consumption.
  6. Comprehensive Swift Testing suite in `DailyKanjiServiceTests.swift`.
- **Approved**: User approved Requirements Report on trunk; proceeding to feature branch implementation.
