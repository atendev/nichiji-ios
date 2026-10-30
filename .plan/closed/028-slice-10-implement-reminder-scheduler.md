---
id: "028"
title: "Implement Slice 10: Reminder Scheduler & Notifications"
type: task
mode: AFK
status: closed
blocked_by: ["026"]
claimed: false
---

## Question

Implement Slice 10 on feature branch `feature/slice-10-reminder-scheduler`: add `ReminderPlanBuilder`, implement `SystemReminderScheduler` scheduling and cancelling, wire every app-side rebuild trigger, add the planned tests, and write the Deviation Report.

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Source of truth: [Slice 10 Requirements Report](026-slice-10-reminder-scheduler-requirements.md).
Follow `docs/workflow.md` slice execution steps. Version: MINOR bump to v0.5.0, confirmed with the user before the commit.

## Resolution

Implemented `ReminderPlanBuilder`, `ReminderRefresher` and the live `SystemReminderScheduler` (add the new window, then prune stale `nichiji.reminder.*` requests). Wired rebuilds into level changes, onboarding replay and completion, launch, foreground, app-side Got it and time-zone changes. The Deviation Report is in `docs/IMPLOG.md`. A Haiku audit did not approve in two rounds; the user then approved the commit. Xcode build and tests were not run locally because the tools are unavailable here, so remote CI is the first build.
