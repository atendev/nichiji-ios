---
id: "048"
title: Build the study log and stats service
type: task
mode: AFK
status: closed
blocked_by: ["040", "047"]
claimed: false
---

## Question

Does every study action write a log entry, and does a tested service compute every stat the rules define?

## Notes

From "Build the review engine": review answers now log rows, Forget it logs its real `calendarDay`, and the widget Got it logs through `GotItAction`. Older `resetToNew` rows may still carry an empty day.

Skills: `tdd`, `domain-modeling`, `unslop`.
No UI in this ticket.

- `LearnerStore` already writes `StudyLogEntry` rows for Today's Got it and for Forget it (the latter with an empty `calendarDay`). Confirm the widget's Got it writes one too, add rows for review answers, and fix or handle the empty `calendarDay`.
- A pure stats calculator over log entries and progress with an injected `DayProvider`, behind a `StatsService` in `ServiceContainer`.
- Streak freeze reads the existing `streakFreezeEnabled` preference.
- CSV export as a pure function.

Minor bump.

From [Decide the streak and stats rules](../closed/047-streak-and-stats-rules.md): compute every number its Resolution lists. Days studied replaces time studying, so no timing is logged. Expose one study-day function and switch the Review tab's This week dots (`ReviewHomeSummary`) to it.

## Resolution

Resolved on 2026-11-02 as a Phase 5 run. Requirements report approved on the 13th audit round; CI pending, see the final report.

**Log writes**: every study action already logged a row. Today and widget Got it go through `GotItAction.perform` to `markLearned` (`learnedDaily`), review answers log through `recordReview` with repeats, and Forget it logs its real day. The ticket's note about Forget it writing an empty day was stale. Only older rows can be empty, and `StudyLogRecord.day(using:)` resolves them to the timestamp's day in the `DayProvider` zone. No migration.

**Store**: `LearnerStore` adds `studyLog()` (raw rows oldest first) and `allProgress()`.

**Study day**: `StudyDay` holds the one rule. The Review tab's This week dots now use it, so a day with only a Got it from Today shows a dot.

**Stats**: `StatsService` (on `ServiceContainer`) over a pure `StatsCalculator` gives `LearnerStats`: streaks, freeze row (`ready` or `usedThisWeek`), the tiles, learning since, the 12×7 activity grid, By level, milestones, Needs attention and the learned list. History, level-complete figures and the CSV export are separate calls. Decisions made where 047 was open:
- Got-it rates (overall, per level and the Needs attention tie-break) come from log rows, never `gotItCount`, which also counts the Today Got it.
- A missed day falls after the first study day and before today. A reset-only day is missed. The longest streak uses the freeze too. "Used this week" means any day this week was forgiven.
- By level, the level milestone and level-complete figures use `preferences.levelSystem` and the full index group. User decision: the level milestone follows the level system with a Custom pool too ("Finish Grade 1" for a Custom Jōyō pool), refining 047's "Custom gets the JLPT label".
- Name kanji is a bar but not a study level, so `LevelSequence` ends at N1 and Secondary. A Custom pool gets no next level and no level-complete figures.
- Days taken is inclusive. Rates round halves up. History headings use `en_US_POSIX` (`MON, OCT 26`, with `, 2025` for past years).
- Needs attention ties: kanji with no Forgot it row sort after those with one, then by kanji.

