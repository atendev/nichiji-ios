---
id: "024"
title: "Slice 9 Requirements Report: Onboarding Flow"
type: grilling
mode: HITL
status: closed
blocked_by: ["023"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 9 (Onboarding Flow, 7 screens) before creating the feature branch?

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/DESIGN.md`, `docs/ui-reference/design-notes.md`, `Nichiji/Views/Onboarding/`, `Nichiji/Views/RootView.swift`.

## Resolution

- **Slice name**: `slice-9-onboarding-flow`.

- **Success criteria**:
  1. `OnboardingCoordinator` runs the seven steps in order (Welcome, Daily kanji, Flashcards, Level, Reminder, Widget, Ready). The progress bar has six segments, excludes Welcome, and fills through the current step. Every step after Welcome has a 44 x 44 pt chevron back button, and Welcome is reachable by going back from Daily kanji. Step changes use a 0.35 s spring slide, or a 0.2 s crossfade under Reduce Motion. No custom edge-swipe back gesture.
  2. `WelcomeView` shows the `SealStamp` mark, 日字, "Nichiji", the tagline "One Kanji. One Day. Every Day.", a Get started button, and "No account needed. Nichiji does not collect any data." No new image asset.
  3. `DailyKanjiIntroView` shows the showcase kanji in a `KanjiCard` with the copy "Each day you get a new kanji to learn with readings and example words to help you learn."
  4. `FlashcardDemoView` uses a static sample (山) and writes nothing to `LearnerStore`. Tap flips the card in 3D. After a flip, a right swipe shows a matcha "Got it" badge and a left swipe shows a mustard "Forgot it" badge, the card tilts and flies off, then resets so the learner can try again. Two buttons ("Got it", "Forgot it") do the same thing for VoiceOver and Switch Control. Continue is always enabled. Under Reduce Motion the flip and fly-off become a 0.2 s crossfade.
  5. `LevelSelectView` shows the JLPT / Jōyō grade switch, selectable level rows (N5 to N1, or 1st to 6th grade and Secondary school) with kanji counts read from `KanjiContentStore`, and a note pointing to Settings for daily order. No Custom option and no order control. It opens on the learner's current system and level. Choosing a system selects its first level. Choosing a level writes `levelSystem`, `selectedJLPTLevel` or `selectedJoyoGrade`, and sets `isCustomPoolActive = false`.
  6. `ReminderSetupView` binds `reminderEnabled` (default on), `reminderHour` and `reminderMinute`, with the Slice 8 time controls (preset chips plus compact `DatePicker`). Continue calls `ReminderScheduler.requestAuthorization()` only when the toggle is on. A `.denied` status shows the inline "Notifications are off" row and never blocks Continue.
  7. `WidgetIntroView` shows a static mini widget graphic with a non-functional "Got it" preview, plus short steps for adding a widget. No account or sign-in language.
  8. `ReadyView` "Start learning" sets `hasCompletedOnboarding = true` and creates no assignment, because Today's lazy rollover already does that. `RootView` cross-fades from onboarding to the tab shell (plain swap under Reduce Motion).
  9. Replay (Settings "Replay introduction") keeps all progress, preferences and today's assignment. Finishing a replay with a changed level calls the shared level-change helper, which runs `LearnerStore.reassignToday(day:from:)` and leaves a `.learned` assignment intact.
  10. The step logic lives in an `@MainActor @Observable OnboardingFlow` model (step navigation, progress fill, level selection, completion). Views stay thin and read the model.
  11. Every control meets 44 x 44 pt tap targets, uses semantic Washi/Sumi tokens, supports Dynamic Type, has accessibility labels, and respects Reduce Motion.

- **Scope boundary**:
  - In scope: `OnboardingCoordinator`, the seven step views, `OnboardingFlow`, the shared level-change helper (extracted from the Slice 8 level screens, which then call it), the `RootView` completion transition, and onboarding strings.
  - Out of this slice: the concrete `UNUserNotificationCenter` scheduler (Slice 10, `NoopReminderScheduler` stays the live default), the `NichijiWidget` extension and `WidgetCenter` reloads (Slice 11), a Custom option or daily order control on the onboarding Level screen (ruled out in the design notes), and any Review, Dictionary or You screens.

- **Anticipated TODOs**:
  - `ReminderSetupView`: no system permission prompt appears until Slice 10 replaces `NoopReminderScheduler`. Mark the call site with a TODO.
  - `ReadyView` / `OnboardingFlow`: add a TODO to rebuild the reminder window and reload widget timelines on completion (Slices 10 and 11).
  - `WidgetIntroView`: the graphic is a mock. Add a TODO to match it to the real widget layout once Slice 11 lands.
  - Dependency flag: the shared level-change helper edits Slice 8 files (`LevelSettingsView`). The change is a refactor with no behavior change, and `SettingsPreferencesTests` must still pass.
  - Dependency flag: level counts come from the verified Slice 2 dataset. The sample counts in the design notes (80, 160, 200, 202, 193, 191, 1,110) are not used.
  - Remove the stale TODOs on `ReadyView` ("Initialize first day assignment"), `OnboardingCoordinator` ("back-swipe gestures") and the other Slice 9 TODOs as they land.
  - Document `OnboardingFlow` in `docs/IMPLEMENTATION.md`.

- **Planned tests**:
  - Add `NichijiTests/Suites/OnboardingFlowTests.swift` (Swift Testing, test doubles, fresh `UserDefaults` suite per test):
    1. `testStepOrderAndProgressFill` checks the seven-step order, that Welcome shows no progress, and that steps 1 to 6 fill 1 to 6 segments.
    2. `testBackFromDailyKanjiReachesWelcome` checks that back navigation walks the steps in reverse without skipping.
    3. `testLevelSystemSwitchSelectsFirstLevel` checks that switching to JLPT selects N5, switching to Jōyō selects 1st grade, and both clear `isCustomPoolActive`.
    4. `testLevelSelectionWritesPreferences` checks that choosing a level writes `levelSystem` and the matching level key.
    5. `testLevelCountsComeFromContentStore` checks that row counts match `TestKanjiContentStore` and are not hardcoded.
    6. `testReminderAuthorizationOnlyWhenEnabled` checks that `requestAuthorization()` runs only when the toggle is on, and that a `.denied` result still lets the flow advance.
    7. `testCompletionSetsFlagWithoutCreatingAssignment` checks that completion sets `hasCompletedOnboarding` and makes no `LearnerStore` write.
    8. `testReplayPreservesProgressAndReassignsOnLevelChange` checks that replay keeps `KanjiProgress`, reassigns an `.assigned` today when the level changed, and leaves a `.learned` today untouched.
  - Re-run `SettingsPreferencesTests` after the helper extraction.
  - Gesture and animation behavior (flip, fly-off, spring slide, cross-fade) are checked manually on a simulator, not unit tested.

- **Status**: Approved by user.
