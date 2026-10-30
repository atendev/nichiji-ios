---
id: "030"
title: "Implement Slice 11: WidgetKit Extension"
type: task
mode: AFK
status: open
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

<Filled in at close.>
