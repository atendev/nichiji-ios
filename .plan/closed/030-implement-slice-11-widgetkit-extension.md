---
id: "030"
title: "Implement Slice 11: WidgetKit Extension"
type: task
mode: AFK
status: closed
blocked_by: ["029"]
claimed: false
---

## Question

Implement the WidgetKit extension and all host-app timeline reload triggers defined in the Slice 11 requirements report.

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, closed ticket `029-slice-11-widgetkit-requirements.md`, `NichijiWidget/`, `Nichiji/Services/DailyKanjiService.swift`, `NichijiTests/Suites/WidgetTimelineTests.swift`.

Implementation checklist derived from the requirements report:
- Register `systemSmall` and `systemMedium` widgets in `NichijiWidgetBundle.swift`.
- Implement the timeline provider using `DailyKanjiService.widgetSnapshot(for:)` with a midnight `reloadPolicy`.
- Implement entry views using existing design tokens and adapt to Light/Dark/Increase Contrast.
- Implement `MarkTodaysKanjiLearnedIntent` (or equivalent) that marks today's kanji learned, rebuilds reminders, and reloads timelines.
- Add widget timeline reloads after:
  - `LevelChangeCoordinator.refreshAssignmentAfterPreferenceChange`
  - `OnboardingFlow.complete`
  - `ServiceContainer.handleTimeOrZoneChange(preferences:)`
  - `TodayView.markLearned`
- Introduce a `WidgetRefresher` wrapper/protocol to make reloads testable and avoid duplicated `WidgetCenter` calls.
- Align onboarding and Settings "Add Widget" wording, and match the onboarding mini-widget preview to the real `systemSmall` layout.
- Resolve the TODOs in `NichijiWidgetBundle.swift`, `LevelChangeCoordinator.swift`, `OnboardingFlow.swift`, `ServiceContainer.swift`, `WidgetTimelineTests.swift`, and `WidgetIntroView.swift`.
- Add explicit post-MVP TODOs for lock-screen widgets, additional families/configuration intents, and widget deep-link to Today.
- Update `NichijiTests/Suites/WidgetTimelineTests.swift` with the planned tests.
- Update `docs/PROGRESS.md` and `docs/CHANGELOG.md`.

Risks to address:
- Lock-screen widget section in the Settings guide must become an explicit post-MVP placeholder.
- `project.yml` must give the widget target the same App Group entitlement and access to shared Nichiji types.
- The missing `Config/Nichiji.entitlements` file must be created or the reference removed.

## Resolution

Implemented the `NichijiWidget` extension on `feature/slice-11-implement-widgetkit-extension` (v0.6.0). `systemSmall` shows the kanji and meaning; `systemMedium` adds readings, one example word and an interactive Got it button. A single-entry timeline built by `DailyKanjiTimelineBuilder` reloads at the next local midnight, and shows a quiet placeholder when the level is complete, onboarding is unfinished or the store cannot be read.

`GotItAction` is the one Got it path for Today and the widget intent: it marks learned, rebuilds reminders and reloads timelines. `WidgetRefresher` is the only `WidgetCenter` caller and reloads after level changes, onboarding completion, time-zone changes and Today's Got it. Onboarding and Settings share `AddWidgetCopy.steps`, the onboarding preview renders the real small widget view, and the Settings lock-screen guide is now a post-MVP placeholder. `project.yml` embeds the widget with the App Group entitlement and shared sources, and `Config/*.entitlements` exist.

Audit and Deviation Report are in `docs/IMPLOG.md`. No Swift toolchain here, so nothing was built locally. CI passed (lint, tests, unsigned IPA) on the third run after two fixes; merged and tagged v0.6.0.
