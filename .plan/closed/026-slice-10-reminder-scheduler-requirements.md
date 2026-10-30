---
id: "026"
title: "Slice 10 Requirements Report: Reminder Scheduler & Notifications"
type: grilling
mode: HITL
status: closed
blocked_by: ["025"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 10 (Reminder Scheduler & Notifications) before creating the feature branch?

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/DESIGN.md`, `Nichiji/Services/ReminderScheduler.swift`, `Nichiji/Services/ServiceContainer.swift`, `Nichiji/Views/Settings/ReminderSettingsView.swift`, `Nichiji/Views/Onboarding/OnboardingFlow.swift`.
Pick up the Slice 10 TODOs left by Slices 8 and 9: the reminder rebuild after level changes in `LevelChangeCoordinator` and after onboarding completion, and the permission prompt at the onboarding Reminder step (the prompt and `SystemReminderScheduler` authorization landed in Slice 9b; scheduling and cancelling remain).

## Resolution

- **Success criteria**:
  1. With reminders on and permission granted, the app keeps up to 7 pending local notifications, one per day at the chosen time. Never more than one per day.
  2. Day-1 copy depends on when the next fire lands:
     - Time still ahead today and today is `.assigned`: kanji-led with today's kanji (`"<kanji> · Today's kanji is ready"`).
     - Time still ahead today and today is `.learned`: today is skipped and the window starts tomorrow.
     - Next fire is tomorrow and today is `.assigned`: `"You missed yesterday's kanji. That's okay, check it now."`
     - Next fire is tomorrow and today is `.learned`: generic copy, because tomorrow's kanji is not known yet.
  3. Days 2 through 7 use `"Today's kanji is ready"`.
  4. Turning reminders off removes every pending Nichiji request. Denied permission leaves the toggle on, adds nothing and removes nothing.
  5. The window is rebuilt on: reminder toggle or time change, level, order or pool change, onboarding completion, app launch, foreground, app-side "Got it", and time-zone or significant time change.
  6. Rebuild replaces only requests with the `nichiji.reminder.` identifier prefix, so it never touches other pending notifications.

- **Scope boundary**:
  - In scope: `SystemReminderScheduler` scheduling and cancelling, taking `DailyKanjiService` and `DayProvider` at init (protocol unchanged). A pure `ReminderPlanBuilder`. A `ServiceContainer` rebuild entry that reloads preferences, applies `ReminderSettingsCoordinator`, and is called from the triggers above. Wiring `LevelChangeCoordinator`, onboarding completion, `handleTimeOrZoneChange`, launch and foreground, and app-side "Got it".
  - Out of scope: authorization (done in 9b), widget "Got it" and `WidgetCenter` reloads (Slice 11), notification actions, a foreground presentation delegate, and any change to the Phase 2 protocol.

- **Anticipated TODOs**:
  - `SystemReminderScheduler.rebuildSchedule` and `cancelAllReminders`: remove the Slice 10 TODOs.
  - `LevelChangeCoordinator.applyLevelChange`: the scheduler arrives through a new parameter, so the three callers (`LevelSettingsView`, `CustomKanjiPickerView`, `OnboardingFlow`) change. The widget half of its TODO stays for Slice 11.
  - `OnboardingFlow` completion TODO: rebuild the reminder window. Widget half stays.
  - `ServiceContainer.handleTimeOrZoneChange`: add the reminder rebuild. Widget half stays.
  - `NichijiApp` builds `SystemReminderScheduler` after `DefaultDailyKanjiService` and `SystemDayProvider`. `OnboardingCoordinator` still passes `NoopReminderScheduler`, which needs a look.
  - `ReminderSchedulerTests` TODOs become real tests. `TestReminderScheduler` keeps its count assertion.
  - Version: MINOR bump to v0.5.0 (new user-facing behavior). Branch: `feature/slice-10-reminder-scheduler`.

- **Planned tests**:
  - `ReminderPlanBuilder` (Swift Testing, no notification center): 7 plans from a fresh start. Time ahead plus `.assigned` gives kanji-led. Time ahead plus `.learned` skips today. Next fire tomorrow plus `.assigned` gives missed-day copy. Tomorrow plus `.learned` gives generic. Days 2 through 7 generic. Time exactly equal to now counts as passed. Month and year rollover. A different `Calendar` time zone shifts the fire dates.
  - `ReminderSettingsCoordinator` with `TestReminderScheduler`: off cancels, denied preserves and does not rebuild, undecided requests then rebuilds, authorized rebuilds.
  - Trigger wiring with `TestReminderScheduler`: level change and onboarding completion each call `rebuildSchedule` once.
  - Manual on a simulator: notifications actually land, the identifier prefix survives a rebuild, time-zone change reschedules, and denied shows the banner. This workspace is Linux, so nothing has been built or run.

- **Concerns raised**:
  - The window goes stale after 7 days without opening the app. Accepted, since the last requests are generic and still valid.
  - DESIGN.md's "kanji-led if learned" wording does not fit a next fire that is tomorrow. The rules above replace it, so DESIGN.md's reminder paragraph needs updating in this slice.
  - A kanji-led notification names today's kanji, which can be stale if the learner changes level after the rebuild. The level-change trigger covers that.

- **Status**: Approved by user.
