---
id: "029"
title: "Slice 11 Requirements Report: WidgetKit Extension"
type: grilling
mode: HITL
status: closed
blocked_by: ["028"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 11 (WidgetKit Extension) before creating the feature branch?

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/DESIGN.md`, `NichijiWidget/`, `Nichiji/Services/DailyKanjiService.swift`, `NichijiTests/Suites/WidgetTimelineTests.swift`.
Pick up the Slice 11 TODOs left by earlier slices: widget timeline reloads after level changes, onboarding completion, time-zone changes and Got it (see the TODO comments in `LevelChangeCoordinator`, `OnboardingFlow` and `ServiceContainer`), the widget Got it intent (which should also rebuild the reminder window), and aligning the onboarding and Settings "Add Widget" wording.

## Resolution

The HITL grilling was delegated to an independent subagent (see delegated gate below). The resulting requirements are clear enough to move directly to an implementation ticket.

### Success Criteria

- The `NichijiWidget` target registers exactly two widget configurations:
  - `systemSmall`: today's kanji literal and primary meaning.
  - `systemMedium`: the kanji, primary meaning, onyomi/kunyomi readings, one featured example word, and an interactive "Got it" button while today's assignment is `.assigned`.
- Both layouts use existing design tokens (semantic colors, `.kanjiWidget` font, continuous corner radii, `minTouchTarget` where tappable) and adapt to Light/Dark/Increase Contrast.
- When the assignment is `.learned`, the "Got it" button flips to a learned state; when the level is complete, the widget shows a quiet placeholder.
- The timeline provider uses `DailyKanjiService.widgetSnapshot(for:)` and a single entry whose `reloadPolicy` is `.after(dayProvider.nextMidnight(after: now))`.
- A `MarkTodaysKanjiLearnedIntent` (or equivalent) resolves today, calls `LearnerStore.markLearned(day:)`, rebuilds reminders via `ReminderRefresher.refresh(preferences:scheduler:)`, and reloads all timelines.
- The following host-app paths reload widget timelines after their work succeeds:
  - `LevelChangeCoordinator.refreshAssignmentAfterPreferenceChange`
  - `OnboardingFlow.complete`
  - `ServiceContainer.handleTimeOrZoneChange(preferences:)`
  - `TodayView.markLearned`
- The onboarding widget intro and the Settings widget guide use identical "Add Widget" wording, and the onboarding mini-widget preview matches the real `systemSmall` layout.
- The widget extension links against shared Nichiji types and is configured with the same App Group (`group.com.aten.nichiji`).

### Scope Boundary

**In scope:** `NichijiWidget` extension target (`systemSmall` and `systemMedium`), timeline provider + entry views, interactive "Got it" AppIntent, host-app timeline reload triggers, Add Widget copy alignment, `WidgetTimelineTests` updates, and `docs/PROGRESS.md`/`docs/CHANGELOG.md` updates.

**Out of scope:** lock-screen widgets (post-MVP placeholder), additional widget families (`systemLarge`, `systemExtraLarge`, accessories), configurable/intent-based widget configuration beyond current preferences, deep-linking into Today, Live Activities, Siri suggestions, AppIntent donations, and new reminder scheduling logic (owned by Slice 10).

### Anticipated TODOs

These should remain in code as intentional post-MVP markers:
- Lock-screen widget family in the Settings widget guide.
- Additional widget families / configuration intents in the widget bundle.
- Widget deep-link to Today (`.widgetURL`/`Link`).

These earlier TODOs must be resolved in Slice 11:
- `NichijiWidgetBundle.swift`: implement `systemSmall`/`systemMedium` and the interactive Got it AppIntent.
- `LevelChangeCoordinator.swift`: reload WidgetKit timelines after level/order changes.
- `OnboardingFlow.swift`: reload widget timelines on onboarding completion.
- `ServiceContainer.swift`: reload WidgetKit timelines in `handleTimeOrZoneChange`.
- `WidgetTimelineTests.swift`: verify timeline provider and interactive Got it AppIntent.
- `WidgetIntroView.swift`: match the mock to the real small widget layout.

A new trigger to add:
- `TodayView.markLearned()`: add an explicit widget-timeline reload after the reminder rebuild.

### Planned Tests

Extend `WidgetTimelineTests.swift` using Phase 4 doubles:
- `systemSmall` and `systemMedium` timeline entries with correct snapshot fields and `reloadPolicy`.
- Level-complete placeholder with no crash and no intent target.
- Interactive "Got it" AppIntent marks learned, rebuilds reminders, and triggers a timeline reload.
- Host-app triggers: level change, onboarding completion, time-zone/zone change, and Today "Got it" each record a widget timeline reload.
- Copy alignment: onboarding and Settings "Add Widget" wording match.

### Delegated gate

- **Grilling audit / Requirements Report** — produced by subagent `aec267a9a06af69b6` acting as the HITL stand-in. Verdict: move directly to `Implement Slice 11: WidgetKit Extension`.

### Risks surfaced

1. Lock-screen scope mismatch: the Settings widget guide advertises a lock-screen widget, but the first pass only approved `systemSmall`/`systemMedium`. Must be an explicit post-MVP placeholder.
2. Missing widget target entitlements and target dependency in `project.yml`; the widget needs the same App Group and access to shared types.
3. Missing `Config/Nichiji.entitlements` file referenced by `project.yml`.
4. Need a `WidgetRefresher` wrapper/protocol to make reloads testable and avoid duplicated `WidgetCenter` calls.
5. `TodayView.markLearned()` currently does not mention widgets; the implementation ticket must add the reload there.
