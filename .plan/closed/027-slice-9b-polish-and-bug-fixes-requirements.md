---
id: "027"
title: "Slice 9b Requirements Report: Onboarding, Today and Settings Polish"
type: grilling
mode: HITL
status: closed
blocked_by: ["025"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for the post-Slice 9 polish and bug fixes before creating the feature branch?

## Notes

Skills: `apple`, `unslop`.
Version: PATCH bump to v0.4.1 (fixes and refinements, plus the permission-only half of the notification scheduler).
Branch: `feature/slice-9b-polish`.
Reference files: `Nichiji/Views/Onboarding/`, `Nichiji/Views/Today/TodayView.swift`, `Nichiji/Views/Settings/`, `Nichiji/Services/ServiceContainer.swift`, `Nichiji/NichijiApp.swift`.

## Resolution

- **Success criteria**:
  1. Step slides never overlap. Going forward, the old step leaves left and the new one enters from the right. Going back reverses both. Reduce Motion keeps a 0.2 s crossfade.
  2. The flashcard swaps faces at the edge-on point of the flip, so the front text turns away with the card and the back text turns in with it. No hard cut. The subtitle swap no longer shifts the card.
  3. Flashcard drag tilt is roughly halved and capped.
  4. The Reminder step shows the system notification prompt when it appears and status is not determined. A status button on the screen reads "Notifications on" or "Notifications off". Pressing it while not determined shows the prompt again. Pressing it while denied opens iOS notification settings, because iOS never shows the prompt twice.
  5. The Ready step shows the logo (seal and 日字), "You're all set", and the Start learning button. No other text.
  6. Opening and closing Control Center keeps Today's scroll position.
  7. Changing the appearance in Settings repaints the open Settings sheet at once.
  8. The Customize kanji grid uses one spacing value for rows and columns (12 pt), square cells, and a 30 pt kanji.

- **Causes found** (read from code, not yet reproduced on a device):
  1. `OnboardingStepHost` computes the removal transition from the current `direction`. SwiftUI keeps the removal transition the old view last rendered, so on a direction change the outgoing screen uses the previous direction. Matches both reported symptoms.
  2. Face swap is a time-delayed opacity (`linear(0.01).delay(0.2)`), not tied to the rotation angle.
  3. `rotationEffect(horizontalOffset / 20)` gives 5° at the swipe threshold and 30° during fly-off.
  4. `NoopReminderScheduler` is the only scheduler, so no system prompt can appear.
  5. Control Center sets `scenePhase` to `.inactive` then `.active`. `TodayView` reloads on `.active` and `loadToday` sets `isLoading`, which swaps the `ScrollView` for a spinner and drops the scroll position.
  6. `preferredColorScheme` is applied only at the app root, so the already presented sheet does not follow a live change.

- **Scope boundary**:
  - In scope: `OnboardingStepHost` paging, `FlashcardDemoView`, `ReminderSetupView`, `OnboardingFlow` (permission request moves from Continue to screen appear and the status button), `ReadyView`, a shared `OnboardingLogo` extracted from `WelcomeView`, `TodayView`, `SettingsSheet`, `CustomKanjiPickerView`, and a new `UNUserNotificationCenterReminderScheduler` with `authorizationStatus()` and `requestAuthorization()` only.
  - Also in scope after approval: the prompt fires when the reminder toggle is switched on while status is undecided.
  - Out of scope: scheduling and cancelling notifications, the rolling 7-day window, copy variants, and rebuild triggers. All stay in Slice 10 (ticket 026).

- **Anticipated TODOs**:
  - `UNUserNotificationCenterReminderScheduler.rebuildSchedule` and `cancelAllReminders` stay no-ops with Slice 10 TODOs.
  - Dependency flag: this overlaps the first piece of Slice 10. Slice 10's requirements should treat authorization as done.
  - Existing test `testReminderAuthorizationOnlyWhenEnabled` assumes the request happens on Continue. It changes to cover the on-appear request and the status button.
  - Neighbouring steps are built off-screen under the new paging. Hidden from VoiceOver and hit testing.

- **Planned tests**:
  - Update `OnboardingFlowTests`: request fires once on reminder appear when not determined, never when already decided, status button re-requests only when not determined, Continue never blocks.
  - Add a status mapping test for the new scheduler through a thin protocol seam, if one can be added without changing the live code path. Otherwise manual.
  - Animation, gesture, Control Center, theme repaint and grid spacing are checked manually on a simulator. This workspace is Linux, so nothing here has been built or run yet.

- **Status**: Approved by user.
