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
- [Verified kanji and stroke dataset sources](closed/002-verified-kanji-dataset-sources.md): Generate a version-pinned bundle from KANJIDIC2, JMdict, and KanjiVG, preserving source caveats, checksums, attribution, and lazy stroke SVG loading.
- [Phase 2 service interfaces and reminder-widget contracts](closed/003-phase-2-service-interfaces.md): Five protocol services in a `ServiceContainer`, writes through a `@ModelActor LearnerStore`, lazy idempotent daily rollover with an injected `DayProvider`, a rolling 7-day notification window, small and medium interactive widgets refreshed at midnight, and typed `NichijiError`.
- [Write Phase 2 interfaces and stubs](closed/004-write-phase-2-interfaces.md): Added Phase 2 protocol stubs and `DailyAssignmentSnapshot` under `Nichiji/Services/`, documented signatures in `docs/IMPLEMENTATION.md`, and updated `docs/DESIGN.md` and `CONTEXT.md`.
- [Phase 3 in-code TODO map and PROGRESS.md slice breakdown](closed/005-phase-3-todo-map-and-progress.md): Established view skeletons, 4-tab structure with quiet placeholders, 11 vertical slices for PROGRESS.md, and `NichijiWidget` target stub in `project.yml`.
- [Write Phase 3 file skeletons, in-code TODO map, and PROGRESS.md](closed/006-write-phase-3-skeletons-and-todos.md): Added design system tokens and components, view skeletons for Onboarding, Today, Settings, and tab shell, populated specific in-code TODO comments across views and widgets, and initialized `docs/PROGRESS.md` with 11 vertical slices.
- [Phase 4 verification and testing suite definition](closed/007-phase-4-verification-and-testing-suite.md): Standardized on Swift Testing (`import Testing`) with in-memory SwiftData containers, four test doubles, and six feature test suites.
- [Write Phase 4 testing suite specification and test doubles](closed/008-write-phase-4-testing-suite.md): Documented Phase 4 verification architecture and invariants in `docs/IMPLEMENTATION.md` and created test doubles and test suite stubs under `NichijiTests/`.
- [Slice 1 Requirements Report: Design Tokens & Typography](closed/009-slice-1-design-tokens-and-typography-requirements.md): Defined success criteria, scope boundary, and test plan for semantic color, typography with fallback, and layout tokens.
- [Implement Slice 1: Design Tokens & Typography](closed/010-slice-1-implement-design-tokens-and-typography.md): Implemented dynamic Washi/Sumi palette, font styling with system fallback, Apple HIG layout modifiers, and `DesignTokensTests`.
- [Slice 2 Requirements Report: Content Dataset & Bundled JSON Store](closed/011-slice-2-content-dataset-and-bundled-json-store-requirements.md): Defined success criteria, scope boundary, and test plan for bundled JSON dataset loading and filtering.
- [Implement Slice 2: Content Dataset & Bundled JSON Store](closed/012-slice-2-implement-content-dataset-and-bundled-json-store.md): Implemented `BundledKanjiContentStore` with caching and offline `SeedKanjiDataset`, updated `TestKanjiContentStore`, and added `KanjiContentStoreTests`.
- [Slice 3 Requirements Report: SwiftData Learner Store](closed/013-slice-3-swiftdata-learner-store-requirements.md): Defined success criteria, scope boundary, and test plan for `@ModelActor` learner store and mutations.
- [Implement Slice 3: SwiftData Learner Store](closed/014-slice-3-implement-swiftdata-learner-store.md): Implemented `SwiftDataLearnerStore` with `@ModelActor`, public `LearnerModels`, and `LearnerStoreTests`.
- [Slice 4 Requirements Report: DayProvider & Daily Kanji Rollover](closed/015-slice-4-dayprovider-and-daily-kanji-rollover-requirements.md): Defined success criteria, scope boundary, and test plan for clock boundary, rollover invariants, deterministic ordering, and widget snapshots.
- [Implement Slice 4: DayProvider & Daily Kanji Rollover](closed/016-slice-4-implement-dayprovider-and-daily-kanji-rollover.md): Implemented `SystemDayProvider`, `DefaultDailyKanjiService`, public snapshots, and `DailyKanjiServiceTests`.

## Not yet specified

_None. Phase 5 vertical slice loop is in progress._

## Out of scope

- Dictionary search, handwriting recognition, stroke-order checking, Review flashcard sessions, You analytics/history views, and iPhone Duo split-pane implementation (deferred past the initial Onboarding + Today implementation pass).

## Frontier

- [Slice 5 Requirements Report: Japanese Pronunciation Audio](tickets/017-slice-5-japanese-pronunciation-audio-requirements.md) (grilling)
