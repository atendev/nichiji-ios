# Map: Nichiji iOS

## Destination

Complete Phases 0 through 4 of the project workflow (`docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/PROGRESS.md`, and initial Swift type and interface outlines) so the vertical slices for Onboarding, Today, Settings, Reminders, and Widgets are ready for Phase 5 implementation.

## Notes

Domain: local-first iOS kanji learning app (Swift 6, SwiftUI, SwiftData, WidgetKit, iOS 27.0).
Skills to consult: `grilling`, `domain-modeling`, `apple`, `unslop`.
Follow `docs/workflow.md` and `AGENTS.md` at all times. Never proceed to the next workflow phase or commit without user confirmation.

## Decisions so far

- [Phase 0 initial scope and architecture boundaries](closed/000-phase-0-scope-and-boundaries.md): Target Onboarding plus Today first with bundled verified offline data, SwiftData plus AppStorage persistence, functional Washi/Sumi themes, local reminders, and initial WidgetKit support.
- [Phase 1 data model and persistence split](closed/001-phase-1-data-model-and-persistence.md): Decode `KanjiEntry` value types from the bundle keyed by character literal; store scalar preferences in App Group `UserDefaults` and `KanjiProgress`, `DailyAssignment`, `CustomKanjiSelection`, and `StudyLogEntry` in App Group SwiftData; return missed daily kanji to the `.new` unlearned pool with the `"You missed yesterday's kanji. That's okay, check it now."` reminder.

## Not yet specified

- Phase 3 in-code TODO map and `docs/PROGRESS.md` feature breakdown once Phase 1 data types and Phase 2 interfaces are approved.
- Phase 4 verification and testing suite definition in `docs/IMPLEMENTATION.md`.

## Out of scope

- Dictionary search, handwriting recognition, stroke-order checking, Review flashcard sessions, You analytics/history views, and iPhone Duo split-pane implementation (deferred past the initial Onboarding + Today implementation pass).

## Frontier

- [Verified kanji and stroke dataset sources](tickets/002-verified-kanji-dataset-sources.md) (research)
- [Phase 2 service interfaces and reminder-widget contracts](tickets/003-phase-2-service-interfaces.md) (grilling)
