---
id: "005"
title: Phase 3 in-code TODO map and PROGRESS.md slice breakdown
type: grilling
mode: HITL
status: closed
blocked_by: ["004"]
claimed: false
---

## Question

How should Nichiji structure its Phase 3 view/service file skeletons, in-code TODO map, and ordered vertical slices in `docs/PROGRESS.md`?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/PROGRESS.md`, `docs/ui-reference/design-notes.md`.

## Resolution

- **Codebase organization**:
  - `Nichiji/DesignSystem/`:
    - `Tokens/`: `ColorTokens.swift` (Washi/Sumi semantic colors), `TypographyTokens.swift` (Shippori Mincho, Zen Kaku Gothic New with system serif/sans fallbacks), `LayoutTokens.swift` (8pt grid, 44pt touch targets, continuous radii).
    - `Components/`: `HeaderBar.swift` (`漢字 | English` pattern), `PrimaryButton.swift` (single vermilion action), `KanjiCard.swift` (card container styling), `SealStamp.swift` (matcha "Got it" stamp).
  - `Nichiji/Views/`:
    - `RootView.swift`: switches between `OnboardingCoordinator` and `MainTabView` based on `hasCompletedOnboarding`.
    - `MainTabView.swift`: 4 tabs (**Today**, **Dictionary**, **Review**, **You**). Today is active; Dictionary, Review, and You are quiet placeholder screens to establish the full navigation skeleton from day one.
    - `Onboarding/`: `OnboardingCoordinator.swift` (7-step sequence + 6-segment progress bar) with step views under `Views/Onboarding/Steps/`. Screen 3 (Flashcard demo) is a self-contained interactive demo view decoupled from the deferred Review engine.
    - `Today/`: `TodayView.swift` (scrolling hero with peeking card), `KanjiHeroView.swift` (260pt character, meaning, readings), `DetailsCardView.swift`, `ExampleWordsCardView.swift`, `StrokeOrderCardView.swift`, `LevelCompleteView.swift`, and inline error/retry state.
    - `Settings/`: `SettingsSheet.swift` (reusable bottom sheet), `AppearancePickerView.swift` (mini phone previews for System/Light/Dark), `LevelSettingsView.swift` (JLPT/Joyo selector + order options), `ReminderSettingsView.swift` (notification toggle, time picker, denied permission warning).
  - `Nichiji/Services/`: concrete implementation file stubs matching Phase 2 protocols with targeted TODO comments.
- **XcodeGen spec**: Add `NichijiWidget` target skeleton to `project.yml` with the shared App Group (`group.com.aten.nichiji`) so multi-target setup is verified.
- **Vertical slice sequence for `docs/PROGRESS.md`**:
  1. Slice 1: Design Tokens & Typography
  2. Slice 2: Content Dataset & Bundled JSON Store
  3. Slice 3: SwiftData Learner Store
  4. Slice 4: DayProvider & Daily Kanji Rollover
  5. Slice 5: Japanese Pronunciation Audio
  6. Slice 6: Core Design System Components
  7. Slice 7: Today Tab & Detail Flow
  8. Slice 8: Settings Sheet & Preferences
  9. Slice 9: Onboarding Flow (7 Screens)
  10. Slice 10: Reminder Scheduler & Notifications
  11. Slice 11: WidgetKit Extension
- **Deliverable**: Ticket 006 task will create the skeleton files, add specific in-code TODO comments across views and services, update `docs/PROGRESS.md` with the 11 vertical slices, and update `project.yml`.
