---
id: "022"
title: "Slice 8 Requirements Report: Settings Sheet & Preferences"
type: grilling
mode: HITL
status: closed
blocked_by: ["021"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 8 (Settings Sheet & Preferences) before creating the feature branch?

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/DESIGN.md`, `docs/ui-reference/design-notes.md`, `Nichiji/Views/Settings/`.

## Resolution

- **Slice name**: `slice-8-settings-sheet-and-preferences`.

- **Success criteria**:
  1. `SettingsSheet` displays the Appearance picker at the top, followed by the **Learning** group (`Level & Order` with active level/custom summary, `Daily Reminder` with `On · <time>` / `Off` summary, `Show romaji` toggle, and `Streak freeze` toggle), the **Help** group (`Add a widget` guide and `Replay introduction` action setting `hasCompletedOnboarding = false` and dismissing the sheet), and the **About** group (`Privacy` push screen showing "Data not collected" and `Version` row).
  2. `AppearancePickerView` renders three mini phone preview cards (`System` with diagonal light/dark split, `Light` in Washi palette, `Dark` in Sumi palette), selected state border/checkmark badge, and a caption describing the active mode (`"Matches your phone. Light by day, dark at night."`, `"Always light, like washi paper."`, `"Always dark, like sumi ink at night."`), persisted via `LearnerPreferenceKey.appearanceMode`.
  3. `LevelSettingsView` provides:
     - The `JLPT` / `Jōyō grade` level system switch (`LearnerPreferenceKey.levelSystem`). Switching systems selects the default first level of that system (`N5` or `1st grade`), disables custom mode (`isCustomPoolActive = false`), and triggers pool re-evaluation.
     - Selectable level rows (`N5`–`N1` for JLPT; `1st grade`–`6th grade` and `Secondary school` for Jōyō) with entry counts from `KanjiContentStore` and selected state when `isCustomPoolActive` is false.
     - Selectable `DailyOrder` rows (`Most common`, `List order`, `Random`) with subtitle notes.
     - A `Customize your kanji` navigation link (`CustomKanjiPickerView`) showing the active custom count and selected indicator when `isCustomPoolActive` is true.
     - Changing the level system, selected level, daily order, or custom kanji selection resolves the updated candidate pool via `DailyKanjiService.activePool(preferences:)`, orders it according to `DailyOrder`, and calls `LearnerStore.reassignToday(day:from:)` so an unlearned today assignment updates immediately while a `.learned` assignment stays intact.
  4. `CustomKanjiPickerView` groups bundled kanji from `KanjiContentStore` by the active `LevelSystem` (JLPT levels or Jōyō grades), showing per-group counts (`"<N> kanji · <M> on"`), a `Select all` / `Clear all` toggle per section, a 5-column kanji toggle grid, and a bottom bar with total selected count and `Done` action that persists `LearnerStore.setCustomSelection(_:levelSystem:)`, sets `isCustomPoolActive = !selected.isEmpty`, and triggers `reassignToday`.
  5. `ReminderSettingsView` binds `reminderEnabled`, `reminderHour`, and `reminderMinute` in App Group `UserDefaults`, queries `ReminderScheduler.authorizationStatus()` on load, displays the inline `"Notifications are off"` warning row with a link to system Settings when `.denied` (while preserving the learner's toggle state), provides reminder time selection (preset chips `8:00 AM`, `12:00 PM`, `8:00 PM` plus a compact `DatePicker` for custom times) and a notification preview card when enabled, and calls `ReminderScheduler.requestAuthorization()` / `rebuildSchedule(preferences:)` or `cancelAllReminders()` when changed.
  6. `TodayView` observes changes to level, order, and custom pool preferences so dismissing or changing settings refreshes Today's displayed kanji immediately when reassigned.
  7. Every interactive control meets Apple HIG 44 × 44 pt minimum tap targets, uses semantic Washi/Sumi color and typography tokens (weight <= 500), supports Dynamic Type, and respects Reduce Motion.

- **Scope boundary**:
  - In scope: `SettingsSheet`, `AppearancePickerView`, `LevelSettingsView`, `CustomKanjiPickerView`, `ReminderSettingsView`, `WidgetGuideSettingsView` / `PrivacySettingsView` sub-screens, preference persistence in App Group `UserDefaults`, custom selection persistence and `reassignToday` wiring through `LearnerStore` and `DailyKanjiService`, `ReminderScheduler` hook calls from `ReminderSettingsView`, and `TodayView` reactivity to preference changes.
  - Out of this slice: Review settings sub-screen (deferred with Review mode), the 7-screen `OnboardingCoordinator` implementation (Slice 9), the concrete `UNUserNotificationCenter` implementation of `ReminderScheduler` (Slice 10; `NoopReminderScheduler` remains the live container default until Slice 10), and the `NichijiWidget` extension implementation and `WidgetCenter.shared.reloadAllTimelines()` calls (Slice 11).

- **Anticipated TODOs**:
  - `SettingsSheet`: leave Review settings row out or marked with a TODO until the post-MVP Review slice lands.
  - `LevelSettingsView` / `CustomKanjiPickerView`: leave a TODO for `ReminderScheduler.rebuildSchedule` and `WidgetCenter` timeline reload after pool changes (Slices 10 and 11).
  - `ReminderSettingsView`: calls `ReminderScheduler` protocol methods now; live `UNUserNotificationCenter` scheduling lands in Slice 10.

- **Planned tests**:
  - Add `NichijiTests/Suites/SettingsPreferencesTests.swift` using Swift Testing and test doubles (`TestKanjiContentStore`, `TestLearnerStore`, `TestDayProvider`, `TestReminderScheduler`):
    1. `testPreferencesSnapshotRoundTrip` verifies reading and writing `AppearanceMode`, `LevelSystem`, `JLPTLevel`, `JoyoGrade`, `DailyOrder`, `showsRomaji`, `streakFreezeEnabled`, `reminderEnabled`, `reminderHour`, `reminderMinute`, and `isCustomPoolActive` in `UserDefaults`.
    2. `testLevelSwitchReassignsUnlearnedToday` verifies that switching level or order re-evaluates `DailyKanjiService.activePool` and swaps an `.assigned` today kanji via `LearnerStore.reassignToday(day:from:)`.
    3. `testLevelSwitchPreservesLearnedToday` verifies that changing level or custom pool when today's assignment is `.learned` leaves today's assignment untouched.
    4. `testCustomKanjiSelectionPersistenceAndPool` verifies `setCustomSelection(_:levelSystem:)` updates `customSelectionIDs(for:)` and that `DailyKanjiService.activePool` filters to the custom selection when `isCustomPoolActive` is true.
    5. `testReminderSettingsAuthorizationAndRebuild` verifies that enabling reminders or changing reminder time invokes `ReminderScheduler.rebuildSchedule(preferences:)`, disabling invokes `cancelAllReminders()`, and `.denied` status surfaces the denied state without resetting `reminderEnabled`.

- **Status**: Approved by user.
