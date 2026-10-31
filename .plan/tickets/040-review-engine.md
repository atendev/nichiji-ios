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

- Review preferences in App Group `UserDefaults`, alongside `LearnerPreferences`.
- A `ReviewService` protocol in `ServiceContainer` with a pure scheduler underneath (same seam as `ReminderPlanBuilder`) and an injected `DayProvider`.
- `LearnerStore` mutations for answers and Forget it, through the `@ModelActor`.
- Today's Got it and the widget's Got it seed progress through the same rule (`GotItAction`).
- New `ReviewServiceTests` suite plus a test double.

Minor bump.

## Resolution

