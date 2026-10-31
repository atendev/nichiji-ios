---
id: "038"
title: Load the generated dataset in the app and widget
type: task
mode: AFK
status: open
blocked_by: ["037"]
claimed: false
---

## Question

Do the app and widget read every kanji from the generated bundle, with the seven-entry seed kept only for tests?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Minor bump.

- `BundledKanjiContentStore` (`Nichiji/Services/KanjiContentStore.swift`) loads `kanji-index.json`, answers `entries(for:)` from the index instead of the preloaded seed, and decodes records on demand with caching.
- `strokePaths(for:)` reads `stroke-order/<hex>.svg` lazily in the app. The widget never loads SVGs.
- Move `SeedKanjiDataset` into `NichijiTests` (six test suites use it).
- Add the resources to both targets in `project.yml`; SVGs go to the app only.
- Apply the `KanjiEntry` schema changes from "Settle the bundled dataset scope and schema" across Today, Settings, onboarding level counts, the custom picker and the widgets.
- The Settings Sources screen is ticket "Build the Sources screen", not this one.
- A missing record or SVG surfaces as unavailable, never a silent substitute.

Also from [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md):

- Drop `strokePaths` and the `ExampleWord` `max*` fields from the models; there is no `legacyJLPTLevel`. "Build the dataset generator and pin its first output" already added `isJLPTLevelEstimated`, `KanjiIndexEntry.frequencyRank` and the `KanjiIndex` wrapper (`formatVersion` 1, `entries`), and left `strokePaths` decoding as optional so the bundle loads before this ticket removes it.
- Remove the hardcoded grade-count fallback in `LevelSettingsView.swift`; the bundle supplies counts.
- Show "N1 (est.)" for estimated levels in the Details row and subtitle, and add the Level-screen footer "JLPT levels are unofficial community lists", linking to Sources once that screen exists.
- An empty `exampleWords` array (11 kanji; the list is in the resolution of "Build the dataset generator and pin its first output") must render safely.
- `words.json` is app-only and loads lazily on first search; the widget never touches it.
- Delete the three verification and "from memory" caveats in `docs/ui-reference/design-notes.md`: line 62 (grade counts need verifying), line 70 (picker lists are samples, grade placement from memory) and line 126 (lists, grade placement, counts and example words from memory).

## Resolution

