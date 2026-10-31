---
id: "040"
title: Build the review engine
type: task
mode: AFK
status: closed
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

Yes. `DefaultReviewService` (in `ServiceContainer`) runs over a pure `ReviewScheduler` with the Leitner table from the closed decision and an injected `DayProvider`.

- Due is day-granular: due dates are the start of a local day. `known` and `new` are never due. Learning rows from before this release have no due date and count as due now.
- `startSession` builds the queue in the chosen order (due first, hardest first, newest first, random), capped by session size. `ReviewSession` keeps the first verdict per kanji. Repeat answers only log and bump counts.
- Answers log `gotItReview` / `forgotItReview` under the session's start day, and schedule from that day even past midnight.
- `GotItAction` passes tomorrow's due date into `markLearned`, so Today and the widget seed the same rule.
- Forget it (`ReviewService.forgetIt`) resets to `new`, clears both review dates, keeps `firstLearnedAt` and the counts (it no longer bumps `forgotItCount`), and logs the real calendar day.
- `ReviewPreferencesSnapshot` lives in App Group `UserDefaults` with the mock defaults; the last card type cannot be turned off.
- Reminders: once today is learned, the first reminder reads "N kanji due for review" when kanji are due on its day (tomorrow).

Follow-ups noted on "Build the Review tab and session" (rebuild reminders after a session), "Build kanji detail and the Dictionary browse grid" (Forget it entry point) and "Build the study log and stats service" (log fixes done). CI: pending at commit time; the run's Final Report carries the result.

