---
id: "006"
title: Write Phase 3 file skeletons, in-code TODO map, and PROGRESS.md
type: task
mode: AFK
status: closed
blocked_by: ["005"]
claimed: false
---

## Question

Turn the decisions in the closed Phase 3 grilling ticket into the Phase 3 deliverables: create view and design-system file skeletons in `Nichiji/`, populate specific in-code TODO comments across views and service stubs, update `docs/PROGRESS.md` with the 11 vertical slices, and add the `NichijiWidget` target skeleton to `project.yml`.

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Source of truth: [Phase 3 in-code TODO map and PROGRESS.md slice breakdown](../closed/005-phase-3-todo-map-and-progress.md).
Follow `docs/workflow.md` Phase 3 rules:
- Annotate the actual codebase with specific TODO comments at every location required to build a concrete map of the work before any real code is written.
- Plain English, 1–2 sentences per comment, no doc citations.
- Update `docs/PROGRESS.md` with the rolled-up feature list.
- Stop at user approval before Phase 4.

## Resolution

- Created design system tokens and components under `Nichiji/DesignSystem/`:
  - `ColorTokens.swift`: semantic surfaces and inks adapting to Washi and Sumi themes, vermilion accent, matcha progress, mustard review states.
  - `TypographyTokens.swift`: Shippori Mincho for kanji display, Zen Kaku Gothic New for interface copy with system fallbacks.
  - `LayoutTokens.swift`: Apple HIG 44pt minimum touch target, 8pt spacing grid, continuous corner radii.
  - `HeaderBar.swift`: `漢字 | English` pattern with trailing action slot.
  - `PrimaryButton.swift`: vermilion action button with continuous rounding and accessible touch targets.
  - `KanjiCard.swift`: surface-raised card container with subtle hairline border.
  - `SealStamp.swift`: matcha "Got it" / learned status badge.
- Created view skeletons under `Nichiji/Views/`:
  - `RootView.swift`: coordinates between onboarding and main app shell based on completion preference.
  - `MainTabView.swift`: 4 bottom tabs (Today active; Dictionary, Review, and You quiet placeholders).
  - `Onboarding/`: `OnboardingCoordinator.swift` (7 steps + 6-segment progress bar) and step views `WelcomeView`, `DailyKanjiIntroView`, `FlashcardDemoView` (self-contained interactive demo), `LevelSelectView`, `ReminderSetupView`, `WidgetIntroView`, `ReadyView`.
  - `Today/`: `TodayView` (scrolling hero with peeking card), `KanjiHeroView` (260pt glyph, meaning, pronunciation trigger), `DetailsCardView` (readings, radical, strokes, level), `ExampleWordsCardView` (vocab rows with no trailing divider), `StrokeOrderCardView` (2-column stroke grid + practice button), `LevelCompleteView` (quiet empty state), and inline error/retry view.
  - `Settings/`: `SettingsSheet.swift`, `AppearancePickerView.swift` (mini phone preview selectors), `LevelSettingsView.swift` (JLPT/Joyo and order options), `ReminderSettingsView.swift` (notification toggle, time picker, denied permission warning).
- Added `NichijiWidget/NichijiWidgetBundle.swift` stub and updated `project.yml` with `NichijiWidget` app-extension target.
- Added specific, concise 1–2 sentence in-code TODO comments across all newly created skeleton files and app entry points.
- Populated `docs/PROGRESS.md` with 11 ordered vertical slices and updated `docs/IMPLOG.md`.
