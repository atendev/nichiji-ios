---
id: "048"
title: Build the study log and stats service
type: task
mode: AFK
status: open
blocked_by: ["040", "047"]
claimed: false
---

## Question

Does every study action write a log entry, and does a tested service compute every stat the rules define?

## Notes

Skills: `tdd`, `domain-modeling`, `unslop`.
No UI in this ticket.

- `LearnerStore` already writes `StudyLogEntry` rows for Today's Got it and for Forget it (the latter with an empty `calendarDay`). Confirm the widget's Got it writes one too, add rows for review answers, and fix or handle the empty `calendarDay`.
- A pure stats calculator over log entries and progress with an injected `DayProvider`, behind a `StatsService` in `ServiceContainer`.
- Streak freeze reads the existing `streakFreezeEnabled` preference.
- CSV export as a pure function.

Minor bump.

## Resolution

