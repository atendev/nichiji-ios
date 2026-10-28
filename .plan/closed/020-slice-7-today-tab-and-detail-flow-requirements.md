---
id: "020"
title: "Slice 7 Requirements Report: Today Tab & Detail Flow"
type: grilling
mode: HITL
status: closed
blocked_by: ["019"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned
Tests for Slice 7 (Today Tab & Detail Flow) before creating the feature branch?

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/DESIGN.md`,
`Nichiji/Views/Today/`.

## Resolution

- **Slice name**: `slice-7-today-tab-and-detail-flow`.

- **Success criteria**:
  1. `NichijiApp` creates a shared App Group SwiftData `ModelContainer` and injects a production `ServiceContainer` into the SwiftUI environment so `TodayView` can reach the services. This work was deferred from Slices 3 and 4 and is now required to wire the Today tab.
  2. `TodayView` loads today's assignment through `DailyKanjiService.assignment(for:)` and resolves the matching `KanjiEntry` from the injected `KanjiContentStore`, using `@Query` for SwiftData learner state and the environment for services.
  3. The 260 pt hero shows the assigned kanji, a short primary meaning, and a speaker button that speaks a kana reading through `PronunciationService`. The hero remains readable across Dynamic Type sizes by capping the glyph at 260 pt for default sizes and falling back to `kanjiHeroCompact` when accessibility sizes exceed a measured breakpoint.
  4. The details card lists onyomi, kunyomi, radical, stroke count, JLPT level, and Joyo grade, with romaji sublabels shown only when `showsRomaji` is true.
  5. The example words card lists the bundled example words, showing word, kana, optional romaji, meaning, and a speaker button per word when a reading is available.
  6. The stroke order card renders a numbered two-column grid of SVG stroke paths loaded from `KanjiContentStore.strokePaths(for:)`. The "Practice this kanji" button stays visible but inactive because handwriting practice is out of scope.
  7. The "Got it" primary button calls `LearnerStore.markLearned(day:)`, advances `KanjiProgress` to `.learning`, and swaps the button for a learned seal.
  8. When the active pool is exhausted, `TodayView` shows `LevelCompleteView` with an "Open Settings" action.
  9. When the content store or learner store throws, the view shows a retry screen with a primary retry button that reruns the load path.
  10. The view refreshes when the app returns to the foreground. `ServiceContainer.handleTimeOrZoneChange(preferences:)` is wired to trigger only Today refresh in this slice; the full reminder and widget rebuild remain out of scope.
  11. All tappable controls are at least 44 × 44 pt, support Dynamic Type, and respect Reduce Motion. Speaker buttons, the settings header button, and example-word actions apply `.minTouchTarget()`. The hero glyph scales down or switches to the compact token at large accessibility sizes.

- **Scope boundary**:
  - In scope: binding `TodayView`, `KanjiHeroView`, `DetailsCardView`, `ExampleWordsCardView`, `StrokeOrderCardView`, and `LevelCompleteView` to real data and services; the app-level `ServiceContainer` and SwiftData `ModelContainer` setup that Slices 3 and 4 deferred; the learned, level-complete, and error states; hero audio; romaji gating; stroke path rendering; and the retry path.
  - Out of this slice: onboarding, the settings sheet UI, reminder scheduling, WidgetKit, handwriting practice, review mode, dictionary search, animations beyond the existing `PrimaryButton` press feedback, data import beyond the bundled seed set, and the full reminder/widget rebuild inside `handleTimeOrZoneChange`.

- **Anticipated TODOs**:
  - `StrokeOrderCardView`: render the numbered SVG grid and keep the practice button as a disabled placeholder.
  - `ExampleWordsCardView`: add a speaker action per word and disable it when no reading is available.
  - `TodayView`: leave a TODO for the post-onboarding first-launch handoff and for the WidgetKit "Got it" AppIntent integration.
  - `LevelCompleteView`: leave a TODO for dynamic level metrics and a direct level switch shortcut.
  - `ServiceContainer.handleTimeOrZoneChange`: update the existing TODO so it triggers Today refresh in this slice and leaves reminder/widget rebuild for Slice 10 and Slice 11.
  - `NichijiTests/TestDoubles/`: add a `TestLearnerStore` double or document the use of an in-memory `SwiftDataLearnerStore` for `TodayTabTests`.

- **Planned tests**:
  - Add `NichijiTests/Suites/TodayTabTests.swift` with Swift Testing and the existing test doubles, plus a new `TestLearnerStore` double if needed.
    1. `testInitialLoad` resolves a seed kanji through `DailyKanjiService` and verifies that the resolved `KanjiEntry` carries the expected ID, primary meaning, and readings.
    2. `testGotItMarksLearned` calls the learned action and checks that `LearnerStore` updates the assignment status to `.learned` and the kanji progress stage to `.learning`.
    3. `testLevelCompleteState` returns `nil` from `assignment(for:)` and verifies that `TodayView` exposes the level-complete state to the UI.
    4. `testErrorRetry` throws from `KanjiContentStore` and verifies that the error state is surfaced and that retry reruns the load path.
    5. `testRomajiToggle` hides romaji labels when `showsRomaji` is false and shows them when true.
    6. `testStrokePaths` verifies that `KanjiContentStore.strokePaths(for:)` returns one path per expected stroke and that `StrokeOrderCardView` builds the correct number of grid cells from that input.
    7. `testAccessibility` verifies that the hero, "Got it" button, and speaker buttons carry `accessibilityLabel` and `accessibilityHint` values and that status does not rely on color alone.

- **Implementation note**: `TodayView` reads learner state through `@Query` and receives services from the environment via the injected `ServiceContainer`. Async work is triggered from view lifecycle hooks and button actions. This keeps the architecture consistent with the existing TODO in `TodayView.swift` and avoids introducing a view-model layer that was not approved in earlier phases.

- **Status**: Requirements report revised and ready for user review before the implementation branch is created.
