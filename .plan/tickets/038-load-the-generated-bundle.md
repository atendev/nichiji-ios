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

## Resolution

