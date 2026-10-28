---
id: "004"
title: Write Phase 2 interfaces and stubs
type: task
mode: AFK
status: closed
blocked_by: ["003"]
claimed: false
---

## Question

Turn the decisions in the closed Phase 2 service interfaces ticket into the Phase 2 deliverable: function signatures with short TODO comments in `docs/IMPLEMENTATION.md`, protocol stubs in `Nichiji/Services/`, and the `docs/DESIGN.md` updates that ticket calls for. Stop at user approval, per `docs/workflow.md`.

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Source of truth: [Phase 2 service interfaces and reminder-widget contracts](../closed/003-phase-2-service-interfaces.md).
Follow the Phase 2 rules and comment style in `docs/workflow.md`: signatures only, no implementation, one or two sentence TODOs.
Add `DayProvider`, rollover and similar terms to `CONTEXT.md` if they are new vocabulary.
Do not commit or move to Phase 3 without user confirmation.

## Resolution

- Added Phase 2 protocol and type stubs under `Nichiji/Services/` (`NichijiError`, `DayProvider`, `KanjiContentStore`, `LearnerStore`, `DailyAssignmentSnapshot`, `DailyKanjiService`, `PronunciationService`, `ReminderScheduler`, `ReminderAuthorizationStatus`, `ServiceContainer`) with 1–2 sentence TODO comments.
- Added `DailyAssignmentSnapshot` as the `Sendable` value projection across the `@ModelActor` `LearnerStore` boundary under Swift 6 strict concurrency, and added `.genericReady(dueReviewCount: Int)` to `ReminderNotificationKind` for days 2–7 of the rolling reminder window.
- Recorded the Phase 2 interfaces in `docs/IMPLEMENTATION.md`, folded the resolved dataset, widget, reminder permission, and time-zone contracts into `docs/DESIGN.md`, and added `Day provider`, `Rollover`, and `Reminder window` to `CONTEXT.md`.
