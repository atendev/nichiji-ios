---
id: "040"
title: Build the review engine
type: task
mode: AFK
status: open
blocked_by: ["039"]
claimed: false
---

## Question

Does a tested service produce the due queue for a session and apply Got it and Forgot it answers per the scheduling rules?

## Notes

Skills: `tdd`, `domain-modeling`, `unslop`.
No UI in this ticket.

Implement the rules from "Decide the review scheduling and progress rules" ([closed decision](../closed/039-review-scheduling-rules.md)): Leitner table (learning +1d, familiar +3d, known graduates), day-granular due, first answer per session decides, `resetToNew` clears `nextReviewAt`/`lastReviewedAt` and carries its `calendarDay`. The reminder window's specific-copy slot gains a review-due variant (`"3 kanji due for review"`) when today is learned and reviews are due — extend `ReminderPlanBuilder` accordingly.

- Review preferences in App Group `UserDefaults`, alongside `LearnerPreferences`.
- A `ReviewService` protocol in `ServiceContainer` with a pure scheduler underneath (same seam as `ReminderPlanBuilder`) and an injected `DayProvider`.
- `LearnerStore` mutations for answers and Forget it, through the `@ModelActor`.
- Today's Got it and the widget's Got it seed progress through the same rule (`GotItAction`).
- New `ReviewServiceTests` suite plus a test double.

Minor bump.

## Resolution

