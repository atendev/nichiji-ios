# Changelog

All notable changes, ordered newest-first. Every commit gets a version bump.

---

## v0.0.6

- Close Phase 4 testing suite planning and specification tickets (007 and 008)
- Document Phase 4 verification architecture and test invariants in `docs/IMPLEMENTATION.md`
- Create test doubles (`TestDayProvider`, `TestKanjiContentStore`, `TestPronunciationService`, `TestReminderScheduler`) under `NichijiTests/TestDoubles/`
- Add Swift Testing test suite stubs under `NichijiTests/Suites/` and update `docs/IMPLOG.md`
- Advance Wayfinder map to Phase 5 Slice 1 (Design Tokens & Typography)

## v0.0.5

- Close Phase 3 planning and implementation tickets (005 and 006)
- Add design system tokens and reusable UI components under `Nichiji/DesignSystem/`
- Add view skeletons and navigation coordination under `Nichiji/Views/` for Onboarding, Today, Settings, and tab shell
- Add `NichijiWidget` target stub to `project.yml` and populate in-code TODO comments
- Initialize `docs/PROGRESS.md` with 11 vertical slices for Phase 5 implementation and advance Wayfinder map to Phase 4

## v0.0.4

- Close the Phase 2 service interfaces and reminder-widget contracts tickets
- Define Phase 2 service protocols, `DailyAssignmentSnapshot`, `NichijiError`, and `ServiceContainer` stubs under `Nichiji/Services/`
- Document Phase 2 interfaces in `docs/IMPLEMENTATION.md` and update `docs/DESIGN.md`, `CONTEXT.md`, and `docs/IMPLOG.md`

## v0.0.3

- Close the verified kanji and stroke dataset research ticket

## v0.0.2

- Define Phase 1 data models for bundled kanji content, AppStorage preferences, SwiftData learner records, and navigation/widget snapshots
- Record the missed-day rollover rule returning unlearned daily kanji to the study pool with the missed-day reminder copy
- Initialize the Wayfinder `.plan/` map and close Phase 0 and Phase 1 planning tickets

## v0.0.1

- Approve Phase 0 design in `docs/DESIGN.md`
- Add workflow documentation skeletons (`docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/PROGRESS.md`, `docs/IMPLOG.md`, `docs/CHANGELOG.md`, `CONTEXT.md`)
